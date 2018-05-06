-- This class serves mostly as a self-documenting guide to common mod operations,
-- as well as an indirection layer to maintain a kind of sanity for compatability purposes

local FtlDat = require("scripts/mod_loader/ftldat/ftldat")

modApi = {}

local prev_path = package.path

function loadModLoaderConfig()
	local data = {
		logLevel = 1, -- log to console by default
		printCallerInfo = true,
		showErrorFrame = true
	}

	sdlext.config("modcontent.lua", function(obj)
		if not obj.modLoaderConfig then return end

		data = obj.modLoaderConfig
	end)

	return data
end

function applyModLoaderConfig(config)
	modApi.logger.logLevel = config.logLevel
	modApi.logger.printCallerInfo = config.printCallerInfo
	modApi.showErrorFrame = config.showErrorFrame
end

function modApi:init()
	self.logger = require("scripts/mod_loader/logger")
	applyModLoaderConfig(loadModLoaderConfig())
	if self.logger.logLevel == self.logger.LOG_LEVEL_FILE then
		self.logger.logToFile("log.txt")
	end

	self.version = "2.1.5"
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

	modApi.timerDrawHook = sdl.drawHook(function(screen)
		local t = modApi.timer:elapsed()
		if t > modApi.msLastElapsed then
			modApi.msDeltaTime = t - modApi.msLastElapsed
			modApi.msLastElapsed = t
		end

		modApi:updateScheduledHooks()
		modApi:evaluateConditionalHooks()
	end)

	Settings = modApi:loadSettings()
end

--Maintain sanity
--Update as new API functions are added
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
	self.missionEndHooks = {
		--Pilot Message
		function(mission,ret)
			ret:AddScript([[
			local ret = SkillEffect()
			local enemy_count = Board:GetEnemyCount()
			if enemy_count == 0 then
				ret:AddVoice("MissionEnd_Dead", -1)
			elseif self.RetreatEndingMessage then
				ret:AddVoice("MissionEnd_Retreat", -1)
			end
			Board:AddEffect(ret)]])
		end,
		
		--Population Event
		function(mission,ret)
			ret:AddScript([[
			local ret = SkillEffect()
			local enemy_count = Board:GetEnemyCount()
			
			if CurrentMission:GetDamage() == 0 then
				ret:AddScript("Board:StartPopEvent(\"Closing_Perfect\")")
			elseif CurrentMission:GetDamage() > 4 then
				ret:AddScript("Board:StartPopEvent(\"Closing_Bad\")")
			elseif enemy_count > 0 then
				ret:AddScript("Board:StartPopEvent(\"Closing\")")
			else
				ret:AddScript("Board:StartPopEvent(\"Closing_Dead\")")
			end
			Board:AddEffect(ret)]])
		end,
		
		--Enemy retreat
		function(mission,ret)
			ret:AddScript([[
			local ret = SkillEffect()
			local effect = SpaceDamage()
			effect.bEvacuate = true
			effect.fDelay = 0.5
			
			local board_size = Board:GetSize()
			for i = 0, board_size.x - 1 do
				for j = 0, board_size.y - 1  do
					if Board:IsPawnTeam(Point(i,j),TEAM_ENEMY)  then
						effect.loc = Point(i,j)
						ret:AddDamage(effect)
						CurrentMission.delayToAdd = CurrentMission.delayToAdd - 0.5
					end
				end
			end
			Board:AddEffect(ret)]])
		end,
		
		--End Delay
		function(mission,ret)
			ret:AddScript([[
			local ret = SkillEffect()
			--ret:AddDelay(CurrentMission:GetEndDelay())
			Board:AddEffect(ret)]])
		end,
	}
	self.iMePilotMessage = 1
	self.iMePopEvent = 2
	self.iMeRetreat = 3
	self.iMeDelay = 4
	
	local name, tbl = debug.getupvalue(oldGetPopulationTexts,1)
	self.PopEvents = copy_table(tbl)
	self.onGetPopEvent = {}
