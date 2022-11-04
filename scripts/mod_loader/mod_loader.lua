mod_loader = {}

Logger = require("scripts/mod_loader/logger")
local ScrollableLogger = require("scripts/mod_loader/logger_scrollable")

local BasicLoggerImpl = require("scripts/mod_loader/logger_basic")
local BufferedLoggerImpl = require("scripts/mod_loader/logger_buffered")
local getUninitializedDependencies

mod_loader.scrollableLogger = false
if mod_loader.scrollableLogger then
	mod_loader.logger = ScrollableLogger(BufferedLoggerImpl())
else
	mod_loader.logger = Logger(BasicLoggerImpl())
end

local oldLog = LOG

-- base logic for logging to let us set the caller as needed
-- will be 2 for most functions (0 is baseLog, 1 is the function calling baseLog, 2 is the caller of that function)
local function baseLog(caller, ...)
	if mod_loader.logger then
		local caller = mod_loader.logger:buildCallerMessage(caller)
		mod_loader.logger:log(caller, ...)
	else
		oldLog(...)
	end
end

function LOG(...)
	baseLog(2, ...)
end

function LOGF(...)
	baseLog(2, string.format(...))
end

function LOGD(...)
	if modApi.debugLogs then
		baseLog(2, ...)
	end
end

function LOGDF(...)
	if modApi.debugLogs then
		baseLog(2, string.format(...))
	end
end

function LOGW(...)
	if modApi.warningLogs then
		baseLog(2, "Warning:", ...)
	end
end

function LOGWF(...)
	if modApi.warningLogs then
		baseLog(2, "Warning:", string.format(...))
	end
end

function mod_loader:init()
	self.mod_dirs = {}
	self.mods = {}
	self.mod_list = {}
	self.mod_options = {}

	self.unmountedMods = {} -- mods which had malformed init.lua
	self.firsterror = nil

	LOGD("Enumerating extensions...")
	self:enumerateMods("scripts/mod_loader/extensions")
	self:enumerateMods("extensions")
	LOGD("Done!")

	self.extensionsEnumerated = true

	LOGD("Enumerating mods...")
	self:enumerateMods("mods")
	LOGD("Done!")

	if MOD_API_DRAW_HOOK then
		-- We used to have to replace the game's cursor with a dummy one drawn
		-- by the mod loader, but since 1.2.x, this is no longer needed, as game
		-- appears to be drawing its own cursor even over the mod loader's overlay.
		--
		-- Unfortunately, it's possible for the backup resource.dat to contain the
		-- replaced blank cursor image. This would result in people not seeing the
		-- default cursor in-game, unless they redownload unmodified resource.dat,
		-- once we removed the following line.
		--
		-- To make it easier for everyone, let's keep replacing the cursor; though
		-- this time with the real image.
		modApi:appendAsset("img/mouse/pointer.png","resources/mods/ui/pointer.png")
	end

	LOGD("Loading additional sprites...")
	self:loadAdditionalSprites()
	LOGD("Done!")
	
	Assert.Traceback = false

	local mod_options = self:getModConfig()
	local orderedMods = self:orderMods(mod_options, self:getSavedModOrder())

	-- Recreate mod_list, sorted by current known init order
	self.mod_list = {}

	-- Fill enabled mods
	local remainingMods = shallow_copy(self.mods)
	for i, id in ipairs(orderedMods) do
		table.insert(self.mod_list, self.mods[id])
	end

	-- Find remaining disabled mods
	local remainingMods = shallow_copy(self.mods)
	for i, mod in ipairs(self.mod_list) do
		remainingMods[mod.id] = nil
	end

	-- Fill mod_list with remaining mods
	for id, mod in pairs(remainingMods) do
		table.insert(self.mod_list, mod)
	end

	-- Sort extensions first
	stablesort(self.mod_list, function(a,b) return a.isExtension and not b.isExtension end)

	-- Process all mods for metadata first.
	-- orderMods only returns a list with enabled mods, so we iterate over the
	-- list of all mods here.
	-- By using a while loop, it will be possible for mods to add addtional mods
	-- during metadata initialization, and have those mods have their metadata
	-- inited as well.
	LOGD("Processing mods metadata...")
	local i = 1
	while i <= #self.mod_list do
		local id = self.mod_list[i].id
		modApi:setCurrentMod(id)
		self:initMetadata(id, mod_options)
		i = i + 1
		modApi.events.onModMetadataDone:dispatch(id)
	end
	LOGD("Done!")

	modApi.events.onModMetadataDone:unsubscribeAll()

	modApi.events.onModsMetadataDone:dispatch()
	modApi.events.onModsMetadataDone:unsubscribeAll()

	LOGD("Initializing mods...")
	local mod_options = self:getModConfig()
	local orderedMods = self:orderMods(mod_options, self:getSavedModOrder())
	self.currentModContent = mod_options
	for i, id in ipairs(orderedMods) do
		modApi:setCurrentMod(id)
		self:initMod(id, mod_options)
		modApi.events.onModInitialized:dispatch(id)
	end
	LOGD("Done!")

	modApi.events.onModInitialized:unsubscribeAll()

	Assert.Traceback = true
	modApi:setCurrentMod(nil)

	modApi.events.onModsInitialized:dispatch()
	modApi.events.onModsInitialized:unsubscribeAll()

	LOGD("Finalizing...")
	modApi:finalize()
	LOGD("Done!")

	modApi.events.onFtldatFinalized:dispatch()
	modApi.events.onFtldatFinalized:unsubscribeAll()

	LOGD("Loading pilot list...")
	self:loadPilotList()
	LOGD("Done!")

	LOGD("Verifying profile data...")
	modApi:affirmProfileData()
	LOGD("Done!")

	modApi.events.onInitialLoadingFinished:subscribe(function()
		self:loadModContent(self:getModConfig(), self:getSavedModOrder())

		modApi.events.onModsFirstLoaded:dispatch()
	end)

	LOGD("Mod loader init success!")
