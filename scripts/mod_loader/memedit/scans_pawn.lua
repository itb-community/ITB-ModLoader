
local rootpath = GetParentPath(...)
local Scan = require(rootpath.."scan")
local utils = require(rootpath.."utils")
local inheritClass = utils.inheritClass
local prepareScanPawn = utils.prepareScanPawn
local removePawns = utils.removePawns
local boardExists = utils.boardExists
local cleanPoint = utils.cleanPoint
local randomCleanPoint = utils.randomCleanPoint
local getMech = utils.getMech
local scans = {}


scans.id = inheritClass(Scan, {
	id = "Id",
	questName = "Pawn Id",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	expectedResults = 2,
	expectedResultIndex = 1,
	access = "RW",
	dataType = "int",
	action = function(self)
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, pawn:GetId())
		self:evaluateResults()
	end
})

scans.mech = inheritClass(Scan, {
	id = "Mech",
	questName = "Pawn Mech",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local isMech = math.random(0,1)
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		if isMech == 1 then
			pawn:SetMech()
		end

		self:searchPawn(pawn, isMech, "byte")
		self:evaluateResults()
	end
})

scans.queuedTargetX = inheritClass(Scan, {
	id = "QueuedTargetX",
	questName = "Pawn Queued Target X",
	questHelp = "Wait",
	prerequisiteScans = {
		"vital.size_pawn",
		"vital.delta_weapons"
	},
	access = "RW",
	dataType = "int",
	expectedResults = 3,
	expectedResultIndex = 2,
	condition = boardExists,
	action = function(self)
		local p1 = randomCleanPoint()
		local p2 = randomCleanPoint()

		prepareScanPawn{ SkillList = {"ScanWeaponQueued"} }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		Board:AddPawn(pawn, p1)
		pawn:FireWeapon(p2, 1)

		self:searchPawn(pawn, p2.x)
		self:evaluateResults()
		Board:ClearSpace(p1)
	end
})

scans.queuedTargetY = inheritClass(Scan, {
	id = "QueuedTargetY",
	questName = "Pawn Queued Target Y",
	questHelp = "Wait",
	prerequisiteScans = {
		"vital.size_pawn",
		"vital.delta_weapons"
	},
	access = "RW",
	dataType = "int",
	expectedResults = 3,
	expectedResultIndex = 2,
	condition = boardExists,
	action = function(self)
		local p1 = randomCleanPoint()
		local p2 = randomCleanPoint()

		prepareScanPawn{ SkillList = {"ScanWeaponQueued"} }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		Board:AddPawn(pawn, p1)
		pawn:FireWeapon(p2, 1)

		self:searchPawn(pawn, p2.y)
		self:evaluateResults()
		Board:ClearSpace(p1)
	end
})

scans.owner = inheritClass(Scan, {
	id = "Owner",
	questName = "Pawn Owner",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	condition = boardExists,
	cleanup = function(self)
		if self.data then
			Board:ClearSpace(self.data.p)
			self.data = nil
		end
	end,
	actions = {
		function(self)
			self.data = {
				p = randomCleanPoint(),
				owner = math.random(3,13)
			}

			prepareScanPawn()
			local fx = SkillEffect()
			local d = SpaceDamage(self.data.p)
			d.sPawn = "ScanPawn"
			fx.iOwner = self.data.owner
			fx:AddDamage(d)
			Board:AddEffect(fx)
		end,
		function(self)
			local pawn = Board:GetPawn(self.data.p)
			self:searchPawn(pawn, self.data.owner)
			self:evaluateResults()
			self:cleanup()
		end
	},
})

scans.maxHealth = inheritClass(Scan, {
	id = "MaxHealth",
	questName = "Pawn Max Health",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	expectedResults = 2,
	expectedResultIndex = 1,
	access = "RW",
	dataType = "int",
	action = function(self)
		local hp = math.random(3, 13)
		prepareScanPawn{ Health = hp }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		pawn:SetHealth(1)

		self:searchPawn(pawn, hp)
		self:evaluateResults()
	end
})

scans.baseMaxHealth = inheritClass(Scan, {
	id = "BaseMaxHealth",
	questName = "Pawn Base Max Health",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	expectedResults = 2,
	expectedResultIndex = 2,
	access = "RW",
	dataType = "int",
	action = function(self)
		local hp = math.random(3, 13)
		prepareScanPawn{ Health = hp }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		pawn:SetHealth(1)

		self:searchPawn(pawn, hp)
		self:evaluateResults()
	end
})

