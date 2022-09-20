
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
		return false, "Enter a mission"
	end
end

function utils.missionBoardExists()
	if false
		or Board == nil
		or Board:IsBusy()
		or Board:IsMissionBoard() == false
	then
		return false, "Enter a mission"
	end

	return true
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

local scanMovePawn
local scanMovePawnId
function utils.requireScanMovePawn()

	if false
		or scanMovePawnId == nil
		or Board:GetPawn(scanMovePawnId) == nil
	then
		utils.prepareScanPawn{
			Image = "MechPunch",
			MoveSpeed = 99,
			Health = 9,
			Flying = true,
			DefaultTeam = TEAM_PLAYER,
			SkillList = {"ScanWeapon"},
		}

		scanMovePawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		scanMovePawnId = scanMovePawn:GetId()

		local p = Point(7,7)
		local pawn = Board:GetPawn(p)

		if pawn then
			pawn:SetSpace(Point(-1,-1))
		end

		scanMovePawn:SetHealth(9)
		Board:AddPawn(scanMovePawn, p)
		Board:Ping(p, GL_Color(50, 255, 50))

		if pawn then
			pawn:SetSpace(utils.cleanPoint())
		end
	end

	ScanPawn.Name = "ScanPawn"
	ScanPawn.MoveSkill = "ScanMove"

	return scanMovePawn
end

function utils.cleanupScanMovePawn()
	if Board then
		local pawn = Board:GetPawn(scanMovePawnId)
		if pawn then
			pawn:SetHealth(0)
		end
	end
end

return utils
