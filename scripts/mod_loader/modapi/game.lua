
local GameClass = {}

GameClass.GetRep = function()
	return CUtils.GetRep()
end

GameClass.GetPow = function()
	return CUtils.GetPower()
end

GameClass.GetMaxPow = function()
	return CUtils.GetMaxPower()
end

GameClass.GetCores = function()
	return CUtils.GetCores()
end

GameClass.GetGridDef = function()
	return CUtils.GetGridDef()
end


GameClass.AddRep = function(reputation)
	Tests.AssertSignature{
		ret = "void",
		func = "AddRep",
		params = { reputation },
		{ "number|int" }
	}
	
	local current = CUtils.GetRep()
	local new = math.max(0, current + reputation)
	
	CUtils.SetRep(new)
end

GameClass.SubRep = function(reputation)
	GameClass.AddRep(-reputation)
end

GameClass.AddPow = function(power)
	Tests.AssertSignature{
		ret = "void",
		func = "AddPow",
		params = { power },
		{ "number|int" }
	}
	
	local current = CUtils.GetPower()
	local new = math.max(0, current + power)
	
	CUtils.SetPower(new)
end

GameClass.SubPow = function(power)
	GameClass.AddPow(-power)
end

GameClass.AddMaxPow = function(power_max)
	Tests.AssertSignature{
		ret = "void",
		func = "AddMaxPow",
		params = { power_max },
		{ "number|int" }
	}
	
	local current = CUtils.GetMaxPower()
	local new = math.max(1, current + power_max)
	
	CUtils.SetMaxPower(new)
end

GameClass.SubMaxPow = function(power_max)
	GameClass.AddMaxPow(-power_max)
end

GameClass.AddCores = function(cores)
	Tests.AssertSignature{
		ret = "void",
		func = "AddCores",
		params = { cores },
		{ "number|int" }
	}
	
	local current = CUtils.GetCores()
	local new = math.max(0, current + cores)
	
	CUtils.SetCores(new)
end

GameClass.SubCores = function(cores)
	GameClass.AddCores(-cores)
end

GameClass.AddGridDef = function(grid_def)
	Tests.AssertSignature{
		ret = "void",
		func = "AddGridDef",
		params = { grid_def },
		{ "number|int" }
	}
	
	local current = CUtils.GetGridDef()
	local new = math.min(85, math.max(-15, current + grid_def))
	
	CUtils.SetGridDef(new)
end

GameClass.SubGridDef = function(grid_def)
	GameClass.AddGridDef(-grid_def)
end


GameClass.IsCogHovered = function()
	return CUtils.IsCogHovered()
end

GameClass.IsRepHovered = function()
	return CUtils.IsRepHovered()
end

GameClass.IsCoreHovered = function()
	return CUtils.IsCoreHovered()
end

GameClass.IsPowerHovered = function()
	return CUtils.IsPowerHovered()
end

GameClass.IsGridDefHovered = function()
	return CUtils.IsGridDefHovered()
end

GameClass.IsPeopleHovered = function()
	return CUtils.IsPeopleHovered()
end


function InitializeGameClass()
	-- modify existing game functions here
end

local game_metatable
local doInit = true
local oldSetGame = SetGame
function SetGame(game)
	if game ~= nil then
		
		if doInit then
			doInit = nil
			
			InitializeGameClass(game)
			
			local old_metatable = getmetatable(game)
			game_metatable = copy_table(old_metatable)
			
			game_metatable.__index = function(self, key)
				local value = GameClass[key]
				if value then
					return value
				end
				
				return old_metatable.__index(self, key)
			end
		end
		
		CUtils.SetUserdataMetatable(game, game_metatable)
	end
	
	oldSetGame(game)
end
