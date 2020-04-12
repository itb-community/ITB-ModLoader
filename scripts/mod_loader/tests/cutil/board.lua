local testsuite = Tests.Testsuite()

local assertEquals = Tests.AssertEquals
local assertNotEquals = Tests.AssertNotEquals
local buildPawnTest = Tests.BuildPawnTest

local function isValidTile(loc)
	return not Board:IsBlocked(loc, PATH_PROJECTILE)
end

-- return all tiles on the board validating the function is_valid_tile.
-- is_valid_tile defaults to isValidTile if no function is provided.
local function getBoardLocations(is_valid_tile)
	is_valid_tile = is_valid_tile or isValidTile
	local result = {}
	local size = Board:GetSize()
	for x = 0, size.x -1 do
		for y = 0, size.y - 1 do
			local loc = Point(x,y)
			
			if isValidTile(loc) then
				result[#result+1] = loc
			end
		end
	end
	
	return result
end

-- returns a random location from a set of locations, validating the function is_valid_tile.
-- is_valid_tile defaults to isValidTile if no function is provided.
-- locations defaults to all locations validating is_valid_tile if no set is provided.
-- the returned location is removed from the set.
local function getRandomLocation(locations, is_valid_tile)
	is_valid_tile = is_valid_tile or isValidTile
	locations = locations or getBoardLocations(is_valid_tile)
	
	return random_removal(locations)
end

testsuite.test_SetFrozen_ShouldFreezePawnsAndMountains = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		pawnLoc = pawn:GetSpace()
		
		local locations = getBoardLocations()
		mountainLoc = getRandomLocation(locations)
		roadLoc = getRandomLocation(locations)
		
		defaultMountainTerrain = Board:GetTerrain(mountainLoc)
		defaultRoadTerrain = Board:GetTerrain(roadLoc)
		Board:SetTerrain(mountainLoc, TERRAIN_MOUNTAIN)
		Board:SetTerrain(roadLoc, TERRAIN_ROAD)
	end,
	execute = function()
		Board:SetFrozen(pawnLoc)
		Board:SetFrozen(mountainLoc)
		Board:SetFrozen(roadLoc)
	end,
	check = function()
		assertEquals(true, Board:IsFrozen(pawnLoc), "Pawn was incorrectly not frozen")
		assertEquals(true, Board:IsFrozen(mountainLoc), "Mountain was incorrectly not frozen")
		assertEquals(false, Board:IsFrozen(roadLoc), "Road was incorrectly frozen")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		Board:SetFrozen(mountainLoc, false)
		Board:SetTerrain(mountainLoc, defaultMountainTerrain)
		Board:SetTerrain(roadLoc, defaultRoadTerrain)
	end
})

return testsuite
