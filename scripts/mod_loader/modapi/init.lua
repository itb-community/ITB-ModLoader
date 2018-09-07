
local FtlDat = require("scripts/mod_loader/ftldat/ftldat")

modApi = {}
function modApi:init()
	self.logger = require("scripts/mod_loader/logger")

	Settings = self:loadSettings()
	ApplyModLoaderConfig(LoadModLoaderConfig())

	self.version = "2.3.0"
	LOG("MOD-API VERSION "..self.version)
	self.texts = {}
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
	
	self.resource = FtlDat.FtlDat:from_file("resources/resource.dat")

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

	self:setupVanillaTexts()
	self:setupModLoaderTexts()

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

	-- Execute deferred statements

	AddDifficultyLevel(
		"DIFF_VERY_HARD",
		#DifficultyLevels -- adds as a new highest difficulty
	)
	AddDifficultyLevel(
		"DIFF_IMPOSSIBLE",
		#DifficultyLevels -- adds as a new highest difficulty
	)

	sdlext.executeAddModContent()
end

function modApi:getText(id)
	assert(type(id) == "string", "Expected string, got: "..type(id))
	local result = self.texts[id]

	if not result then
		LOG("Attempt to reference non-existing text id '"..id.."', "..debug.traceback())
	end
	
	return result
end

function modApi:setupVanillaTexts()
	for i, v in ipairs(self.squadKeys) do
		self.texts[v.."_Name"] = Global_Texts["TipTitle_"..v]
		self.texts[v.."_Description"] = Global_Texts["TipText_"..v]
	end

	self.texts["Difficulty_Easy_Name"]          = Global_Texts.Toggle_Easy
	self.texts["Difficulty_Easy_Title"]         = Global_Texts.TipTitle_HangarEasy
	self.texts["Difficulty_Easy_Description"]   = Global_Texts.TipText_HangarEasy
	self.texts["Difficulty_Normal_Name"]        = Global_Texts.Toggle_Normal
	self.texts["Difficulty_Normal_Title"]       = Global_Texts.TipTitle_HangarNormal
	self.texts["Difficulty_Normal_Description"] = Global_Texts.TipText_HangarNormal
	self.texts["Difficulty_Hard_Name"]          = Global_Texts.Toggle_Hard
	self.texts["Difficulty_Hard_Title"]         = Global_Texts.TipTitle_HangarHard
	self.texts["Difficulty_Hard_Description"]   = Global_Texts.TipText_HangarHard
end