scans.boosted = inheritClass(Scan, {
	id = "Boosted",
	gameVersion = "1.2.63",
	questName = "Pawn Boosted",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn", "vital.delta_weapons"},
	access = "RW",
	-- Set this to bool so we get is/set functions
	-- even though the value type is a byte.
	dataType = "bool",
	condition = function(self)
		if false
			or Board == nil
			or Board:IsBusy()
			or Board:IsMissionBoard() == false
		then
			return false, "MissionBoard not found"
		elseif getMech() == nil then
			return false, "Mech not found"
		end

		return true
	end,
	cleanup = function(self)
		self.data = nil
	end,
	actions = {
		function(self)
			local dll = modApi.memedit.dll
			removePawns(TEAM_ENEMY)

			local mech = getMech()
			local p = mech:GetSpace()
			local isBoosted = math.random(0,1)

			Board:SetTerrain(p, TERRAIN_ROAD)

			-- Remove weapons from all mechs.
			for pawnId = 0, 2 do
				local pawn = Board:GetPawn(pawnId)
				if pawn then
					local weaponCount = dll.pawn.getWeaponCount(pawn)
					for weaponIndex = 1, weaponCount do
						dll.pawn.removeWeapon(pawn, 1)
					end
				end
			end

			if isBoosted == 1 then
				mech:AddWeapon("ScanWeapon")
				mech:AddWeapon("Passive_FireBoost")
				Board:SetFire(p, true)
			else
				mech:AddWeapon("ScanWeapon")
				mech:FireWeapon(p, 1)
			end

			self.data = {
				mech = mech,
				isBoosted = isBoosted,
			}
		end,
		function(self)
			self:searchPawn(self.data.mech, self.data.isBoosted, "byte")
			self:evaluateResults()
		end
	},
})

scans.class = inheritClass(Scan, {
	id = "Class",
	questName = "Pawn Class",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "string",
	action = function(self)
		local class = "ScanClass"..tostring(math.random(3,13))
		prepareScanPawn{ Class = class }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, class)
		self:evaluateResults()
	end
})

scans.imageOffset = inheritClass(Scan, {
	id = "ImageOffset",
	questName = "Pawn Image Offset",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	action = function(self)
		local imageOffset = math.random(3,13)
		prepareScanPawn{ ImageOffset = imageOffset }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, imageOffset)
		self:evaluateResults()
	end
})

scans.moveSpeed = inheritClass(Scan, {
	id = "MoveSpeed",
	questName = "Pawn Move Speed",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	action = function(self)
		local moveSpeed = math.random(3,13)
		prepareScanPawn{ MoveSpeed = moveSpeed }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, moveSpeed)
		self:evaluateResults()
	end
})

scans.impactMaterial = inheritClass(Scan, {
	id = "ImpactMaterial",
	questName = "Pawn Impact Material",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	action = function(self)
		local impactMaterial = math.random(3,13)
		prepareScanPawn{ ImpactMaterial = impactMaterial }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, impactMaterial)
		self:evaluateResults()
	end
})

scans.leader = inheritClass(Scan, {
	id = "Leader",
	questName = "Pawn Leader",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	action = function(self)
		local leader = math.random(3,13)
		prepareScanPawn{ Leader = leader }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, leader)
		self:evaluateResults()
	end
})

scans.defaultfaction = inheritClass(Scan, {
	id = "Leader",
	questName = "Pawn Default Faction",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	action = function(self)
		local defaultfaction = math.random(3,13)
		prepareScanPawn{ DefaultFaction = defaultfaction }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, defaultfaction)
		self:evaluateResults()
	end
})

scans.spacecolor = inheritClass(Scan, {
	id = "SpaceColor",
	questName = "Pawn Space Color",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local spacecolor = math.random(0,1) == 1
		prepareScanPawn{ SpaceColor = spacecolor }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, spacecolor)
		self:evaluateResults()
	end
})

scans.minor = inheritClass(Scan, {
	id = "Minor",
	questName = "Pawn Minor",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local minor = math.random(0,1) == 1
		prepareScanPawn{ Minor = minor }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, minor)
		self:evaluateResults()
	end
})

scans.neutral = inheritClass(Scan, {
	id = "Neutral",
	questName = "Pawn Neutral",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local neutral = math.random(0,1) == 1
		prepareScanPawn{ Neutral = neutral }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, neutral)
		self:evaluateResults()
	end
})

scans.pushable = inheritClass(Scan, {
	id = "Pushable",
	questName = "Pawn Pushable",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local pushable = math.random(0,1) == 1
		prepareScanPawn{ Pushable = pushable }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, pushable)
		self:evaluateResults()
	end
})

scans.corpse = inheritClass(Scan, {
	id = "Corpse",
	questName = "Pawn Corpse",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local corpse = math.random(0,1) == 1
		prepareScanPawn{ Corpse = corpse }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, corpse)
		self:evaluateResults()
	end
})

scans.massive = inheritClass(Scan, {
	id = "Massive",
	questName = "Pawn Massive",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local massive = math.random(0,1) == 1
		prepareScanPawn{ Massive = massive }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, massive)
		self:evaluateResults()
	end
})

