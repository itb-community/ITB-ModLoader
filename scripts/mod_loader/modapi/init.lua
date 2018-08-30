
local FtlDat = require("scripts/mod_loader/ftldat/ftldat")

modApi = {}
function modApi:init()
	self.logger = require("scripts/mod_loader/logger")

	Settings = self:loadSettings()
	ApplyModLoaderConfig(LoadModLoaderConfig())

	self.version = "2.3.0"
	LOG("MOD-API VERSION "..self.version)
	self.currentModSquads = {}
	self.currentModSquadText = {}

	if not self:fileExists("resources/resource.dat.bak") then
		LOG("Backing up resource.dat")

		local from = io.open("resources/resource.dat","rb")
		local to = io.open("resources/resource.dat.bak","w+b")

		to:write(from:read("*all"))

		from:close()
		to:close()
	else
		local file = io.open("resources/resource.dat","rb")
		local inp = file:read("*all")
		file:close()
		local instance = FtlDat.FtlDat:from_string(inp)

		if not instance.signature then
			LOG("resource.dat has been updated since last launch, re-acquiring backup")
			
			local to = io.open("resources/resource.dat.bak","w+b")
			to:write(inp)
			to:close()
		else
			LOG("Restoring resource.dat")

			local from = io.open("resources/resource.dat.bak","rb")
			local to = io.open("resources/resource.dat","wb")

			to:write(from:read("*all"))

			from:close()
			to:close()
		end
	end
	
	modApi.resource = FtlDat.FtlDat:from_file("resources/resource.dat")
	
	self.squadKeys = {
		"Archive_A",
		"Rust_A",
		"Pinnacle_A",
		"Detritus_A",
		"Archive_B",
		"Rust_B",
		"Pinnacle_B",
		"Detritus_B",
	}

	self.defaultMaps = {
		"acid0", "acid1", "acid2", "acid3", "acid4",
		"acid5", "acid6", "acid7", "acid8", "acid9",
		"acid10", "acid11", "acid12", "acid13", "acid14",
		"acid15",

		"any0", "any1", "any2", "any3", "any4",
		"any5", "any6", "any7", "any8", "any9",
		"any10", "any11", "any12", "any13", "any14",
		"any15", "any16", "any17", "any18", "any19",
		"any20", "any21", "any22", "any23", "any24",
		"any25", "any26", "any27", "any28", "any29",
		"any30", "any31", "any32", "any33", "any34",
		"any35", "any36", "any37", "any38", "any39",
		"any40", "any41", "any42", "any43", "any44",
		"any45", "any46", "any47", "any48", "any49",
		"any50",

		"barrels", "belt",

		"cave1", "cave2", "cave3", "cave4", "cave5",

		"crosscrack", "crosscrack2", "crosscrack3", "crosscrack4",
		"crosscrack5", "crosscrack6", "crosscrack7", "crosscrack8",
		"crosscrack9", "crosscrack10", "crosscrack11", "crosscrack12",
		"crosscrack13", "crosscrack14", "crosscrack15",

		"ctf0", "ctf1", "ctf2", "ctf3", "ctf4",
		"ctf5", "ctf6", "ctf7", "ctf8", "ctf9",
		"ctf10", "ctf11", "ctf12", "ctf13", "ctf14",

		"disposal", "disposal1", "disposal2", "disposal3", "disposal4",
		"disposal5", "disposal6", "disposal7", "disposal8", "disposal9",
		"disposal10", "disposal11", "disposal12", "disposal13", "disposal14",
		"disposal15", "disposal16", "disposal17", "disposal18", "disposal19",
		"disposal20",

		"final_island", "final_mission",

		"goo1", "goo2", "goo3", "goo4", "goo5", "goo6", "goo7",

		"grass0", "grass1", "grass2", "grass3", "grass4",
		"grass5", "grass6", "grass7", "grass8", "grass9",
		"grass10",

		"hightide1", "hightide2", "hightide3", "hightide4", "hightide5",
		"hightide6", "hightide7", "hightide8", "hightide9", "hightide10",
		"hightide11", "hightide12", "hightide13", "hightide14", "hightide15",
		"hightide16", "hightide17", "hightide18", "hightide19", "hightide20",

		"island_ending",

		"matt",

		"mix0", "mix1", "mix2", "mix3", "mix4", "mix5", "mix6",	"mix7", "mix8",
		"mix9", "mix10",

		"mountclear1",
		"null",

		"opendam1", "opendam2", "opendam3", "opendam4", "opendam5",
		"opendam6", "opendam7", "opendam8", "opendam9", "opendam10",
		"opendam11", "opendam12", "opendam13", "opendam14", "opendam15",
		"opendam16", "opendam17", "opendam18", "opendam19", "opendam20",

		"sand0", "sand1", "sand2", "sand3", "sand4",
		"sand5", "sand6", "sand7", "sand8", "sand9",
		"sand10", "sand11", "sand12", "sand13", "sand14",
		"sand15",

		"sand_hole1", "sand_hole2", "sand_hole3", "sand_hole4",

		"snow0", "snow1", "snow2", "snow3", "snow4",
		"snow5", "snow6", "snow7", "snow8", "snow9",
		"snow10", "snow11", "snow12", "snow13", "snow14",
		"snow15", "snow16", "snow17", "snow18", "snow19",
		"snow20", "snow21", "snow22", "snow23", "snow24",
		"snow25",

		"terraformer1", "terraformer2", "terraformer3", "terraformer4",
		"terraformer5", "terraformer6", "terraformer7", "terraformer8",

		"trailer",

		"train0", "train1", "train2", "train3", "train4",
		"train5", "train6", "train7", "train8", "train9",
		"train10", "train11", "train12", "train13", "train14",
		"train15", "train16", "train17", "train18", "train19",
		"train20",

		"tutorial",

		"volcano1", "volcano2", "volcano3", "volcano4",
		"volcano5", "volcano6", "volcano7", "volcano8",
		"volcano9", "volcano10"
	}
	self:deleteModdedMaps()

	self.compareScheduledHooks = function(a, b)
		return a.triggerTime < b.triggerTime
	end
	self.timer = sdl.timer()
	self.msDeltaTime = 0
	self.msLastElapsed = 0

	if MOD_API_DRAW_HOOK then
		sdlext.addFrameDrawnHook(function(screen)
			local t = modApi.timer:elapsed()
			if t > modApi.msLastElapsed then
				modApi.msDeltaTime = t - modApi.msLastElapsed
				modApi.msLastElapsed = t
			end

			modApi:updateScheduledHooks()
			modApi:evaluateConditionalHooks()
		end)
	end
