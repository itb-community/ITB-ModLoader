local DequeList = require("scripts/mod_loader/deque_list")
local boardOverrides = {}
local doInit = true
local hooks = {}

local boardKeys = {
	"AddAlert",
	"AddAnimation",
	"AddBurst", -- 2 signatures
	"AddEffect",
	"AddPawn",
	"AddTeleport",
	"AddUniqueBuilding",
	"BlockSpawn",
	"Bounce",
	"ClearBlockSpawns",
	"ClearSpace",
	"Crack",
	"DamageSpace", -- 2 signatures
	"Fade",
	"GetAnotherPlayerPawn",
	"GetBuildingCount",
	"GetBuildings",
	"GetBusyState",
	"GetDistance",
	"GetDistanceToBuilding",
	"GetDistanceToPawn",
	"GetEnemyCount",
	"GetMechDamage",
	"GetPath",
	"GetPawn", -- 2 signatures
	"GetPawnCount",
	"GetPawnSpace",
	"GetPawnTeam", -- 2 signatures
	"GetPawns",
	"GetRandomBuilding",
	"GetReachable",
	"GetSimplePath",
	"GetSimpleReachable",
	"GetSize",
	"GetSpawnCount", -- 2 signatures
	"GetTerrain", -- 2 signatures
	"GetTurn",
	"GetZone",
	"IsAcid",
	"IsBlocked",
	"IsBuilding", -- 2 signatures
	"IsDamaged",
	"IsDangerous",
	"IsDangerousItem",
	"IsEdge",
	"IsEnvironmentDanger",
	"IsFire",
	"IsFrozen",
	"IsItem",
	"IsPawnAlive",
	"IsPawnSpace",
	"IsPawnTeam",
	"IsPod",
	"IsPowered",
	"IsSafe",
	"IsSmoke",
	"IsSpawning",
	"IsTargeted",
	"IsTerrain",
	"IsUniqueBuilding",
	"IsValid", -- 2 signatures
	"IsVines",
	"IsWall",
	"LockBomb",
	"MarkFlashing",
	"MarkSpaceColor",
	"MarkSpaceDamage",
	"MarkSpaceDesc",
	"MarkSpaceImage",
	"MarkSpaceSimpleColor",
	"Ping",
	"RandomizeTerrain",
	"RemovePawn", -- 2 signatures
	"RemoveShield",
	"SetAcid",
	"SetCustomTile",
	"SetDangerous",
	"SetFrozen",
	"SetItem",
	"SetLava",
	"SetPopulated",
	"SetSmoke",
	"SetTerrain",
	"SetTerrainIcon",
	"SetWall",
	"SetWeather",
	"Slide",
	"SpawnPawn", -- 2 signatures
	"SpawnQueued",
	"StartMechTravel",
	"StartPopEvent",
	"StartShake",
	"StopWeather",
}

BoardClass = Board

local oldSetBoard = SetBoard
function SetBoard(board)
	if board and doInit then
		for i, fn in pairs(boardOverrides) do
			local oldFunc = board[i]
			
			BoardClass[i] = function(self, ...)
				return oldFunc(self, fn(self, ...))
			end
		end
		
		doInit = nil
	end
	
	oldSetBoard(board)
end

for _, key in ipairs(boardKeys) do
	modApi:AddHook("board".. key)
	
	modApi["fireBoard".. key .."Hooks"] = function(...)
		local result = {...}
		
		for _, fn in ipairs(modApi["board".. key .."Hooks"]) do
			local output = {fn(unpack(result))}
			
			if output and #output > 0 then
				result = output
			end
		end
		
		return unpack(result)
	end
	
	boardOverrides[key] = function(self, ...)
		return modApi["fireBoard".. key .."Hooks"](...)
	end
end

BoardClass.MovePawnsFromTile = function(self, loc)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertTypePoint(loc, "Argument #1")

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
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertTypePoint(loc, "Argument #1")
	Tests.AssertEquals("table", type(pawnStack), "Argument #2")

	while not pawnStack:isEmpty() do
		local pawn = pawnStack:popLeft()
		pawn:SetSpace(loc)
	end
end

BoardClass.SetFire = function(self, loc, fire)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertTypePoint(loc, "Argument #1")
	Tests.AssertEquals("boolean", type(fire), "Argument #2")

	local pawnStack = self:MovePawnsFromTile(loc)

	local dmg = SpaceDamage(loc)
	dmg.iFire = fire and EFFECT_CREATE or EFFECT_REMOVE
	self:DamageSpace(dmg)

	self:RestorePawnsToTile(loc, pawnStack)
end

BoardClass.GetLuaString = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	local size = self:GetSize()
	return string.format("Board [width = %s, height = %s]", size.x, size.y)
end
BoardClass.GetString = BoardClass.GetLuaString
	
BoardClass.IsMissionBoard = function(self)
	return Board.mission ~= nil
end

BoardClass.IsTipImage = function(self)
	return Board.mission == nil
end
