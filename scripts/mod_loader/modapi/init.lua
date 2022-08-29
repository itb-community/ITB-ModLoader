
local parentDirectory = GetParentPath(...)

modApi = modApi or {}

modApi.events.onSettingsInitialized:subscribe(function(settings)
	Settings = settings
	LOG("Settings initialized!")
end)

function modApi:init()
	Settings = self:loadSettings()

	-- safe to start logging after this like is run
	-- if we start logging before we apply the config, we may not update the log file correctly
	ApplyModLoaderConfig(LoadModLoaderConfig())

	self.version = "2.7.2"
	LOG("GAME VERSION", self:getGameVersion())
	LOG("MOD-API VERSION", self.version)
	LOGD("Parent directory:", parentDirectory)

	if not self:fileExists("resources/resource.dat") then
		if self:fileExists("resources/resource.dat.bak") then
			LOGD("Resource.dat was missing, restoring from backup...")
			modApi:copyFileOS("resources/resource.dat.bak", "resources/resource.dat")
			LOGD("Done!")
			deco.reloadFonts()
		else
			-- Call error() inside of a sdl.drawHook - this way we get an actual message box that halts the game.
			-- Without it, error() produces a blank white rectangle with no text, and the game closes on its own
			-- shortly after.
			sdl.drawHook(function()
				-- This message gets printed twice in error.txt, but whatever.
				error(
						"\nThe mod loader could not find the game's resource.dat file, and backup was missing.\n\n" ..
								"Reinstalling the game or using the 'Verify integrity of game files' option on Steam should fix this."
				)
			end)
			-- Call error() here to halt loading of further files
			error("")
		end
	else
		if not self:fileExists("resources/resource.dat.bak") then
			LOGD("Backing up resource.dat...")
			modApi:copyFileOS("resources/resource.dat", "resources/resource.dat.bak")
			LOGD("Done!")
		else
			local instance = nil
			try(function()
				LOGD("Building FTLDat to check signature...")
				instance = FtlDat("resources/resource.dat")
				LOGD("Done!")
			end)
			:catch(function(err)
				if instance ~= nil then
					instance:destroy()
				end
				LOG("Failed to create FTLDat instance from resource.dat:", err)
			end)

			if instance and not instance.signature then
				LOGD("resource.dat has been updated since last launch, re-acquiring backup...")
				modApi:copyFileOS("resources/resource.dat", "resources/resource.dat.bak")
				LOGD("Done!")
			else
				LOGD("Restoring resource.dat...")
				modApi:copyFileOS("resources/resource.dat.bak", "resources/resource.dat")
				LOGD("Done!")
			end
		end
	end

	LOGD("Building FTLDat...")
	self.resource = FtlDat("resources/resource.dat")
	LOGD("Done!")

	self.squadKeys = {
		"Archive_A",
		"Rust_A",
		"Pinnacle_A",
		"Detritus_A",
		"Archive_B",
		"Rust_B",
		"Pinnacle_B",
		"Detritus_B",
		"Secret",
		"Squad_Bomber",
		"Squad_Spiders",
		"Squad_Mist",
		"Squad_Heat",
		"Squad_Cataclysm",
	}

	LOGD("Loading language...")
	modApi:loadLanguage(modApi:getLanguageIndex())
	LOGD("Done!")

	LOGD("Loading default maps...")
	self.defaultMaps = require(parentDirectory .. "default_maps")
	LOGD("Done!")

	LOGD("Deleting modded maps...")
	self:deleteModdedMaps()
	LOGD("Done!")

	self.compareScheduledHooks = function(a, b)
		return a.triggerTime < b.triggerTime
	end
	LOGD("Building timer...")
	self.timer = sdl.timer()
	LOGD("Done!")
	self.msDeltaTime = 0
	self.msLastElapsed = 0

	self.conditionalHooks = {}
	self.scheduledHooks = {}

	LOGD("Resetting hooks...")
	self:ResetHooks()
	LOGD("Done!")

	if MOD_API_DRAW_HOOK then
		modApi.events.onFrameDrawn:subscribe(function(screen)
			local t = modApi.timer:elapsed()
			if t > modApi.msLastElapsed then
				modApi.msDeltaTime = t - modApi.msLastElapsed
				modApi.msLastElapsed = t
			end

			modApi:updateScheduledHooks()
			modApi:evaluateConditionalHooks()
		end)
	end

	sdlext.executeAddModContent()
	self.initialized = true

	LOGD("modApi init success!")
end

function modApi:delayedInit()
	InitializeBoardPawn()

	modApi.delayedInit = nil
	LOGD("modApi delayed init success!")
end

