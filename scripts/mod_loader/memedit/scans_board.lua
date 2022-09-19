
local rootpath = GetParentPath(...)
local Scan = require(rootpath.."scan")
local utils = require(rootpath.."utils")
local inheritClass = utils.inheritClass
local boardExists = utils.boardExists
local requireScanMovePawn = utils.requireScanMovePawn
local scans = {}

local boardPreRequisites = {"vital.size_board"}

scans.highlightedX = inheritClass(Scan, {
	id = "HighlightedX",
	questName = "Board HighlightedX",
	questHelp = "Wait",
	prerequisiteScans = boardPreRequisites,
	access = "R",
	dataType = "int",
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
		self:searchBoard(p2.x)
		self:evaluateResults()
	end,
})

scans.highlightedY = inheritClass(Scan, {
	id = "HighlightedY",
	questName = "Board HighlightedY",
	questHelp = "Wait",
	prerequisiteScans = boardPreRequisites,
	access = "R",
	dataType = "int",
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
		self:searchBoard(p2.y)
		self:evaluateResults()
	end,
})

return scans