function modApi:setupModLoaderTexts()
	self.texts["Button_ModContent"] = "Mod Content"
	self.texts["FrameTitle_ModContent"] = "Mod Content"

	self.texts["Button_ModConfig"] = "Configure Mods"
	self.texts["ButtonTooltip_ModConfig"] = "Turn on and off individual mods, and configure any settings they might have."
	self.texts["FrameTitle_ModConfig"] = "Mod Configuration"

	self.texts["Button_SquadSelect"] = "Edit Squads"
	self.texts["ButtonTooltip_SquadSelect"] = "Select which squads will be available to pick."
	self.texts["FrameTitle_SquadSelect"] = "Squad Selection"
	self.texts["SquadSelect_Total"] = "Total selected"

	self.texts["Button_PilotArrange"] = "Arrange Pilots"
	self.texts["ButtonTooltip_PilotArrange"] = "Select which pilots will be available to pick."
	self.texts["ButtonTooltipOff_PilotArrange"] = "Pilots can only be arranged before the New Game button is pressed.\n\nRestart the game to be able to arrange pilots."
	self.texts["FrameTitle_PilotArrange"] = "Arrange Pilots"

	self.texts["Button_ModLoaderConfig"] = "Configure Mod Loader"
	self.texts["ButtonTooltip_ModLoaderConfig"] = "Configure some features of the mod loader."
	self.texts["FrameTitle_ModLoaderConfig"] = "Mod Loader Configuration"

	self.texts["ModLoaderConfig_LogLevel_Text"] = "Logging level"
	self.texts["ModLoaderConfig_LogLevel_Tooltip"] = "Controls where the game's logging messages are printed."
	self.texts["ModLoaderConfig_LogLevel_DD0"] = "None"
	self.texts["ModLoaderConfig_LogLevel_DD1"] = "Only console"
	self.texts["ModLoaderConfig_LogLevel_DD2"] = "File and console"

	self.texts["ModLoaderConfig_Caller_Text"] = "Print Caller Information"
	self.texts["ModLoaderConfig_Caller_Tooltip"] = "Include timestamp and stacktrace in LOG messages."

	self.texts["ModLoaderConfig_FloatyTooltips_Text"] = "Attach Tooltips To Mouse Cursor"
	self.texts["ModLoaderConfig_FloatyTooltips_Tooltip_On"] = "Tooltips follow the mouse cursor around."
	self.texts["ModLoaderConfig_FloatyTooltips_Tooltip_Off"] = "Tooltips show to the side of the UI element that spawned them, similar to the game's own tooltips."

	self.texts["ModLoaderConfig_ProfileConfig_Text"] = "Profile-Specific Configuration"
	self.texts["ModLoaderConfig_ProfileConfig_Tooltip"] = "Configuration for the mod loader and individual mods will be remembered per profile, instead of globally.\n\nNote: with this option enabled, switching profiles will require you to restart the game to apply the different mod configurations."

	self.texts["ModLoaderConfig_ScriptError_Text"] = "Show Script Error Popup"
	self.texts["ModLoaderConfig_ScriptError_Tooltip"] = "Show an error popup at startup if a mod fails to mount, init, or load."

	self.texts["ModLoaderConfig_OldVersion_Text"] = "Show Mod Loader Outdated Popup"
	self.texts["ModLoaderConfig_OldVersion_Tooltip"] = "Show a popup if the mod loader is out-of-date for installed mods."

	self.texts["ModLoaderConfig_ResourceError_Text"] = "Show Resource Error Popup"
	self.texts["ModLoaderConfig_ResourceError_Tooltip"] = "Show an error popup at startup if the mod loader fails to load the game's resources."

	self.texts["ModLoaderConfig_RestartReminder_Text"] = "Show Restart Reminder Popup"
	self.texts["ModLoaderConfig_RestartReminder_Tooltip"] = "Show a popup reminding to restart the game when enabling mods."

	self.texts["Button_Ok"] = "OK"
	self.texts["Button_Yes"] = "YES"
	self.texts["Button_No"] = "NO"
	self.texts["Button_DisablePopup"] = "GOT IT, DON'T TELL ME AGAIN"
	self.texts["ButtonTooltip_DisablePopup"] = "This dialog will not be shown anymore. You can re-enable it in Configure Mod Loader."

	self.texts["FrameTitle_ScriptError"] = "Script Error"
	self.texts["FrameText_ScriptError_Mount"] = "Unable to mount mod at [%s]:\n%s"

	self.texts["FrameTitle_RestartRequired"] = "Restart Required"
	self.texts["FrameText_RestartRequired"] = "You have enabled one or more mods. In order to apply them, game restart is required."

	self.texts["FrameTitle_OldVersion"] = "Mod Loader Outdated"
	self.texts["FrameText_OldVersion"] = "The following mods could not be loaded, because they require a newer version of the mod loader:\n\n%s\nYour installed version: %s"
	self.texts["OldVersion_ListEntry"] = "- [%s] requires at least version %s."

	self.texts["FrameTitle_ResourceError"] = "Resource Error"
	self.texts["FrameText_ResourceError"] = 
					"The mod loader failed to load game resources. "..
					"This will cause some elements of modded UI to be invisible or incorrectly positioned. "..
					"This happens sometimes, but so far the cause is not known.\n\n"..
					"Restarting the game should fix this."

	self.texts["VersionString"] = "Mod loader version: "

	self.texts["Custom_Difficulty_Note"] = "Note: this is a modded difficulty level. It won't change anything without mods providing content for this difficulty."

	self.texts["Difficulty_VeryHard_Name"] = "Very Hard"
	self.texts["Difficulty_VeryHard_Title"] = "Very Hard Mode"
	self.texts["Difficulty_VeryHard_Description"] = "Intended for veteran Commanders looking for a challenge."

	self.texts["Difficulty_Impossible_Name"] = "Impossible"
	self.texts["Difficulty_Impossible_Title"] = "Impossible Mode"
	self.texts["Difficulty_Impossible_Description"] = "A punishing difficulty allowing no mistakes."
end

-- Maintain sanity
-- Update as new API functions are added
function modApi:resetModContent()
	self.textOverrides = {}
	self.mod_squads = {
		{ self:getText("Archive_A_Name"), "PunchMech", "TankMech", "ArtiMech" },
		{ self:getText("Rust_A_Name"), "JetMech", "RocketMech",  "PulseMech" },
		{ self:getText("Pinnacle_A_Name"), "LaserMech", "ChargeMech", "ScienceMech" },
		{ self:getText("Detritus_A_Name"), "ElectricMech", "WallMech", "RockartMech" },
		{ self:getText("Archive_B_Name"), "JudoMech", "DStrikeMech", "GravMech" },
		{ self:getText("Rust_B_Name"), "FlameMech", "IgniteMech", "TeleMech" },
		{ self:getText("Pinnacle_B_Name"), "GuardMech", "MirrorMech", "IceMech" },
		{ self:getText("Detritus_B_Name"), "LeapMech", "UnstableTank", "NanoMech" },
	}
	self.squad_text = {
		self:getText("Archive_A_Name"),
		self:getText("Archive_A_Description"),
		
		self:getText("Rust_A_Name"),
		self:getText("Rust_A_Description"),
		
		self:getText("Pinnacle_A_Name"),
		self:getText("Pinnacle_A_Description"),
		
		self:getText("Detritus_A_Name"),
		self:getText("Detritus_A_Description"),
		
		self:getText("Archive_B_Name"),
		self:getText("Archive_B_Description"),
		
		self:getText("Rust_B_Name"),
		self:getText("Rust_B_Description"),
		
		self:getText("Pinnacle_B_Name"),
		self:getText("Pinnacle_B_Description"),
		
		self:getText("Detritus_B_Name"),
		self:getText("Detritus_B_Description"),
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
	self.modsLoadedHooks = {}
	self.testMechEnteredHooks = {}
	self.testMechExitedHooks = {}

	local name, tbl = debug.getupvalue(oldGetPopulationTexts,1)
	self.PopEvents = copy_table(tbl)
	self.onGetPopEvent = {}
end

function modApi:setCurrentMod(mod)
	self.currentMod = mod
	self.currentModSquads[mod] = {}
	self.currentModSquadText[mod] = {}
end