end

function modApi:setCurrentMod(mod)
	self.currentMod = mod
	self.currentModSquads[mod] = {}
	self.currentModSquadText[mod] = {}
end

-- //////////////////////////////////////////////////////////////////////////////
-- API

function modApi:deltaTime()
	return self.msDeltaTime
end

function modApi:elapsedTime()
	-- return cached time, so that mods don't get different
	-- timings depending on when in the frame they called
	-- this function.
	return self.msLastElapsed
end

function list_indexof(list, value)
	for k, v in ipairs(list) do
		if value == v then
			return k
		end
	end
	return nil
end

--[[
	Returns true if this string starts with the prefix string
--]]
function modApi:stringStartsWith(str, prefix)
	return string.sub(str,1,string.len(prefix)) == prefix
end

--[[
	Returns true if this string ends with the suffix string
--]]
function modApi:stringEndsWith(str, suffix)
	return suffix == "" or string.sub(str,-string.len(suffix)) == suffix
end

--[[
	Trims leading and trailing whitespace from the string.

	trim11 from: http://lua-users.org/wiki/StringTrim
--]]
function modApi:trimString(str)
	local n = str:find"%S"
	return n and str:match(".*%S", n) or ""
end

function modApi:splitString(test,sep)
	if sep == nil then
		sep = "%s"
	end

	local t = {}
	for str in string.gmatch(test, "([^"..sep.."]+)") do
		table.insert(t, str)
	end

	return t
end

function modApi:isVersion(version,comparedTo)
	assert(type(version) == "string")
	if not comparedTo then
		comparedTo = self.version
	end
	assert(type(comparedTo) == "string")
	
	local v1 = self:splitString(version,"%D")
	local v2 = self:splitString(comparedTo,"%D")
	
	for i = 1, math.min(#v1,#v2) do
		local n1 = tonumber(v1[i])
		local n2 = tonumber(v2[i])
		if n1 > n2 then
			return false
		elseif n1 < n2 then
			return true
		end
	end
	
	return #v1 <= #v2
end

function modApi:addGenerationOption(id, name, tip, data)
	assert(type(id) == "string" or type(id) == "number")
	assert(type(name) == "string")
	tip = tip or nil
	assert(type(tip) == "string")
	data = data or {}
	assert(type(data) == "table") -- Misc stuff
	for i, option in ipairs(mod_loader.mod_options[self.currentMod]) do
		assert(option.id ~= id)
	end
	
	local option = {
		id = id,
		name = name,
		tip = tip,
		check = true,
		enabled = true,
		data = data
	}
	
	if data.values then
		assert(#data.values > 0)
		option.check = false
		option.enabled = nil
		option.values = data.values
		option.value = data.value or data.values[1]
		option.strings = data.strings
	elseif data.enabled == false then
		option.enabled = false
	end
	
	table.insert(mod_loader.mod_options[self.currentMod].options, option)
end

function modApi:addSquadTrue(squad, name, desc, icon)
	return self:addSquad(squad, name, desc, icon)
end

function modApi:addSquad(squad, name, desc, icon)
	assert(type(squad) == "table")
	assert(#squad == 4)
	assert(type(name) == "string")
	assert(type(desc) == "string")

	table.insert(self.mod_squads, squad)
	table.insert(self.squad_text, name)
	table.insert(self.squad_text, desc)
	table.insert(self.squad_icon, icon or "resources/mods/squads/unknown.png")
end

function modApi:overwriteTextTrue(id,str)
	return self:overwriteText(id,str)
end

function modApi:overwriteText(id,str)
	assert(type(id) == "string")
	assert(type(str) == "string")
	self.textOverrides[id] = str
end

function modApi:addWeapon_Texts(tbl)
	assert(type(tbl) == "table")
	for k,v in pairs(tbl) do
		Weapon_Texts[k] = v
	end
end

--[[
	Loads the specified file, loading any global variable definitions
	into the specified table instead of the global namespace (_G).
	The file can still access variables defined in _G, but not write to
	them by default (unless specifically doing _G.foo = bar).

	Last arg can be omitted, defaulting to an empty table.
--]]
function modApi:loadIntoEnv(scriptPath, envTable)
	envTable = envTable or {}
	assert(type(envTable) == "table", "Environment must be a table")
	assert(type(scriptPath) == "string", "Path is not a string")

	setmetatable(envTable, { __index = _G })
	assert(pcall(setfenv(
		assert(loadfile(scriptPath)),
		envTable
	)))
	setmetatable(envTable, nil)

	return envTable
end

--[[
	Reloads the settings file to have access to selected settings
	from in-game lua scripts.
--]]
function modApi:loadSettings()
	local path = os.getKnownFolder(5).."/My Games/Into The Breach/settings.lua"
	if self:fileExists(path) then
		return self:loadIntoEnv(path).Settings
	end

	return nil
end

function modApi:writeProfileData(id, obj)
	local settings = self:loadSettings()

	sdlext.config(
		"profile_"..settings.last_profile.."/modcontent.lua",
		function(readObj)
			readObj[id] = obj
		end
	)
end

function modApi:readProfileData(id)
	local settings = self:loadSettings()

	local result = nil

	sdlext.config(
		"profile_"..settings.last_profile.."/modcontent.lua",
		function(readObj)
			result = readObj[id]
		end
	)

	return result
end

-- //////////////////////////////////////////////////////////////////////////////
-- Hooks

function modApi:addPreMissionAvailableHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preMissionAvailableHooks,fn)
end

function modApi:addPostMissionAvailableHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postMissionAvailableHooks,fn)
end

function modApi:addMissionAvailableHook(fn)
	self:addPostMissionAvailableHook(fn)
end

function modApi:addPreEnvironmentHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preEnvironmentHooks,fn)
end

