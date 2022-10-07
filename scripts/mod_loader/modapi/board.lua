local DequeList = require("scripts/mod_loader/deque_list")

BoardClass = Board

BoardClass.MovePawnsFromTile = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	-- In case there are multiple pawns on the same tile
	local pawnStack = DequeList()
	local point = Point(-1, -1)

	while self:IsPawnSpace(loc) do
		local pawn = self:GetPawn(loc)
		pawnStack:pushLeft(pawn)
		pawn:SetSpace(point)
	end

	return pawnStack
end

BoardClass.RestorePawnsToTile = function(self, loc, pawnStack)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	Assert.Equals("table", type(pawnStack), "Argument #2")

	while not pawnStack:isEmpty() do
		local pawn = pawnStack:popLeft()
		pawn:SetSpace(loc)
	end
end

BoardClass.SetFire = function(self, loc, fire)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	Assert.Equals("boolean", type(fire), "Argument #2")

	local pawnStack = self:MovePawnsFromTile(loc)

	local dmg = SpaceDamage(loc)
	dmg.iFire = fire and EFFECT_CREATE or EFFECT_REMOVE
	self:DamageSpace(dmg)

	self:RestorePawnsToTile(loc, pawnStack)
end

-- gets the currently active psion on the board, returns a value from the LEADER globals if found, nil if not
BoardClass.GetMutation = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local enemies = self:GetPawns(TEAM_ENEMY)
	-- scan the board for a psion, if found return its effect
	-- note that when multiple psions exist, the mutation is the newest psion, this is consistent with the game logic
	-- this also may give inaccurate results in the mech tester, as spawning a psion does not update mutations there
	for i = enemies:size(), 1, -1 do
		local leader = _G[self:GetPawn(enemies:index(i)):GetType()]:GetLeader()
		if leader ~= LEADER_NONE then
			return leader
		end
	end
	return nil
end

-- checks if the given mutation is active on the board. Note that for health, regen, and explision, returns true for th especific psion and the boss
BoardClass.IsMutation = function(self, predicate)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("number", type(predicate), "Argument #1")

	-- for boss psions, return true if any of the three were passed as the argument
	local mutation = self:GetMutation()
	return mutation == predicate or (mutation == LEADER_BOSS and (predicate == LEADER_HEALTH or predicate == LEADER_REGEN or predicate == LEADER_EXPLODE))
end

BoardClass.GetLuaString = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	local size = self:GetSize()
	return string.format("Board [width = %s, height = %s]", size.x, size.y)
end
BoardClass.GetString = BoardClass.GetLuaString

BoardClass.IsMissionBoard = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	return self:GetSize() ~= Point(6,6)
end

BoardClass.IsTipImage = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	return self:GetSize() == Point(6,6)
end

BoardClass.GetSelectedPawn = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	local pawns = Board:GetPawns(TEAM_ANY)
	for i = 1, pawns:size() do
		local pawn = Board:GetPawn(pawns:index(i))
		if pawn and pawn:IsSelected() then
			return pawn
		end
	end
	
	return nil
end

BoardClass.GetSelectedPawnId = function(self)
	local selectedPawn = self:GetSelectedPawn()
	
	if selectedPawn then
		return selectedPawn:GetId()
	end
	
	return nil
end

BoardClass.GetTile = function(self, predicateFn)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("function", type(predicateFn), "Argument #1")

	for _, p in ipairs(self) do
		if predicateFn(p) then
			return p
		end
	end

	return nil
end

BoardClass.GetTiles = function(self, predicateFn)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals({"nil", "function"}, type(predicateFn), "Argument #1")

	local result = PointList()

	for _, p in ipairs(self) do
		if not predicateFn or (predicateFn and predicateFn(p)) then
			result:push_back(p)
		end
	end

	return result
end

BoardClass.__ipairs = function(self, ...)
	Assert.Equals("userdata", type(self), "Argument #0")

	local index = 0
	local size = self:GetSize()
	return function()
		if index < size.x * size.y then
			local p = Point(index % size.x, math.floor(index / size.x))
			index = index + 1
			return index, p
		end
	end
end


-- memedit functions
--------------------

local getMemedit = modApi.getMemedit
local requireMemedit = modApi.requireMemedit

