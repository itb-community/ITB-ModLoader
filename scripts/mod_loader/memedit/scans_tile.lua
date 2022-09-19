
local rootpath = GetParentPath(...)
local Scan = require(rootpath.."scan")
local utils = require(rootpath.."utils")
local inheritClass = utils.inheritClass
local boardExists = utils.boardExists
local cleanPoint = utils.cleanPoint
local randomCleanPoint = utils.randomCleanPoint
local nonUniqueBuildingPoint = utils.nonUniqueBuildingPoint
local randomNonUniqueBuildingPoint = utils.randomNonUniqueBuildingPoint
local requireScanMovePawn = utils.requireScanMovePawn
local scans = {}


local tilePreRequisites = {
	"vital.size_tile",
	"vital.delta_rows",
	"vital.step_rows"
}


scans.acid = inheritClass(Scan, {
	id = "Acid",
	questName = "Tile Acid",
	questHelp = "Wait",
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
	questName = "Tile Fire Type",
	questHelp = "Wait",
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
	questName = "Tile Frozen",
	questHelp = "Wait",
	prerequisiteScans = tilePreRequisites,
	access = "RW",
	dataType = "bool",
	condition = boardExists,
	cleanup = function(self)
		if self.data then
			Board:ClearSpace(self.data.p)
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
	questName = "Health",
	questHelp = "Wait",
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
	questName = "Tile Highlighted",
	questHelp = "Wait",
	prerequisiteScans = tilePreRequisites,
	access = "R",
	dataType = "bool",
	condition = boardExists,
	cleanup = function(self)
		if ScanMove.Caller == self then
			ScanMove:TeardownEvent()
		end
	end,
	actions = {
		function(self)
			requireScanMovePawn()

			if self.iteration == 1 then
				ScanMove:RegisterEvent{
					Event = self.onMoveHighlighted,
					Caller = self,
				}
			end

			self.issue = "Hover tiles with the provided ScanPawn's Move skill"
		end
	},
	onMoveHighlighted = function(self, p2)
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
	questName = "Max Health",
	questHelp = "Wait",
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
	questName = "Rubble Type",
	questHelp = "Wait",
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
	questName = "Tile Shield",
	questHelp = "Wait",
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
	questName = "Tile Smoke",
	questHelp = "Wait",
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
	questName = "Terrain",
	questHelp = "Wait",
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
	questName = "Terrain Icon",
	questHelp = "Wait",
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

return scans