function modApi:addPostEnvironmentHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postEnvironmentHooks,fn)
end

function modApi:addNextTurnHook(fn)
	assert(type(fn) == "function")
	table.insert(self.nextTurnHooks,fn)
end

function modApi:addVoiceEventHook(fn)
	assert(type(fn) == "function")
	table.insert(self.voiceEventHooks,fn)
end

function modApi:addMissionUpdateHook(fn)
	assert(type(fn) == "function")
	table.insert(self.missionUpdateHooks,fn)
end

function modApi:addMissionStartHook(fn)
	assert(type(fn) == "function")
	table.insert(self.missionStartHooks,fn)
end

function modApi:addMissionEndHook(fn, i)
	assert(type(fn) == "function")
	if i ~= nil then
		assert(type(i) == "number")
		assert(i > 0)
		assert(math.floor(i) == i)
		table.insert(self.missionEndHooks,i,fn)
		if i <= self.iMePilotMessage then
			self.iMePilotMessage = self.iMePilotMessage + 1
		end
		if i <= self.iMePopEvent then
			self.iMePopEvent = self.iMePopEvent + 1
		end
		if i <= self.iMeRetreat then
			self.iMeRetreat = self.iMeRetreat + 1
		end
		if i <= self.iMeDelay then
			self.iMeDelay = self.iMeDelay + 1
		end
	else
		table.insert(self.missionEndHooks,fn)
	end
end

function modApi:addMissionNextPhaseCreatedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.missionNextPhaseCreatedHooks,fn)
end

function modApi:addPreStartGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preStartGameHooks,fn)
end

function modApi:addPostStartGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postStartGameHooks,fn)
end

function modApi:addPreLoadGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preLoadGameHooks,fn)
end

function modApi:addPostLoadGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postLoadGameHooks,fn)
end

function modApi:addSaveGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.saveGameHooks,fn)
end

--[[
	Executes the function on the game's next update step. Only works during missions.
	
	Calling this while during game loop (either in a function called from missionUpdate,
	or as a result of previous runLater) will correctly schedule the function to be
	invoked during the next update step (not the current one).
--]]
function modApi:runLater(fn)
	assert(type(f) == "function")

	if not self.runLaterQueue then
		self.runLaterQueue = {}
	end

	table.insert(self.runLaterQueue, f)