end

-- Maintain sanity
-- Update as new API functions are added
function modApi:resetModContent()
	self.textOverrides = {}
	self.mod_squads = {
		{ "Rift Walkers", "PunchMech", "TankMech", "ArtiMech" },
		{ "Rusting Hulks", "JetMech", "RocketMech",  "PulseMech" },
		{ "Zenith Guard", "LaserMech", "ChargeMech", "ScienceMech" },
		{ "Blitzkrieg", "ElectricMech", "WallMech", "RockartMech" },
		{ "Steel Judoka", "JudoMech", "DStrikeMech", "GravMech" },
		{ "Flame Behemoths", "FlameMech", "IgniteMech", "TeleMech" },
		{ "Frozen Titans", "GuardMech", "MirrorMech", "IceMech" },
		{ "Hazardous Mechs", "LeapMech", "UnstableTank", "NanoMech" },
	}
	self.squad_text = {
		"Rift Walkers",
		"These were the very first Mechs to fight against the Vek. They are efficient and reliable.",
		
		"Rusting Hulks",
		"R.S.T. weather manipulators allow these Mechs to take advantage of smoke storms everywhere.",
		
		"Zenith Guard",
		"Detritus' Beam technology and Pinnacle's Shield technology create a powerful combination.",
		
		"Blitzkrieg",
		"R.S.T. engineers designed this Squad around the mass destruction capabilities of harnessed lightning.",
		
		"Steel Judoka",
		"These Mechs specialize in positional manipulation to turn the Vek against each other.",
		
		"Flame Behemoths",
		"Invincible to flames, these Mechs aim to burn any threat to ashes.",
		
		"Frozen Titans",
		"These Titans rely on the Cryo Launcher, a powerful weapon that takes an experienced Pilot to master.",
		
		"Hazardous Mechs",
		"These Mechs have spectacular damage output but rely on nanobots feeding off dead Vek to stay alive.",
	}
	self.squad_icon = {
		"img/units/player/mech_punch_ns.png",
		"img/units/player/mech_jet_ns.png",
		"img/units/player/mech_laser_ns.png",
		"img/units/player/mech_electric_ns.png",
		"img/units/player/mech_judo_ns.png",
		"img/units/player/mech_flame_ns.png",
		"img/units/player/mech_guard_ns.png",
		"img/units/player/mech_leap_ns.png",
	}
	self.resourceDat = sdl.resourceDat("resources/resource.dat")

	self.conditionalHooks = {}
	self.scheduledHooks = {}
	self.nextTurnHooks = {}
	self.missionUpdateHooks = {}
	self.missionStartHooks = {}
	self.missionNextPhaseCreatedHooks = {}
	self.preMissionAvailableHooks = {}
	self.postMissionAvailableHooks = {}
	self.preEnvironmentHooks = {}
	self.postEnvironmentHooks = {}
	self.preStartGameHooks = {}
	self.postStartGameHooks = {}
	self.preLoadGameHooks = {}
	self.postLoadGameHooks = {}
	self.saveGameHooks = {}
	self.currentModSquads = {}
	self.currentModSquadText = {}
	self.voiceEventHooks = {}
	self.preIslandSelectionHooks = {}
	self.postIslandSelectionHooks = {}
	self.missionEndHooks = {}
	self.vekSpawnAddedHooks = {}
	self.vekSpawnRemovedHooks = {}

	local name, tbl = debug.getupvalue(oldGetPopulationTexts,1)
	self.PopEvents = copy_table(tbl)
	self.onGetPopEvent = {}
end

function modApi:setCurrentMod(mod)
	self.currentMod = mod
	self.currentModSquads[mod] = {}
	self.currentModSquadText[mod] = {}
end