end

function mod_loader:loadAdditionalSprites()
	local baseDir = "resources/mods/game/"

	modApi:appendAsset("img/units/mission/train_w_broken.png",baseDir.."img/units/mission/train_w_broken.png")
	modApi:appendAsset("img/units/mission/missilesilo_w_broken.png",baseDir.."img/units/mission/missilesilo_w_broken.png")
	modApi:appendAsset("img/units/mission/generator_3_w_broken.png",baseDir.."img/units/mission/generator_3_w_broken.png")

	ANIMS.train_dual_damagedw_broken = ANIMS.BaseUnit:new{ Image = "units/mission/train_w_broken.png", PosX = -51, PosY = 3 }
	ANIMS.missilew_broken = ANIMS.BaseUnit:new{ Image = "units/mission/missilesilo_w_broken.png", PosX = -8, PosY = 5}
	ANIMS.generator3w_broken = ANIMS.BaseUnit:new{ Image = "units/mission/generator_3_w_broken.png", PosX = -17, PosY = -10 }
	
	modApi:appendAsset("img/units/placeholder_mech.png",baseDir.."img/placeholders/mech.png")
	modApi:appendAsset("img/weapons/placeholder_weapon.png",baseDir.."img/placeholders/weapon.png")
	modApi:appendAsset("img/units/placeholder_enemy.png",baseDir.."img/placeholders/enemy.png")
	modApi:appendAsset("img/empty.png",baseDir.."img/placeholders/empty.png")
	
	ANIMS.placeholder_mech = ANIMS.SingleImage:new{Image = "units/placeholder_mech.png"}
	ANIMS.placeholder_enemy = ANIMS.SingleImage:new{Image = "units/placeholder_enemy.png"}

	-- Fix incorrect offset of the 2 island Unfair victory medal.
	modApi:appendAsset("img/ui/hangar/victory_2.png", "resources/mods/ui/victory_2.png")
	-- Duplicate victory medal pngs for use by the mod loader
	-- so its ui won't trigger wasDrawn for vanilla medals.
	modApi:copyAsset("img/ui/hangar/victory_2.png", "img/ui/hangar/ml_victory_2.png")
	modApi:copyAsset("img/ui/hangar/victory_3.png", "img/ui/hangar/ml_victory_3.png")
	modApi:copyAsset("img/ui/hangar/victory_4.png", "img/ui/hangar/ml_victory_4.png")
end