end

function modApi:processRunLaterQueue(mission)
	if self.runLaterQueue then
		local q = self.runLaterQueue
		local n = #q
		for i = 1, n do
			q[i](mission)
			q[i] = nil
		end

		-- compact the table, if processed hooks also scheduled
		-- their own runLater functions (but we will process those
		-- on the next update step)
		local i = n + 1
		local j = 0
		while q[i] do
			j = j + 1
			q[j] = q[i]
			q[i] = nil
			i = i + 1
		end
	end
end

--[[
	Registers a conditional hook which will be
	executed once the condition function associated
	with it returns true.
--]]
function modApi:conditionalHook(conditionFn, fn)
	assert(type(conditionFn) == "function")
	assert(type(fn) == "function")

	table.insert(self.conditionalHooks, {
		condition = conditionFn,
		hook = fn
	})
end

function modApi:evaluateConditionalHooks()
	for i, tbl in ipairs(self.conditionalHooks) do
		if tbl.condition() then
			table.remove(self.conditionalHooks, i)
			tbl.hook()
		end
	end
end

--[[
	Schedules an argumentless function to be executed
	in msTime milliseconds.
--]]
function modApi:scheduleHook(msTime, fn)
	assert(type(msTime) == "number")
	assert(type(fn) == "function")

	table.insert(self.scheduledHooks, {
		triggerTime = self:elapsedTime() + msTime,
		hook = fn
	})

	-- sort the table according to triggerTime field, so hooks
	-- that are scheduled sooner are executed first, even if
	-- both hooks are processed during the same update step.
	table.sort(self.scheduledHooks, self.compareScheduledHooks)
end

function modApi:updateScheduledHooks()
	local t = self:elapsedTime()

	for i, tbl in ipairs(self.scheduledHooks) do
		if tbl.triggerTime <= t then
			table.remove(self.scheduledHooks, i)
			tbl.hook()
		end
	end
end

function modApi:addPopEvent(event, msg)
	assert(type(event) == "string")
	assert(type(msg) == "string")
	if not self.PopEvents[event] then
		self.PopEvents[event] = {}
	end
	
	table.insert(self.PopEvents[event],msg)
end

function modApi:setPopEventOdds(event, odds)
	assert(type(event) == "string")
	assert(self.PopEvents[event])
	assert(odds == nil or type(odds) == "number")
	
	self.PopEvents[event].Odds = odds
end

function modApi:addOnPopEvent(fn)
	assert(type(fn) == "function")
	table.insert(self.onGetPopEvent,fn)
end

-- //////////////////////////////////////////////////////////////////////////////
-- Map handling

function modApi:fileExists(name)
	assert(name ~= nil, "Filename is nil")
	assert(type(name) == "string", "Filename is not a string")

	local f = io.open(name, "rb")

	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

