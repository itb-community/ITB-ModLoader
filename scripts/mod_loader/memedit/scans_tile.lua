
local rootpath = GetParentPath(...)
local Scan = require(rootpath.."scan")
local utils = require(rootpath.."utils")
local inheritClass = utils.inheritClass
local boardExists = utils.boardExists
local randomCleanPoint = utils.randomCleanPoint
local randomUniqueBuildingPoint = utils.randomUniqueBuildingPoint
local randomNonUniqueBuildingPoint = utils.randomNonUniqueBuildingPoint
local requireScanMovePawn = utils.requireScanMovePawn
local cleanupScanMovePawn = utils.cleanupScanMovePawn
local scans = {}


local tilePreRequisites = {
	"vital.size_tile",
	"vital.delta_rows",
	"vital.step_rows"
}


scans.acid = inheritClass(Scan, {
	id = "Acid",
	name = "Tile Acid",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "bool",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomCleanPoint()
			local isAcid = math.random(0,1)
			Board:SetAcid(p, isAcid == 1)
			self:searchTile(p, isAcid, "byte")
			self:evaluateResults()
			Board:ClearSpace(p)
		end
	},
})

scans.fireType = inheritClass(Scan, {
	id = "FireType",
	name = "Tile Fire Type",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "byte",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomCleanPoint()
			local isFire = math.random(0,1)
			Board:SetFire(p, isFire == 1)
			self:searchTile(p, isFire)
			self:evaluateResults()
			Board:ClearSpace(p)
		end
	},
})

scans.frozen = inheritClass(Scan, {
	id = "Frozen",
	name = "Tile Frozen",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "bool",
	condition = boardExists,
	cleanup = function(self)
		if self.data then
			if Board then
				Board:ClearSpace(self.data.p)
			end
			self.data = nil
		end
	end,
	actions = {
		function(self)
			local p = randomCleanPoint()
			local isFrozen = math.random(0,1)
			Board:SetTerrain(p, TERRAIN_MOUNTAIN)
			Board:SetFrozen(p, isFrozen == 1)
			self.data = {
				p = p,
				isFrozen = isFrozen
			}
		end,
		function(self)
			self:searchTile(self.data.p, self.data.isFrozen, "byte")
			self:evaluateResults()
			self:cleanup()
		end
	},
})

scans.health = inheritClass(Scan, {
	id = "Health",
	name = "Tile Health",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "int",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomNonUniqueBuildingPoint()
			local health = math.random(1,3)
			Board:SetTerrain(p, TERRAIN_BUILDING)
			Board:SetHealth(p, health, 4)
			self:searchTile(p, health)
			self:evaluateResults()
			Board:SetTerrain(p, TERRAIN_ROAD)
		end
	},
})

scans.highlighted = inheritClass(Scan, {
	id = "Highlighted",
	name = "Tile Highlighted",
	prerequisiteScans = tilePreRequisites,
	access = "R",
	dataType = "bool",
	condition = boardExists,
	cleanup = function(self)
		cleanupScanMovePawn()
		if ScanMove.Caller == self then
			ScanMove:TeardownEvent()
		end
	end,
	actions = {
		function(self)
			requireScanMovePawn()

			if self.iteration == 1 then
				ScanMove:SetEvents{
					TargetEvent = self.onMoveHighlighted,
					Caller = self,
				}
			end

			self.issue = "Hover tiles with the provided ScanPawn's Move skill"
		end
	},
	onMoveHighlighted = function(self, pawn, p1, p2)
		for i,p in ipairs(Board) do
			if p == p2 then
				self:searchTile(p, true, "bool")
			else
				self:searchTile(p, false, "bool")
			end
			self:evaluateResults()
		end
	end,
})

scans.maxHealth = inheritClass(Scan, {
	id = "MaxHealth",
	name = "Tile Max Health",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "int",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomNonUniqueBuildingPoint()
			local maxHealth = math.random(2,4)
			Board:SetTerrain(p, TERRAIN_BUILDING)
			Board:SetHealth(p, 1, maxHealth)
			self:searchTile(p, maxHealth)
			self:evaluateResults()
			Board:SetTerrain(p, TERRAIN_ROAD)
		end
	},
})

scans.rubbleType = inheritClass(Scan, {
	id = "RubbleType",
	name = "Tile Rubble Type",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "byte",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomNonUniqueBuildingPoint()
			local rubbleType = math.random(0,1)
			if rubbleType == 0 then
				Board:SetTerrain(p, TERRAIN_BUILDING)
				Board:SetTerrain(p, TERRAIN_RUBBLE)
			else
				Board:SetTerrain(p, TERRAIN_MOUNTAIN)
				Board:SetTerrain(p, TERRAIN_RUBBLE)
			end
			self:searchTile(p, rubbleType)
			self:evaluateResults()
			Board:ClearSpace(p)
		end
	},
})

scans.shield = inheritClass(Scan, {
	id = "Shield",
	name = "Tile Shield",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "bool",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomCleanPoint()
			local isShield = math.random(0,1) * 2
			Board:SetTerrain(p, TERRAIN_MOUNTAIN)
			Board:SetShield(p, isShield == 2)
			self:searchTile(p, isShield, "byte")
			self:evaluateResults()
			Board:ClearSpace(p)
		end
	},
})

scans.smoke = inheritClass(Scan, {
	id = "Smoke",
	name = "Tile Smoke",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "bool",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomCleanPoint()
			local isSmoke = math.random(0,1)
			Board:SetSmoke(p, isSmoke == 1, true)
			self:searchTile(p, isSmoke, "byte")
			self:evaluateResults()
			Board:ClearSpace(p)
		end
	},
})

scans.terrain = inheritClass(Scan, {
	id = "Terrain",
	name = "Tile Terrain",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "int",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomCleanPoint()
			local terrain = math.random(0,1) == 1 and TERRAIN_MOUNTAIN or TERRAIN_ICE
			Board:SetTerrain(p, terrain)
			self:searchTile(p, terrain)
			self:evaluateResults()
			Board:ClearSpace(p)
		end
	},
})

scans.terrainIcon = inheritClass(Scan, {
	id = "TerrainIcon",
	name = "Tile Terrain Icon",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "string",
	condition = boardExists,
	actions = {
		function(self)
			local p = randomCleanPoint()
			local terrainIcon = "testIcon"
			Board:SetTerrainIcon(p, terrainIcon)
			self:searchTile(p, terrainIcon)
			self:evaluateResults()
			Board:SetTerrainIcon(p, "")
		end
	},
})

scans.uniqueBuildingName = inheritClass(Scan, {
	id = "UniqueBuildingName",
	name = "Tile Unique Building Name",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "string",
	condition = boardExists,
	actions = {
		function(self)
			local unique = randomUniqueBuildingPoint()
			-- local nonUnique = randomNonUniqueBuildingPoint()
			-- Board:SetTerrain(unique, TERRAIN_BUILDING)
			self:searchTile(unique, "str_bar1")
			-- self:searchTile(nonUnique, "")
			self:evaluateResults()
		end
	},
})

return scans