scans.flying = inheritClass(Scan, {
	id = "Flying",
	questName = "Pawn Flying",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local flying = math.random(0,1) == 1
		prepareScanPawn{ Flying = flying }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, flying)
		self:evaluateResults()
	end
})

scans.jumper = inheritClass(Scan, {
	id = "Jumper",
	questName = "Pawn Jumper",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local jumper = math.random(0,1) == 1
		prepareScanPawn{ Jumper = jumper }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, jumper)
		self:evaluateResults()
	end
})

scans.teleporter = inheritClass(Scan, {
	id = "Teleporter",
	questName = "Pawn Teleporter",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		local teleporter = math.random(0,1) == 1
		prepareScanPawn{ Teleporter = teleporter }
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")

		self:searchPawn(pawn, teleporter)
		self:evaluateResults()
	end
})

scans.team = inheritClass(Scan, {
	id = "Team",
	questName = "Pawn Team",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local team = math.random(3,13)
		pawn:SetTeam(team)

		self:searchPawn(pawn, team)
		self:evaluateResults()
	end
})

scans.mutation = inheritClass(Scan, {
	id = "Mutation",
	questName = "Pawn Mutation",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "int",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local mutation = math.random(3,13)
		pawn:SetMutation(mutation)

		self:searchPawn(pawn, mutation)
		self:evaluateResults()
	end
})

scans.customAnim = inheritClass(Scan, {
	id = "CustomAnim",
	questName = "Pawn Custom Animation",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "string",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local customAnim = "ScanAnim"..tostring(math.random(3,13))
		pawn:SetCustomAnim(customAnim)

		self:searchPawn(pawn, customAnim)
		self:evaluateResults()
	end
})

scans.active = inheritClass(Scan, {
	id = "Active",
	questName = "Pawn Active",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	actions = {
		function(self)
			prepareScanPawn{ SkillList = {"ScanWeapon"} }
			local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
			local isActive = math.random(0,1) == 1
			pawn:SetActive(isActive)

			self:searchPawn(pawn, isActive)
			self:evaluateResults()
		end
	}
})

scans.invisible = inheritClass(Scan, {
	id = "Invisible",
	questName = "Pawn Invisible",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local isInvisible = math.random(0,1) == 1
		pawn:SetInvisible(isInvisible)

		self:searchPawn(pawn, isInvisible)
		self:evaluateResults()
	end
})

scans.missionCritical = inheritClass(Scan, {
	id = "MissionCritical",
	questName = "Pawn Mission Critical",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local isMissionCritical = math.random(0,1) == 1
		pawn:SetMissionCritical(isMissionCritical)

		self:searchPawn(pawn, isMissionCritical)
		self:evaluateResults()
	end
})

scans.powered = inheritClass(Scan, {
	id = "Powered",
	questName = "Pawn Powered",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local powered = math.random(0,1) == 1
		pawn:SetPowered(powered)

		self:searchPawn(pawn, powered)
		self:evaluateResults()
	end
})

scans.acid = inheritClass(Scan, {
	id = "Acid",
	questName = "Pawn Acid",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local isAcid = math.random(0,1)
		pawn:SetAcid(true)
		pawn:SetAcid(false)
		pawn:SetAcid(isAcid == 1)

		self:searchPawn(pawn, isAcid, "byte")
		self:evaluateResults()
	end
})

scans.frozen = inheritClass(Scan, {
	id = "Frozen",
	questName = "Pawn Frozen",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local isFrozen = math.random(0,1)
		pawn:SetFrozen(true)
		pawn:SetFrozen(false)
		pawn:SetFrozen(isFrozen == 1)

		self:searchPawn(pawn, isFrozen, "byte")
		self:evaluateResults()
	end
})

scans.shield = inheritClass(Scan, {
	id = "Shield",
	questName = "Pawn Shield",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
	access = "RW",
	dataType = "bool",
	action = function(self)
		prepareScanPawn{}
		local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
		local isShielded = math.random(0,1)
		pawn:SetShield(true)
		pawn:SetShield(false)
		pawn:SetShield(isShielded == 1)

		self:searchPawn(pawn, isShielded, "byte")
		self:evaluateResults()
	end
})

scans.fire = inheritClass(Scan, {
	id = "Fire",
	questName = "Pawn Fire",
	questHelp = "Wait",
	prerequisiteScans = {"vital.size_pawn"},
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
			prepareScanPawn{}
			local p = randomCleanPoint()
			local pawn = PAWN_FACTORY:CreatePawn("ScanPawn")
			local isFire = math.random(0,1)
			Board:AddPawn(pawn, p)
			Board:SetFire(p, true)
			Board:SetFire(p, false)
			Board:SetFire(p, isFire == 1)

			self.data = {
				pawn = pawn,
				p = p,
				isFire = isFire
			}
		end,
		function(self)
			self:searchPawn(self.data.pawn, self.data.isFire, "byte")
			self:evaluateResults()
			self:cleanup()
		end
	}
})

return scans