local rootDirPath = Directory():path()
function mod_loader:enumerateMods(dirPathRelativeToGameDir, parentMod)
	local inputDir = Directory(dirPathRelativeToGameDir)
	if not inputDir:exists() then
		return
	end

	local dirs = inputDir:directories()

	for _, dir in ipairs(dirs) do
		local modDirPath = dir:path():gsub(rootDirPath, "")
		table.insert(self.mod_dirs, modDirPath)

		local err = ""
		local initFilePath = modDirPath .. "scripts/init.lua"

		if not modApi:fileExists(initFilePath) then
			local allDirectories = self:enumerateDirectoriesIn(modDirPath)

			-- filter out directories whose names start with '.' - by convention, these
			-- typically contain configuration or other files that programs generally
			-- shouldn't try to list / index.
			local visibleDirectories = {}
			for _, entry in ipairs(allDirectories) do
				if not modApi:stringStartsWith(entry, ".") then
					table.insert(visibleDirectories, entry)
				end
			end

			if #visibleDirectories == 1 then
				local childDirPath = visibleDirectories[1]
				dir = dir:directory(childDirPath)
				modDirPath = modDirPath .. childDirPath .."/"
				initFilePath = modDirPath .. "scripts/init.lua"
			end
		end

		local function fn()
			return dofile(initFilePath)
		end
		
		local ok, data = xpcall(fn,function(e) err = e end)
		
		if ok and type(data) ~= "table" then
			ok = false
			err = "init.lua does not return a mod data table"
		end
		
		if ok and type(data.id) ~= "string" then
			ok = false
			err = "Missing id"
		end
		
		if ok and self.mods[data.id] then
			ok = false
			err = string.format("Duplicate mod with id [%s] found at [%s]",data.id,self.mods[data.id].dir)
		end
		
		if ok and type(data.init) ~= "function" then
			ok = false
			err = "Missing init function"
		end
		
		if ok and type(data.load) ~= "function" then
			ok = false
			err = "Missing load function"
		end
		
		if ok and type(data.name) ~= "string" then
			ok = false
			err = "Missing name"
		end

		if ok and not self.extensionsEnumerated and not data.isExtension then
			ok = false
			err = string.format("Mods should be placed in [%s]", Directory("mods"):path())
		end

		if ok and data.isExtension and self.extensionsEnumerated then
			ok = false
			err = string.format("Extension should be placed in [%s]", Directory("extensions"):path())
		end

		-- Optional fields, give a warning if they're undefined or invalid
		if ok and not modApi:isValidVersion(data.version) then
			data.version = "0"
			LOGWF("mod [%s] - Invalid version", data.id)
		end

		if ok and not modApi:isValidVersion(data.modApiVersion) then
			data.modApiVersion = modApi.version
			LOGWF("mod [%s] - Invalid modApiVersion", data.id)
		end

		if ok and not modApi:isValidVersion(data.gameVersion) then
			data.gameVersion = modApi.gameVersion
			LOGWF("mod [%s] - Invalid gameVersion", data.id)
		end

		-- Optional fields, just verify the type if they're defined
		if ok and data.icon and type(data.icon) ~= "string" then
			ok = false
			err = "'icon' is not a string"
		end

		if ok and data.metadata and type(data.metadata) ~= "function" then
			ok = false
			err = "'metadata' is not a function"
		end

		if ok then
			data.dir = dir:name()
			data.path = initFilePath
			data.scriptPath = modDirPath .. "scripts/"
			data.resourcePath = modDirPath
			data.requirements = data.requirements or {}
			data.dependencies = data.dependencies or {}
			
			data.initialized = false
			data.installed = false
			
			self.mods[data.id] = data
			self.mod_list[#self.mod_list + 1] = data
			
			self.mod_options[data.id] = {
				options = {},--For configurable mods
				enabled = data.enabled == nil and true or data.enabled,
				version = data.version,
			}

			-- Format all entries as id = version
			local function formatAsIdVersionTable(list)
				for i = #list, 1, -1 do
					local id = list[i]

					if list[id] == nil then
						list[id] = ""
					end

					list[i] = nil
				end

				-- Initialize and load dependencies before this
				-- mod by adding them to the requirements table
				for id, version in pairs(list) do
					if not list_contains(data.requirements, id) then
						table.insert(data.requirements, id)
					end
				end
			end

			formatAsIdVersionTable(data.dependencies)
			
			if parentMod then
				table.insert(parentMod.children, data.id)
				data.parent = parentMod.id
				
				-- Initialize and load parent mod before submods
				if not list_contains(data.requirements, parentMod.id) then
					table.insert(data.requirements, parentMod.id)
				end

				-- Make this mod depend on parent, so it doesn't init
				-- if parent fails to init
				if data.dependencies[parentMod.id] == nil then
					data.dependencies[parentMod.id] = ""
				end
			end
			
			if data.submodFolders then
				data.children = {}
				
				if type(data.submodFolders) == "string" then
					data.submodFolders = {data.submodFolders}
				end
				
				for _, subpath in ipairs(data.submodFolders) do
					if type(subpath) == "string" then
						self:enumerateMods(modDirPath .. subpath, data)
					end
				end
			end
		end
		
		if not ok then
			LOG(string.format("Unable to mount mod at [%s]: %s", modDirPath,err))
			self.unmountedMods[modDirPath] = err
		end
	end
end

function mod_loader:enumerateFilesIn(dirPathRelativeToGameDir)
	local r = {}

	for _, file in ipairs(Directory(dirPathRelativeToGameDir):files()) do
		table.insert(r, file:name())
	end

	return r
end

function mod_loader:enumerateDirectoriesIn(dirPathRelativeToGameDir)
	local r = {}

	for _, dir in ipairs(Directory(dirPathRelativeToGameDir):directories()) do
		table.insert(r, dir:name())
	end

	return r
end

function mod_loader:initMod(id, mod_options)
	local mod = self.mods[id]
	local ok, err = true, ""

	-- Process version in init, so that mods that are not enabled don't
	-- trigger the warning dialog.
	if mod.modApiVersion and modApi:isVersionAbove(mod.modApiVersion, modApi.version) then
		mod.initialized = false
		mod.installed = false
		mod.outOfDate = true

		LOGF(
			"Could not initialize mod [%s] with id [%s], because it requires mod loader version %s or higher (installed: %s).",
			mod.name, id, mod.modApiVersion, modApi.version
		)
		return
	end

	local uninitializedDependencies = getUninitializedDependencies(mod.dependencies)
	if ok and uninitializedDependencies ~= nil then
		ok = false
		err = string.format(
			"Initializing mod [%s] with id [%s] failed:\nMissing dependencies: %s",
			mod.name, id, table.concat(uninitializedDependencies, ", ")
		)
	end

	if ok then
		ok, err = xpcall(
			function()
				LOGF("Initializing mod [%s] with id [%s]...", mod.name, id)
				mod.init(mod, mod_options[id].options)
			end,
			function(e)
				return string.format(
					"Initializing mod [%s] with id [%s] failed:\n%s\n\n%s",
					mod.name, id, e, debug.traceback("", 2)
				)
			end
		)
	end

	if ok then
		mod.initialized = true
		LOGF("Initialized mod [%s] with id [%s] successfully!", mod.name, id)
	else
		mod.initialized = false
		mod.installed = false
		mod.error = err
		if not self.firsterror then self.firsterror = err end
		LOG(err)
	end
end

function mod_loader:initMetadata(id, mod_options)
	local mod = self.mods[id]

	if mod.icon then
		mod.icon = mod.resourcePath .. mod.icon
	end

	-- Request dependencies enabled
	if mod_options[id].enabled then
		for id, version in pairs(mod.dependencies) do
			dependency = self.mod_options[id]

			if dependency then
				dependency.requested = true
			end
		end
	end

	if mod.metadata then
		local ok, err = xpcall(
			function()
				mod.metadata(mod)
			end,
			function(e)
				return string.format(
					"Preparing metadata for mod [%s] with id [%s] failed:\n%s\n\n%s",
					mod.name, id, e, debug.traceback("", 2)
				)
			end
		)

		if ok then
			LOG(string.format(
				"Metadata for mod [%s] with id [%s] prepared successfully!",
				mod.name, id
			))
		else
			LOG(err)
		end
	end
end

function mod_loader:hasMod(id)
	return self.mods[id] and true or false
end

function mod_loader:getModContentDefaults()
	local options = {}
	
	for id, mod in pairs(self.mod_options) do
		if self:hasMod(id) then
			local new = { enabled = mod.enabled, version = mod.version, options = {} }
			
			--Convert from array (for order) to keyed (for save game)
			for i, option in ipairs(mod.options) do
				local opt = { enabled = option.enabled, value = option.value }
				
				new.options[option.id] = opt
			end
			
			options[id] = new
		end
	end

	return options
end

function mod_loader:getModConfig()
	local options = self:getModContentDefaults()

	local copyOptionsFn = function(from, to)
		for id, mod in pairs(from) do
			if to[id] then
				to[id].enabled = mod.enabled or self.mod_options[id].requested
				for i, option in pairs(mod.options) do
					if to[id].options[i] then
						to[id].options[i] = mod.options[i]
					end
				end
			end
		end
	end

	local readConfigFn = function(obj)
		if not obj.modOptions then return end
		copyOptionsFn(obj.modOptions, options)
	end

	-- Read from shared config first
	sdlext.config("modcontent.lua", readConfigFn)

	-- Read from profile-specific config, if enabled
	-- For newly created profiles, this will not change the options in any way,
	-- effectively "copying" current settings.
	if modApi.profileConfig and modApi:isProfilePath() then
		sdlext.config(modApi:getCurrentProfilePath().."modcontent.lua", readConfigFn)
	end
	
	return options
end

function mod_loader:getSavedModOrder()
	local order = {}
	sdlext.config("modcontent.lua",function(obj)
		if not obj.modOrder then return end
		
		order = obj.modOrder
	end)
	
	return order
end

function mod_loader:getCurrentModContent()
	return copy_table(self.currentModContent)
end

function mod_loader:getCurrentModOrder()
	return copy_table(self.currentModOrder)
end

--[[
	This allows a mod to specify requirements = {"mod_id"} which will
	force the mod with the id "mod_id" to load before your mod.
	Partially based off Lemonymous/Lemonhead's Sequential Mod Loader
	library for Invisible, Inc.
--]]
local function requireMod(self, options, ordered, traversed, id)
	if not traversed[id] and self:hasMod(id) and options[id] and options[id].enabled then
		traversed[id] = true
		
		if type(self.mods[id].requirements) == "table" then
			for i, requiredmod in ipairs(self.mods[id].requirements) do
				requireMod(self, options, ordered, traversed, requiredmod)
			end
		end
		
		options[id] = nil
		table.insert(ordered, id)
	end
end

function getUninitializedDependencies(dependencies)
	if type(dependencies) ~= "table" then
		return nil
	end

	local uninitedDependencies = {}

	for id, version in pairs(dependencies) do
		local dependency = mod_loader.mods[id]

		if false
			or dependency == nil
			or dependency.initialized ~= true
			or modApi:isVersionBelow(dependency.version, version)
		then
			table.insert(uninitedDependencies, version == "" and id or id.." "..version)
		end
	end

	if #uninitedDependencies > 0 then
		return uninitedDependencies
	end
end

function mod_loader:orderMods(options, savedOrder)
	local options = shallow_copy(options)
	
	local traversed = {}
	local ordered = {}
	
	--If we have saved an order since before we want that to have priority
	for i, id in ipairs(savedOrder) do
		requireMod(self,options,ordered,traversed,id)
	end
	
	--Sort the remaining options by id for consistency
	local sorted = {}
	for id in pairs(options) do
		local skip = false
		
		for i = 1, #sorted do
			if id < sorted[i] then
				table.insert(sorted,i,id)
				skip = true
				break
			end
		end
		
		if not skip then
			table.insert(sorted,id)
		end
	end
	
	for i, id in ipairs(sorted) do
		requireMod(self,options,ordered,traversed,id)
	end
	
	-- Sort extensions first
	stablesort(ordered, function(a,b)
		local modA = self.mods[a]
		local modB = self.mods[b]
		return modA.isExtension and not modB.isExtension
	end)

	return ordered
end

function mod_loader:loadModContent(mod_options,savedOrder)
	LOG("--------LOADING MODS--------")
	
	self.currentModContent = mod_options
	
	--For helping with the standardized mod API--
	modApi:resetModContent()
	
	Assert.Traceback = false
	
	local orderedMods = self:orderMods(mod_options, savedOrder)
	
	for i, id in ipairs(orderedMods) do
		local mod = self.mods[id]

		-- don't try to load mods that were not initialized
		if mod.initialized then
			modApi:setCurrentMod(id)

			local ok, err = xpcall(
				function()
					mod.load(
						mod,
						mod_options[id].options,
						mod_options[id].version
					)
				end,
				function(e)
					return string.format(
						"Failed to load mod [%s] with id [%s]:\n%s\n\n%s",
						mod.name, id, e, debug.traceback("", 2)
					)
				end
			)

			if ok then
				mod.installed = true
				LOG(string.format(
					"Loaded mod [%s] with id [%s] successfully!",
					mod.name,
					id
				))
				modApi.events.onModLoaded:dispatch(id)
			else
				mod.installed = false
				mod.error = err
				if not self.firsterror then self.firsterror = err end
				LOG(err)
			end
		elseif not mod.outOfDate then
			mod.installed = false
			LOG(string.format(
				"Failed to load mod [%s] with id [%s], because it was not initialized.",
				mod.name,
				id
			))
		end
	end
	
	Assert.Traceback = true
	modApi:setCurrentMod(nil)

	modApi.events.onModsLoaded:dispatch()
end

function mod_loader:loadPilotList()
	loadPilotsOrder()
	PilotList = {}

	-- skip pilots that are not unlocked
	-- note they are sorted at the end of the list due to loadPilotsOrder
	for i = 1, modApi.constants.MAX_PILOTS do
		local name = PilotListExtended[i]
		local pilot = _G[name]
		if pilot ~= nil and (pilot.IsEnabled == nil or pilot:IsEnabled()) then
			PilotList[i] = name
		end
	end
end

modApi:init()
mod_loader:init()
