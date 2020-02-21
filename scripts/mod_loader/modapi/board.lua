local DequeList = require("scripts/mod_loader/deque_list")

-- TODO: test and find out what is saved in savegame, and what is not.

TERRAIN_ICE_CRACKED = -1
TERRAIN_MOUNTAIN_CRACKED = -2
TERRAIN_FOREST_FIRE = -3

RUBBLE_BUILDING = 0
RUBBLE_MOUNTAIN = 1

local BoardClass = {}

BoardClass.SetFire = function(self, loc, fire)
	Tests.AssertSignature{
		ret = "void",
		func = "SetFire",
		params = { self, loc, fire },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	if fire == nil then
		fire = true
	end
	
	CUtils.SetTileFire(self, loc, fire)
end

-- returns true if tile is a forest, even if it is on fire.
BoardClass.IsForest = function(self, loc)
	Tests.AssertSignature{
		ret = "bool",
		func = "IsForest",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.IsTileForest(self, loc)
end

BoardClass.IsForestFire = function(self, loc)
	Tests.AssertSignature{
		ret = "bool",
		func = "IsForestFire",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.IsForestFire(self, loc)
end

BoardClass.IsShield = function(self, loc)
	Tests.AssertSignature{
		ret = "bool",
		func = "IsShield",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.IsTileShield(self, loc)
end

BoardClass.SetShield = function(self, loc, shield, no_animation)
	Tests.AssertSignature{
		ret = "void",
		func = "SetShield",
		params = { self, loc, shield, no_animation },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool", "boolean|bool" },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	-- Shielding empty tiles is possible, but they are not stored in the savegame,
	-- so that shouldn't be part of the mod loader.
	local iTerrain = self:GetTerrain(loc)
	local isShieldableTerrain = iTerrain == TERRAIN_BUILDING or iTerrain == TERRAIN_MOUNTAIN
	
	if shield == nil then
		shield = true
	end
	
	if no_animation == nil then
		no_animation = false
	end
	
	if isShieldableTerrain then
		if no_animation then
			CUtils.SetTileShield(self, loc, shield)
		else
			local d = SpaceDamage(loc)
			d.iShield = shield and 1 or -1
			self:DamageSpace(d)
		end
	elseif self:IsPawnSpace(loc) then
		self:GetPawn(loc):SetShield(shield, no_animation)
	end
end

BoardClass.SetWater = function(self, loc, water, sink)
	Tests.AssertSignature{
		ret = "void",
		func = "SetWater",
		params = { self, loc, water, sink },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool", "boolean|bool" },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" }
	}
	
	if water then
		if sink then
			local d = SpaceDamage(loc)
			d.iTerrain = TERRAIN_LAVA
			self:DamageSpace(d)
		else
			self:SetTerrain(loc, TERRAIN_WATER)
		end
		
		self:SetLava(loc, false)
		self:SetAcid(loc, false)
	elseif self:GetTerrain(loc) == TERRAIN_WATER then
		self:SetTerrain(loc, TERRAIN_ROAD)
	end
end

BoardClass.SetAcidWater = function(self, loc, acid, sink)
	Tests.AssertSignature{
		ret = "void",
		func = "SetAcidWater",
		params = { self, loc, acid, sink },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool", "boolean|bool" },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" }
	}
	
	if acid then
		if sink then
			local d = SpaceDamage(loc)
			d.iTerrain = TERRAIN_LAVA
			self:DamageSpace(d)
		else
			self:SetTerrain(loc, TERRAIN_WATER)
		end
		
		self:SetLava(loc, false)
		self:SetAcid(loc, true)
	elseif self:GetTerrain(loc) == TERRAIN_WATER and self:IsAcid(loc) then
		self:SetAcid(loc, false)
		self:SetTerrain(loc, TERRAIN_ROAD)
	end
end

BoardClass.GetHealth = function(self, loc)
	Tests.AssertSignature{
		ret = "int",
		func = "GetHealth",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.GetTileHealth(self, loc)
end

BoardClass.GetMaxHealth = function(self, loc)
	Tests.AssertSignature{
		ret = "int",
		func = "GetMaxHealth",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.GetTileMaxHealth(self, loc)
end

BoardClass.GetLostHealth = function(self, loc)
	Tests.AssertSignature{
		ret = "int",
		func = "GetLostHealth",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.GetTileLostHealth(self, loc)
end

BoardClass.SetHealth = function(self, loc, hp)
	Tests.AssertSignature{
		ret = "void",
		func = "SetHealth",
		params = { self, loc, hp },
		{ "userdata|GameBoard&", "userdata|Point", "number|int" }
	}
	
	local hp_max = CUtils.GetTileMaxHealth(self, loc)
	local iTerrain = self:GetTerrain(loc)
	hp = math.max(0, math.min(hp, hp_max))
	
	local rubbleState = CUtils.GetTileRubbleState(self, loc)
	local isRubble = iTerrain == TERRAIN_RUBBLE
	local isBuilding = iTerrain == TERRAIN_BUILDING
	local isMountain = iTerrain == TERRAIN_MOUNTAIN
	local isRuins = isRubble and rubbleState == RUBBLE_BUILDING
	local isDestroyedMountain = isRubble and rubbleState == RUBBLE_MOUNTAIN
	
	if isBuilding or isRuins then
		self:SetBuilding(loc, hp, hp_max)
		
	elseif isMountain or isDestroyedMountain then
		self:SetMountain(loc, hp, hp_max)
		
	elseif iTerrain == TERRAIN_ICE then
		self:SetIce(loc, hp, hp_max)
	end
end

BoardClass.SetMaxHealth = function(self, loc, hp_max)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMaxHealth",
		params = { self, loc, hp_max },
		{ "userdata|GameBoard&", "userdata|Point", "number|int" }
	}
	
	local rubbleState = CUtils.GetTileRubbleState(self, loc)
	local iTerrain = self:GetTerrain(loc)
	
	local isBuilding = iTerrain == TERRAIN_BUILDING
	local isRuins = iTerrain == TERRAIN_RUBBLE and rubbleState == RUBBLE_BUILDING
	
	if isBuilding or isRuins then
		
		if self:IsUniqueBuilding(loc) then
			hp_max = 1
		else
			hp_max = math.max(1, math.min(4, hp_max))
		end
		
		local hp = CUtils.GetTileHealth(self, loc.x, loc.y)
		
		self:SetBuilding(loc, hp, hp_max)
	end
end

BoardClass.SetBuilding = function(self, loc, hp, hp_max)
	Tests.AssertSignature{
		ret = "void",
		func = "SetBuilding",
		params = { self, loc, hp, hp_max },
		{ "userdata|GameBoard&", "userdata|Point", "number|int", "number|int" },
		{ "userdata|GameBoard&", "userdata|Point", "number|int" },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	hp_max = hp_max or CUtils.GetTileMaxHealth(self, loc)
	hp = hp or CUtils.GetTileHealth(self, loc)
	
	CUtils.SetTileMaxHealth(self, loc, hp_max)
	CUtils.SetTileHealth(self, loc, hp)
	
	self:SetTerrain(loc, TERRAIN_BUILDING)
	
	if hp > 0 then
		self:SetPopulated(true, loc)
	end
end

BoardClass.SetMountain = function(self, loc, hp)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMountain",
		params = { self, loc, hp },
		{ "userdata|GameBoard&", "userdata|Point", "number|int" }
	}
	
	self:SetTerrain(loc, TERRAIN_MOUNTAIN)
	
	if hp > 0 then
		CUtils.SetTileMaxHealth(self, loc, 2)
		CUtils.SetTileHealth(self, loc, hp)
	else
		self:SetRubble(loc)
	end
end

BoardClass.SetIce = function(self, loc, hp)
	Tests.AssertSignature{
		ret = "void",
		func = "SetIce",
		params = { self, loc, hp },
		{ "userdata|GameBoard&", "userdata|Point", "number|int" }
	}
	
	self:SetTerrain(loc, TERRAIN_ICE)
	
	if hp > 0 then
		CUtils.SetTileMaxHealth(self, loc, 2)
		CUtils.SetTileHealth(self, loc, hp)
	else
		self:SetTerrain(loc, TERRAIN_ROAD)
		self:SetTerrain(loc, TERRAIN_WATER)
	end
end

BoardClass.SetRubble = function(self, loc, flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetRubble",
		params = { self, loc, flag },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	if flag == nil then
		flag = true
	end
	
	local iTerrain = self:GetTerrain(loc)
	
	if flag then
		if iTerrain == TERRAIN_BUILDING then
			local hp_max = self:GetMaxHealth(loc)
			self:SetBuilding(loc, 0, hp_max)
			
		elseif iTerrain == TERRAIN_MOUNTAIN then
			self:SetTerrain(loc, TERRAIN_ROAD)
			CUtils.SetTileRubbleState(self, loc, RUBBLE_MOUNTAIN)
			self:SetTerrain(loc, TERRAIN_RUBBLE)
		end
		
	elseif iTerrain == TERRAIN_RUBBLE then
		
		local rubbleState = CUtils.GetTileRubbleState(self, loc)
		
		if rubbleState == RUBBLE_BUILDING then
			local hp_max = self:GetMaxHealth(loc)
			self:SetBuilding(loc, hp_max, hp_max)
			
		else
			self:SetTerrain(loc, TERRAIN_MOUNTAIN)
		end
	end
end

BoardClass.SetSnow = function(self, loc, snow)
	Tests.AssertSignature{
		ret = "void",
		func = "SetSnow",
		params = { self, loc, snow },
		{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" }
	}
	
	if snow == nil then
		snow = true
	end
	
	local custom_tile = self:GetCustomTile(loc)
	
	if snow then
		if custom_tile == "" then
			self:SetCustomTile(loc, "snow.png")
		end
	else
		if custom_tile == "snow.png" then
			self:SetCustomTile(loc, "")
		end
	end
end

BoardClass.SetUniqueBuilding = function(self, loc, buildingId)
	Tests.AssertSignature{
		ret = "void",
		func = "SetUniqueBuilding",
		params = { self, loc, buildingId },
		{ "userdata|GameBoard&", "userdata|Point", "string|string" }
	}
	
	CUtils.TileSetUniqueBuilding(self, loc, buildingId)
end

BoardClass.GetUniqueBuilding = function(self, loc)
	Tests.AssertSignature{
		ret = "string",
		func = "GetUniqueBuilding",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.TileGetUniqueBuilding(self, loc)
end

BoardClass.RemoveUniqueBuilding = function(self, loc)
	Tests.AssertSignature{
		ret = "void",
		func = "RemoveUniqueBuilding",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	CUtils.TileRemoveUniqueBuilding(self, loc)
	self:SetBuilding(loc)
end

BoardClass.RemoveItem = function(self, loc)
	Tests.AssertSignature{
		ret = "void",
		func = "RemoveItem",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	if not self:IsItem(loc) then
		return
	end
	
	CUtils.TileRemoveItem(self, loc)
end

BoardClass.GetItemName = function(self, loc)
	Tests.AssertSignature{
		ret = "string",
		func = "GetItem",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	if not self:IsItem(loc) then
		return
	end
	
	return CUtils.TileGetItemName(self, loc)
end

BoardClass.GetHighlighted = function(self)
	Tests.AssertSignature{
		ret = "void",
		func = "GetHighlighted",
		params = { self },
		{ "userdata|GameBoard&" }
	}
	
	return CUtils.BoardGetHighlighted(self)
end

BoardClass.IsHighlighted = function(self, loc)
	Tests.AssertSignature{
		ret = "bool",
		func = "IsHighlighted",
		params = { self, loc },
		{ "userdata|GameBoard&", "userdata|Point" }
	}
	
	return CUtils.IsTileHighlighted(self, loc)
end

BoardClass.MarkGridLoss = function(self, loc, grid_loss)
	Tests.AssertSignature{
		ret = "void",
		func = "MarkGridLoss",
		params = { self, loc, grid_loss },
		{ "userdata|GameBoard&", "userdata|Point", "number|int" }
	}
	
	CUtils.TileMarkGridLoss(self, loc, grid_loss)
end

BoardClass.GetLuaString = function(self)
	Tests.AssertSignature{
		ret = "string",
		func = "GetLuaString",
		params = { self },
		{ "userdata|GameBoard&" }
	}
	
	local size = self:GetSize()
	return string.format("Board [width = %s, height = %s]", size.x, size.y)
end
BoardClass.GetString = BoardClass.GetLuaString

local function isTipImage(board)
	return CUtils.IsGameboard(board)
end

BoardClass.IsGameBoard = function(self)
	Tests.AssertSignature{
		ret = "boolean",
		func = "IsGameBoard",
		params = { self },
		{ "userdata|GameBoard&" }
	}
	
	return not self:IsTipImage()
end

BoardClass.IsTipImage = function(self)
	Tests.AssertSignature{
		ret = "boolean",
		func = "IsTipImage",
		params = { self },
		{ "userdata|GameBoard&" }
	}
	
	return isTipImage(self)
end

-- GetCurrentMission is not accurate enough.
--[[BoardClass.GetMission = function(self)
	Tests.AssertSignature{
		ret = "table",
		func = "GetMission",
		params = { self },
		{ "userdata|GameBoard&" }
	}
	
	if self:IsTipImage() then
		return nil
	end
	
	return GetCurrentMission()
end]]



function InitializeBoardClass(board)
	-- modify existing board functions here
	
	local oldSetLava = board.SetLava
	BoardClass.SetLava = function(self, loc, lava, sink)
		Tests.AssertSignature{
			ret = "void",
			func = "SetLava",
			params = { self, loc, lava, sink },
			{ "userdata|GameBoard&", "userdata|Point", "boolean|bool", "boolean|bool" },
			{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" }
		}
		
		if lava and sink then
			local d = SpaceDamage(loc)
			d.iTerrain = TERRAIN_LAVA
			self:DamageSpace(d)
		else
			oldSetLava(self, loc, lava)
		end
	end
	
	-- Note for future digging:
	-- (glitchy vanilla behavior) setting building on water messes up the tile somehow,
	-- making the water stick around even when attempting to change the terrain later.
	local oldSetTerrain = board.SetTerrain
	BoardClass.SetTerrain = function(self, loc, iTerrain)
		Tests.AssertSignature{
			ret = "void",
			func = "SetTerrain",
			params = { self, loc, iTerrain },
			{ "userdata|GameBoard&", "userdata|Point", "number|int" }
		}
		
		if iTerrain == TERRAIN_MOUNTAIN_CRACKED then
			self:SetMountain(loc, 1)
			
		elseif iTerrain == TERRAIN_ICE_CRACKED then
			self:SetIce(loc, 1)
			
		else
			oldSetTerrain(self, loc, iTerrain)
			
			if iTerrain == TERRAIN_FOREST and board:IsFire(loc) then
				-- update tile after placing forest on fire, to avoid graphical glitch.
				board:SetFire(loc)
			end
			
			if iTerrain == TERRAIN_BUILDING and self:GetHealth(loc) == 0 then
				-- update tile after placing building on rubble,
				-- so visual and functional rubble always returns TERRAIN_RUBBLE
				CUtils.SetTileTerrain(self, loc, TERRAIN_RUBBLE)
			end
		end
	end
	
	local oldIsTerrain = board.IsTerrain
	BoardClass.IsTerrain = function(self, loc, iTerrain)
		Tests.AssertSignature{
			ret = "bool",
			func = "IsTerrain",
			params = { self, loc, iTerrain },
			{ "userdata|GameBoard&", "userdata|Point", "number|int" }
		}
		
		if iTerrain == TERRAIN_ICE_CRACKED then
			local iTerrain = self:GetTerrain(loc)
			local hp = self:GetHealth(loc)
			
			return iTerrain == TERRAIN_ICE and hp == 1
			
		elseif iTerrain == TERRAIN_MOUNTAIN_CRACKED then
			local iTerrain = self:GetTerrain(loc)
			local hp = self:GetHealth(loc)
			
			return iTerrain == TERRAIN_MOUNTAIN and hp == 1
			
		elseif iTerrain == TERRAIN_FOREST_FIRE then
			return self:IsForestFire(loc)
		end
		
		return oldIsTerrain(self, loc, iTerrain)
	end
	
	-- added no_animation parameter similar to what vanilla function SetSmoke has.
	local oldSetFrozen = board.SetFrozen
	BoardClass.SetFrozen = function(self, loc, frozen, no_animation)
		Tests.AssertSignature{
			ret = "void",
			func = "SetFrozen",
			params = { self, loc, frozen, no_animation },
			{ "userdata|GameBoard&", "userdata|Point", "boolean|bool", "boolean|bool" },
			{ "userdata|GameBoard&", "userdata|Point", "boolean|bool" },
			{ "userdata|GameBoard&", "userdata|Point" }
		}
		
		local iTerrain = self:GetTerrain(loc)
		local isFreezeableTerrain = iTerrain == TERRAIN_BUILDING or iTerrain == TERRAIN_MOUNTAIN
		
		if frozen == nil then
			frozen = true
		end
		
		if no_animation == nil then
			no_animation = false
		end
		
		if no_animation and self:GetCustomTile(loc) == "" then
			self:SetCustomTile(loc, "snow.png")
		end
		
		if no_animation and self:IsPawnSpace(loc) then
			self:GetPawn(loc):SetFrozen(frozen, no_animation)
			
			if frozen then
				CUtils.SetTileFire(self, loc, false)
			end
			
		elseif no_animation and isFreezeableTerrain then
			CUtils.SetTileFrozen(self, loc, frozen)
		else
			oldSetFrozen(self, loc, frozen)
		end
	end
	
	-- the PointList returned by vanilla GetBuildings is inconsistent.
	-- destroyed buildings will linger as valid points until SetTerrain is used.
	local oldGetBuildings = board.GetBuildings
	BoardClass.GetBuildings = function(self)
		
		local buildings = oldGetBuildings(self)
		
		for i = buildings:size(), 1, -1 do
			local isBuilding = self:IsTerrain(buildings:index(i), TERRAIN_BUILDING) 
			
			if not isBuilding then
				buildings:erase(i)
			end
		end
		
		return buildings
	end
	
	-- TODO: add function SetAcid(board, bool, bool) with instant acid application/removal
end

local board_metatable
local doInit = true
local oldSetBoard = SetBoard
function SetBoard(board)
	if board ~= nil then
		
		if doInit then
			doInit = nil
			
			InitializeBoardClass(board)
			
			local old_metatable = getmetatable(board)
			board_metatable = copy_table(old_metatable)
			
			board_metatable.__index = function(self, key)
				local value = BoardClass[key]
				if value then
					return value
				end
				
				return old_metatable.__index(self, key)
			end
		end
		
		CUtils.SetUserdataMetatable(board, board_metatable)
	end
	
	oldSetBoard(board)
end