-- Maintain sanity
-- Update as new API functions are added
function modApi:resetModContent()
	self.dictionary = {}

	self.mod_squads = {
		-- normal
		{ GetVanillaText("TipTitle_Archive_A"),  "PunchMech",    "TankMech",     "ArtiMech",    id = "Archive_A"  },
		{ GetVanillaText("TipTitle_Rust_A"),     "JetMech",      "RocketMech",   "PulseMech",   id = "Rust_A"     },
		{ GetVanillaText("TipTitle_Pinnacle_A"), "LaserMech",    "ChargeMech",   "ScienceMech", id = "Pinnacle_A" },
		{ GetVanillaText("TipTitle_Detritus_A"), "ElectricMech", "WallMech",     "RockartMech", id = "Detritus_A" },
		{ GetVanillaText("TipTitle_Archive_B"),  "JudoMech",     "DStrikeMech",  "GravMech",    id = "Archive_B"  },
		{ GetVanillaText("TipTitle_Rust_B"),     "FlameMech",    "IgniteMech",   "TeleMech",    id = "Rust_B"     },
		{ GetVanillaText("TipTitle_Pinnacle_B"), "GuardMech",    "MirrorMech",   "IceMech",     id = "Pinnacle_B" },
		{ GetVanillaText("TipTitle_Detritus_B"), "LeapMech",     "UnstableTank", "NanoMech",    id = "Detritus_B" },

		-- secret
		{ GetVanillaText("TipTitle_Secret"), "BeetleMech", "HornetMech", "ScarabMech", id = "Secret" },

		-- advanced
		{ GetVanillaText("TipTitle_Squad_Bomber"),    "PierceMech",    "BomblingMech",   "ExchangeMech", id = "Squad_Bomber"    },
		{ GetVanillaText("TipTitle_Squad_Spiders"),   "BulkMech",      "ScorpioMech",    "FourwayMech",  id = "Squad_Spiders"   },
		{ GetVanillaText("TipTitle_Squad_Mist"),      "NeedleMech",    "SmokeMech",      "SupermanMech", id = "Squad_Mist"      },
		{ GetVanillaText("TipTitle_Squad_Heat"),      "InfernoMech",   "DoubletankMech", "NapalmMech",   id = "Squad_Heat"      },
		{ GetVanillaText("TipTitle_Squad_Cataclysm"), "BottlecapMech", "TrimissileMech", "HydrantMech",  id = "Squad_Cataclysm" },
	}
	-- TODO: vanilla squad tables use ID in first spot instead of display name
	self.mod_squads_by_id = {}
	self.squad_text = {}
	for i, squad in ipairs(self.mod_squads) do
		self.mod_squads_by_id[squad.id] = squad
		self.squad_text[i*2 - 1] = squad[1]
		self.squad_text[i*2] = GetVanillaText("TipText_" .. squad.id)
	end

	self.squad_icon = {
		-- normal
		"img/units/player/mech_punch_ns.png",
		"img/units/player/mech_jet_ns.png",
		"img/units/player/mech_laser_ns.png",
		"img/units/player/mech_electric_ns.png",
		"img/units/player/mech_judo_ns.png",
		"img/units/player/mech_flame_ns.png",
		"img/units/player/mech_guard_ns.png",
		"img/units/player/mech_leap_ns.png",
		-- secret
		"img/units/player/vek_beetle_ns.png",
		-- advanced
		"img/advanced/units/player/brute_pierce_ns.png",
		"img/advanced/units/player/brute_bulk_ns.png",
		"img/advanced/units/player/brute_needle_ns.png",
		"img/advanced/units/player/prime_firefighter_ns.png",
		"img/advanced/units/player/prime_bottlecap_ns.png",
	}
	self.resourceDat = sdl.resourceDat("resources/resource.dat")

	self.conditionalHooks = {}
	self.scheduledHooks = {}
	self:ResetHooks()

	modApi.events.onModContentReset:dispatch()

	self:conditionalHook(
		function()
			return Game ~= nil and modApi.delayedInit ~= nil
		end,
		function()
			modApi:delayedInit()
		end
	)
end

function modApi:setCurrentMod(mod)
	self.currentMod = mod
end

function modApi:getCurrentModcontentPath()
	if modApi.profileConfig and modApi:isProfilePath() then
		return modApi:getCurrentProfilePath().."modcontent.lua"
	else
		return "modcontent.lua"
	end
end

function modApi:getGameVersion()
	if modApi.gameVersion then
		return modApi.gameVersion
	end

	local logPath = GetSavedataLocation() .. "log.txt"
	if modApi:fileExists(logPath) then
		local file = assert(io.open(logPath, "r"), "Failed to open file: " .. logPath)
		local content = file:read(200)
		file:close()

		local version = string.match(content, "Into the Breach: (%S+)")
		if version then
			modApi.gameVersion = version
			return modApi.gameVersion
		end
	end

	LOG("WARNING: Unable to get game version!")
end

modApi.events.onSettingsChanged:subscribe(function(old, neu)
	if old.language ~= neu.language then
		if GAME then
			mod_loader:loadModContent(GAME.modOptions, GAME.modLoadOrder)
		else
			mod_loader:loadModContent(mod_loader.mod_options, mod_loader:getModConfig())
		end
	end
end)