function modApi:copyFile(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	local input = io.open(src, "r")
	assert(input, "Unable to open " .. src)
	local content = input:read("*a")
	input:close()

	local output = io.open(dst, "w")
	assert(output, "Unable to open " .. dst)
	output:write(content)
	output:close()
end

function modApi:pruneExtension(filename)
	-- gsub() returns multiple values, store the first
	-- value in a variable so that we correctly ignore
	-- the retvalues that come after it.
	local r = string.gsub(filename, "\.[^\.]*$", "")
	return r
end

--[[
	Returns a list of names of all *.map files in maps/ directory,
	without the .map extension
--]]
function modApi:getMapsList()
	local list = {}

	for i, file in pairs(os.listfiles("maps")) do
		if modApi:stringEndsWith(file, ".map") then
			table.insert(list, self:pruneExtension(file))
		end
	end

	return list
end

function modApi:deleteModdedMaps()
	for i, mapname in ipairs(self:getMapsList()) do
		if not list_contains(self.defaultMaps, mapname) then
			os.remove("maps/"..mapname..".map")
		end
	end
end

function modApi:addMap(path)
	local idx = (string.find(path, "/[^/]*$") or 0) + 1
	local mapfile = string.sub(path, idx)
	local mapname = self:pruneExtension(mapfile)

	if list_contains(self.defaultMaps, mapname) then
		LOG(string.format("Unable to add map '%s', because it would overwrite a vanilla map.", path))
	else
		self:copyFile(path, "maps/"..mapfile)
	end
end

-- //////////////////////////////////////////////////////////////////////////////
-- Resource.dat handling

function modApi:appendAsset(resource, filePath)
	assert(type(resource) == "string")
	local f = io.open(filePath,"rb")
	assert(f,filePath)
	
	for i, file in ipairs(self.resource._files) do
		if file._meta._filename == resource then
			file._meta.body = f:read("*all")
			file._meta._fileSize = file._meta.body:len()
			f:close()

			return
		end
	end
	
	self.resource._numFiles = self.resource._numFiles + 1
	
	local file = FtlDat.File(self.resource._io,self.resource,self.resource.m_root)
	file._meta = FtlDat.Meta(file._io, file, file.m_root)
	
	file._meta._filenameSize = resource:len()
	file._meta._filename = resource
	file._meta.body = f:read("*all")
	file._meta._fileSize = file._meta.body:len()
	f:close()
    
    table.insert(self.resource._files,file)
end

function modApi:appendDat(filePath)
	local instance = FtlDat.FtlDat:from_file(filePath)
	
	for i, file in ipairs(instance._files) do
		local found = false
		for j, og in ipairs(self.resource) do
			if file._meta._filename == og._meta._filename then
				og._meta.body = file._meta.body
				og._meta._fileSize = file._meta._fileSize
				found = true
			
				break
			end
		end
		
		if not found then
			table.insert(self.resource._files,file)
			self.resource._numFiles = self.resource._numFiles + 1
		end
	end
end

function modApi:fileDirectoryToDat(path)
	assert(type(path) == "string")
	local len = path:len()
	assert(len > 0)
	
	if path:sub(len) ~= [[/]] and path:sub(len) ~= [[\]] then
		path = path.."/"
	end
	
	local ftldat = FtlDat.FtlDat()
	ftldat._files = {}
	ftldat._numFiles = 0
	
	local function addDir(directory)
		for i, dir in pairs(os.listdirs(path..directory)) do
			addDir(directory..dir.."/")
		end
		for i, dirfile in pairs(os.listfiles(path..directory)) do
			
			local f = io.open(path..directory..dirfile,"rb")
			
			ftldat._numFiles = ftldat._numFiles + 1
	
			local file = FtlDat.File()
			file._meta = FtlDat.Meta()
	
			file._meta._filename = directory..dirfile
			file._meta._filenameSize = file._meta._filename:len()
			file._meta.body = f:read("*all")
			file._meta._fileSize = file._meta.body:len()
			
			f:close()
			
			table.insert(ftldat._files,file)
		end
	end
	
	addDir("")
	
	local f = io.open(path.."resource.dat","wb+")
	local output = ftldat:_write()
	f:write(output)
	f:close()
end

function modApi:getSignature()
	return "ModLoaderSignature"
end

function modApi:finalize()
	local f = io.open("resources/resource.dat","wb")
	
	if not self.resource.signature then
		self.resource.signature = true
		self.resource._numFiles = self.resource._numFiles + 1
		local file = FtlDat.File(self.resource._io,self.resource,self.resource.m_root)
		file._meta = FtlDat.Meta(file._io, file, file.m_root)
		
		file._meta._filename = self:getSignature()
		file._meta._filenameSize = file._meta._filename:len()
		file._meta.body = "OK"
		file._meta._fileSize = file._meta.body:len()
		table.insert(self.resource._files,file)
	end
	
	local output = self.resource:_write()
	f:write(output)
	f:close()
end
