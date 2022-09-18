
-- A collection of shared utility functions
-- used by various scans.

local utils = {}

-- Inherits from a class, and applies the
-- given table onto the returned class
-- instance object.
function utils.inheritClass(from, to)
	local o = Class.inherit(from)

	for i,v in pairs(to) do
		o[i] = v
	end

	return o
end

function utils.boardExists()
	if true
		and Board ~= nil
		and Board:IsBusy() == false
	then
		return true
	else
		return false, "Board not found"
	end
end

-- Destructive function calculating the smallest
-- gap between any of its values.
function utils.findSmallestGap(tbl)
	table.sort(tbl, function(a,b) return a<b end)

	local mindist = INT_MAX
	for i = 2, #tbl do
		local dist = tbl[i] - tbl[i-1]
		if dist ~= 0 and dist < mindist then
			mindist = dist
		end
	end

	return mindist
end

-- Returns a healthy mech if one can be found.
function utils.getMech()
	for i = 0, 2 do
		local mech = Game:GetPawn(i)
		if mech then
			-- Revive if dead
			mech:SetHealth(10)
			return mech
		end
	end
end

-- Resets the definition of ScanPawn and
-- applies the new definition onto it.
function utils.prepareScanPawn(def)
	for i,v in pairs(ScanPawn) do
		ScanPawn[i] = nil
	end

	for i,v in pairs(def or {}) do
		ScanPawn[i] = v
	end
end

-- Finds a tile without any unit on it,
-- and resets it with Board:ClearSpace
-- before returning it.
-- If there are no such tiles throw an error.
function utils.cleanPoint(random)
	local result
	local board = Board

	if random then
		board = randomize(extract_table(Board:GetTiles()))
	end

	for _, p in ipairs(board) do
		if not Board:IsPawnSpace(p) then
			result = p
			break
		end
	end

	if result == nil then
		error("Unable to find a tile without a pawn")
	end

	Board:ClearSpace(result)
	return result
end

-- Finds a tile that if turned into a building,
-- will not be a unique building; and also does
-- not have a pawn occupying it.
-- If there are no such tiles throw an error.
function utils.nonUniqueBuildingPoint(random)
	local result = Point(0,0)
	local board = Board

	if random then
		board = randomize(extract_table(Board:GetTiles()))
	end

	for _, p in ipairs(board) do
		if not Board:IsPawnSpace(p) then
			local terrain = Board:GetTerrain(p)
			Board:SetTerrain(p, TERRAIN_BUILDING)
			local isUniqueBuilding = Board:IsUniqueBuilding(p)
			Board:SetTerrain(p, terrain)

			if not isUniqueBuilding then
				result = p
				break
			end
		end
	end

	if result == nil then
		error("Unable to find a non-unique-building-tile without a pawn")
	end

	Board:ClearSpace(result)
	return result
end

-- Same as cleanPoint, but randomize the
-- returned tile
function utils.randomCleanPoint()
	return utils.cleanPoint(true)
end

-- Same as nonUniqueBuildingPoint, but randomize the
-- returned tile
function utils.randomNonUniqueBuildingPoint()
	return utils.cleanPoint(true)
end

-- Removes all units of a specified team.
function utils.removePawns(team)
	local pawns = Board:GetPawns(team)
	for i = 1, pawns:size() do
		local pawn = Board:GetPawn(pawns:index(i))
		Board:RemovePawn(pawn)
	end
end

return utils
