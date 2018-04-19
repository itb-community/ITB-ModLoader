-- This class serves mostly as a self-documenting guide to common mod operations,
-- as well as an indirection layer to maintain a kind of sanity for compatability purposes

local FtlDat = require("scripts/mod_loader/ftldat")

modApi = {}

local prev_path = package.path

local function file_exists(name)
   local f=io.open(name,"rb")
   if f~=nil then io.close(f) return true else return false end
end

function modApi:init()
	--package.path = prev_path..package.path
	self.logger = require("scripts/mod_loader/logger")
	applyModLoaderConfig(loadModLoaderConfig())
	if self.logger.logLevel == self.logger.LOG_LEVEL_FILE then
		self.logger.logToFile("log.txt")
	end

	self.version = "2.1.4"
	LOG("MOD-API VERSION "..self.version)
	self.currentModSquads = {}
	self.currentModSquadText = {}
	
	if not file_exists("resources/resource.dat.bak") then
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

	self.compareScheduledHooks = function(a, b)
		return a.triggerTime < b.triggerTime
	end
	self.timer = sdl.timer()
	self.msDeltaTime = 0
	self.msLastElapsed = 0
	MODAPI_HOOK_draw = sdl.drawHook(function(screen)
		local t = modApi.timer:elapsed()
		if t > modApi.msLastElapsed then
			modApi.msDeltaTime = t - modApi.msLastElapsed
			modApi.msLastElapsed = t
		end

		modApi:updateScheduledHooks()
	end)
end

function modApi:deltaTime()
	return self.msDeltaTime
end

function modApi:elapsedTime()
	-- return cached time, so that mods don't get different
	-- timings depending on when in the frame they called
	-- this function.
	return self.msLastElapsed
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

--Maintain sanity
--Update as new API functions are added
function modApi:resetModContent()
	self.textOverrides = {}
	self.mod_squads = {
		{"Rift Walkers","PunchMech", "TankMech", "ArtiMech"},
		{"Rusting Hulks","JetMech", "RocketMech",  "PulseMech"},
		{"Zenith Guard","LaserMech", "ChargeMech", "ScienceMech"},
		{"Blitzkrieg","ElectricMech", "WallMech", "RockartMech"},
		{"Steel Judoka","JudoMech", "DStrikeMech", "GravMech"},
		{"Flame Behemoths","FlameMech", "IgniteMech", "TeleMech"},
		{"Frozen Titans","GuardMech", "MirrorMech", "IceMech"},
		{"Hazardous Mechs","LeapMech", "UnstableTank", "NanoMech"},
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
	self.scheduledHooks = {}
	self.nextTurnHooks = {}
	self.missionUpdateHooks = {}
	self.missionStartHooks = {}
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
			ret:AddScript([[local ret = SkillEffect()
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
			ret:AddScript([[local ret = SkillEffect()
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
			ret:AddScript([[local ret = SkillEffect()
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

function modApi:addGenerationOption(id,name,tip,data)
	assert(type(id) == "string" or type(id) == "number")
	assert(type(name) == "string")
	tip = tip or nil
	assert(type(tip) == "string")
	data = data or {}
	assert(type(data) == "table")--Misc stuff
	for i, option in ipairs(mod_loader.mod_options[self.currentMod]) do
		assert(option.id ~= id)
	end
	
	local option = {id = id, name = name, tip = tip, check = true, enabled = true, data = data}
	
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
	
	table.insert(mod_loader.mod_options[self.currentMod].options,option)
end

function modApi:addSquadTrue(squad,name,desc,icon)
	return self:addSquad(squad,name,desc,icon)
end

function modApi:addSquad(squad,name,desc,icon)
	assert(type(squad) == "table")
	assert(#squad == 4)
	assert(type(name) == "string")
	assert(type(desc) == "string")
	table.insert(self.mod_squads,squad)
	table.insert(self.squad_text,name)
	table.insert(self.squad_text,desc)
	table.insert(self.squad_icon,icon or "resources/mods/squads/unknown.png")
end

function modApi:overwriteTextTrue(id,str)
	return self:overwriteText(id,str)
end

function modApi:overwriteText(id,str)
	assert(type(id) == "string")
	assert(type(str) == "string")
	self.textOverrides[id] = str
end

function modApi:addPreMissionAvailableHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preMissionAvailableHooks,fn)
end

function modApi:addPostMissionAvailableHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postMissionAvailableHooks,fn)
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

function modApi:addMissionEndHook(fn,i)
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

function modApi:addWeapon_Texts(tbl)
	assert(type(tbl) == "table")
	for k,v in pairs(tbl) do
		Weapon_Texts[k] = v
	end
end

function modApi:addPopEvent(event,msg)
	assert(type(event) == "string")
	assert(type(msg) == "string")
	if not self.PopEvents[event] then
		self.PopEvents[event] = {}
	end
	
	table.insert(self.PopEvents[event],msg)
end

function modApi:setPopEventOdds(event,odds)
	assert(type(event) == "string")
	assert(self.PopEvents[event])
	assert(odds == nil or type(odds) == "number")
	
	self.PopEvents[event].Odds = odds
end

function modApi:addOnPopEvent(fn)
	assert(type(fn) == "function")
	table.insert(self.onGetPopEvent,fn)
end

function modApi:appendAsset(resource,filePath)
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