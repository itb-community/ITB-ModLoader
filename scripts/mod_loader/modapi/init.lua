
local FtlDat = require("scripts/mod_loader/ftldat/ftldat")
local parentDirectory = GetParentPath(...)

modApi = {}
function modApi:init()
	Settings = self:loadSettings()
	ApplyModLoaderConfig(LoadModLoaderConfig())

	self.version = "2.5.1"
	LOG("MOD-API VERSION "..self.version)

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

	modApi:loadLanguage(modApi:getLanguageIndex())

	self.defaultMaps = require(parentDirectory .. "default_maps")
	self:deleteModdedMaps()

	self.compareScheduledHooks = function(a, b)
		return a.triggerTime < b.triggerTime
	end
	self.timer = sdl.timer()
	self.msDeltaTime = 0
	self.msLastElapsed = 0

	self.conditionalHooks = {}
	self.scheduledHooks = {}
	self:ResetHooks()

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

function modApi:delayedInit()
	InitializeBoardPawn()

	modApi.delayedInit = nil
end

-- Maintain sanity
-- Update as new API functions are added
function modApi:resetModContent()
	self.dictionary = {}

	self.mod_squads = {
		{ GetVanillaText("TipTitle_Archive_A"), "PunchMech", "TankMech", "ArtiMech" },
		{ GetVanillaText("TipTitle_Rust_A"), "JetMech", "RocketMech",  "PulseMech" },
		{ GetVanillaText("TipTitle_Pinnacle_A"), "LaserMech", "ChargeMech", "ScienceMech" },
		{ GetVanillaText("TipTitle_Detritus_A"), "ElectricMech", "WallMech", "RockartMech" },
		{ GetVanillaText("TipTitle_Archive_B"), "JudoMech", "DStrikeMech", "GravMech" },
		{ GetVanillaText("TipTitle_Rust_B"), "FlameMech", "IgniteMech", "TeleMech" },
		{ GetVanillaText("TipTitle_Pinnacle_B"), "GuardMech", "MirrorMech", "IceMech" },
		{ GetVanillaText("TipTitle_Detritus_B"), "LeapMech", "UnstableTank", "NanoMech" },
	}
	self.squad_text = {
		GetVanillaText("TipTitle_Archive_A"),
		GetVanillaText("TipText_Archive_A"),

		GetVanillaText("TipTitle_Rust_A"),
		GetVanillaText("TipText_Rust_A"),

		GetVanillaText("TipTitle_Pinnacle_A"),
		GetVanillaText("TipText_Pinnacle_A"),

		GetVanillaText("TipTitle_Detritus_A"),
		GetVanillaText("TipText_Detritus_A"),

		GetVanillaText("TipTitle_Archive_B"),
		GetVanillaText("TipText_Archive_B"),

		GetVanillaText("TipTitle_Rust_B"),
		GetVanillaText("TipText_Rust_B"),

		GetVanillaText("TipTitle_Pinnacle_B"),
		GetVanillaText("TipText_Pinnacle_B"),

		GetVanillaText("TipTitle_Detritus_B"),
		GetVanillaText("TipText_Detritus_B"),
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
	self:ResetHooks()

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
	if modApi.profileConfig then
		return modApi:getCurrentProfilePath().."modcontent.lua"
	else
		return "modcontent.lua"
	end
end

function modApi:getGameVersion()
	if type(IsLocalizedText) == "function" then
		return "1.2.20"
	elseif type(IsGamepad) == "function" then
		return "1.1.22"
	end

	return "1.0.22"
end

sdlext.addSettingsChangedHook(function(old, neu)
	if old.language ~= neu.language then
		if GAME then
			mod_loader:loadModContent(GAME.modOptions, GAME.modLoadOrder)
		else
			mod_loader:loadModContent(mod_loader.mod_options, mod_loader:getModConfig())
		end
	end
end)