BoardClass.GetFireType = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local result

	try(function()
		result = requireMemedit().board.getFireType(loc)
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

BoardClass.GetHighlighted = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local memedit = getMemedit()
	if memedit then
		local result

		try(function()
			result = Point(
				memedit.board.getHighlightedX(loc),
				memedit.board.getHighlightedY(loc)
			)
		end)
		:catch(function(err)
			error(string.format(
					"memedit.dll: %s",
					tostring(err)
			))
		end)

		return result
	end

	if GetCurrentMission() == nil then
		return
	end

	return mouseTile()
end

BoardClass.GetMaxHealth = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local result

	try(function()
		result = requireMemedit().board.getMaxHealth(loc)
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

BoardClass.GetTerrainIcon = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local result

	try(function()
		result = requireMemedit().board.getTerrainIcon(loc)
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

BoardClass.GetUniqueBuilding = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local result

	try(function()
		result = requireMemedit().board.getUniqueBuildingName(loc)
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

BoardClass.IsForest = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local result

	try(function()
		local memedit = requireMemedit()
		local fireType = memedit.board.getFireType(loc)
		local terrain = memedit.board.getTerrain(loc)

		result = false
			or terrain == TERRAIN_FOREST
			or fireType == FIRE_TYPE_FOREST_FIRE
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

BoardClass.IsForestFire = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local result

	try(function()
		result = requireMemedit().board.getFireType(loc) == FIRE_TYPE_FOREST_FIRE
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

BoardClass.IsHighlighted = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local memedit = getMemedit()
	if memedit then
		local result

		try(function()
			result = memedit.board.isHighlighted(loc)
		end)
		:catch(function(err)
			error(string.format(
					"memedit.dll: %s",
					tostring(err)
			))
		end)

		return result
	end

	if GetCurrentMission() == nil then
		return
	end

	return loc == mouseTile()
end

BoardClass.IsShield = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

	local result

	try(function()
		result = requireMemedit().board.isShield(loc)
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

-- SetSmoke has two parameter. Param #2 allows setting smoke
-- without an animation. Add this functionality to SetShield.
BoardClass.SetShield = function(self, loc, shield, skipAnimation)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	Assert.Equals("boolean", type(shield), "Argument #2")
	Assert.Equals({"nil", "boolean"}, type(skipAnimation), "Argument #3")

	local memedit = getMemedit()
	if memedit and skipAnimation then
		try(function()
			local terrain = memedit.board.getTerrain(loc)
			local isShieldableTerrain = false
				or terrain == TERRAIN_MOUNTAIN
				or terrain == TERRAIN_BUILDING

			if isShieldableTerrain then
				memedit.board.setShield(loc, shield)
			else
				local pawn = self:GetPawn(loc)
				if pawn then
					pawn:SetShield(shield, skipAnimation)
				end
			end
		end)
		:catch(function(err)
			error(string.format(
					"memedit.dll: %s",
					tostring(err)
			))
		end)

		return
	end

	if shield then
		self:AddShield(loc)
	else
		self:RemoveShield(loc)
	end
end

BoardClass.SetUniqueBuilding = function(self, loc, structureId)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	Assert.Equals("string", type(structureId), "Argument #2")

	local terrains = { [loc.y * self:GetSize().x + loc.x + 1] = self:GetTerrain(loc) }
	local memedit = getMemedit()

	if structureId ~= "" then
		-- Change all buildings to roads
		for i, p in ipairs(self) do
			local terrain = self:GetTerrain(p)

			if terrain == TERRAIN_BUILDING then
				terrains[i] = terrain
				self:SetTerrain(p, TERRAIN_ROAD)
			end
		end
	end

	if memedit then
		try(function()
			memedit.board.setUniqueBuildingName(loc, "")
		end)
		:catch(function(err)
			error(string.format(
					"memedit.dll: %s",
					tostring(err)
			))
		end)
	end

	if structureId ~= "" then
		-- Create a single building so it is the only one
		-- that can be converted to a unique building
		self:SetTerrain(loc, TERRAIN_ROAD)
		self:SetTerrain(loc, TERRAIN_BUILDING)
		self:AddUniqueBuilding(structureId)

		-- Revart all buildings back to buildings
		for i, p in ipairs(self) do
			if terrains[i] then
				self:SetTerrain(p, terrains[i])
			end
		end
	end
end


local boardClass = BoardClass
local boardInitialized = false

local function initializeBoardClass(board)
	boardInitialized = true


	-- Override existing Board class functions here


	-- SetSmoke has two parameter. Param #2 allows setting smoke
	-- without an animation. Add this functionality to SetAcid.
	boardClass.SetAcidVanilla = board.SetAcid
	boardClass.SetAcid = function(self, loc, acid, skipAnimation)
		Assert.Equals("userdata", type(self), "Argument #0")
		Assert.TypePoint(loc, "Argument #1")
		Assert.Equals("boolean", type(acid), "Argument #2")
		Assert.Equals({"nil", "boolean"}, type(skipAnimation), "Argument #3")

		local memedit = getMemedit()
		if memedit and skipAnimation then
			try(function()
				memedit.board.setAcid(loc, acid)
			end)
			:catch(function(err)
				error(string.format(
						"memedit.dll: %s",
						tostring(err)
				))
			end)

			return
		end

		self:SetAcidVanilla(loc, acid)
	end

	-- SetSmoke has two parameter. Param #2 allows setting smoke
	-- without an animation. Add this functionality to SetFrozen.
	boardClass.SetFrozenVanilla = board.SetFrozen
	boardClass.SetFrozen = function(self, loc, frozen, skipAnimation)
		Assert.Equals("userdata", type(self), "Argument #0")
		Assert.TypePoint(loc, "Argument #1")
		Assert.Equals("boolean", type(frozen), "Argument #2")
		Assert.Equals({"nil", "boolean"}, type(skipAnimation), "Argument #3")

		local memedit = getMemedit()
		if memedit and skipAnimation then
			try(function()
				local terrain = memedit.board.getTerrain(loc)
				local customTile = self:GetCustomTile(loc)
				local fireType = memedit.board.getFireType(loc)
				local isFreezableTerrain = false
					or terrain == TERRAIN_MOUNTAIN
					or terrain == TERRAIN_BUILDING

				if frozen then
					if customTile == "" then
						self:SetCustomTile(loc, "snow.png")
					end

					if fireType ~= FIRE_TYPE_NONE then
						memedit.board.setFireType(loc, FIRE_TYPE_NONE)
					end
				end

				if isFreezableTerrain then
					memedit.board.setFrozen(loc, frozen)
				else
					local pawn = self:GetPawn(loc)
					if pawn then
						pawn:SetFrozen(frozen, skipAnimation)
					end
				end
			end)
			:catch(function(err)
				error(string.format(
						"memedit.dll: %s",
						tostring(err)
				))
			end)

			return
		end

		self:SetFrozenVanilla(loc, frozen)
	end


	modApi.events.onBoardClassInitialized:dispatch(boardClass, board)
	modApi.events.onBoardClassInitialized:unsubscribeAll()

	boardClass = nil
end

local oldSetBoard = SetBoard
function SetBoard(board)
	if true
		and board ~= nil
		and boardInitialized == false
	then
		initializeBoardClass(board)
	end

	oldSetBoard(board)
end
