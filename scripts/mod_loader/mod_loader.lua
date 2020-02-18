mod_loader = {}

Logger = require("scripts/mod_loader/logger")

local BasicLogger = require("scripts/mod_loader/logger_basic")
local ScrollableLogger = require("scripts/mod_loader/logger_scrollable")
local BufferedLogger = require("scripts/mod_loader/logger_buffered")

local useBufferedLogger = false
if useBufferedLogger then
	mod_loader.logger = ScrollableLogger(BufferedLogger)
else
	mod_loader.logger = Logger(BasicLogger)
end


local oldLog = LOG
function LOG(...)
	if mod_loader.logger then
		mod_loader.logger:log(...)
	else
		oldLog(...)
	end
end

function LOGF(...)
	LOG(string.format(...))
end

function mod_loader:init()
	self.mod_dirs = {}
	self.mods = {}
	self.mod_options = {}

	self.unmountedMods = {} -- mods which had malformed init.lua
	self.firsterror = nil
	
	modApi.modsInitializedHooks = {}
	
	self:enumerateMods()

	if MOD_API_DRAW_HOOK then
		-- Replace the game's cursor with a transparent image.
		-- Helps visually, as some modded UI may want to completely intercept
		-- mousemotion events, in which case the game's own cursor would 'hitch',
		-- and stop moving once the mouse entered the modded UI's bounds.
		-- We re-draw the cursor ourselves on top of modded UI to retain smooth
		-- mouse pointer movement.
		modApi:appendAsset("img/mouse/pointer.png","resources/mods/ui/pointer-dummy.png")
	end

	self:loadAdditionalSprites()

	-- Process all mods for metadata first.
	-- orderMods only returns a list with enabled mods, so we iterate over the
	-- list of all mods here.
	for id, _ in pairs(self.mods) do
		modApi:setCurrentMod(id)
		self:initMetadata(id)
	end

	local orderedMods = self:orderMods(self:getModConfig(), self:getSavedModOrder())
	for i, id in ipairs(orderedMods) do
		modApi:setCurrentMod(id)
		self:initMod(id)
	end

	for i, hook in ipairs(modApi.modsInitializedHooks) do
		local ok, err = pcall(function() hook() end)

		if not ok then
			LOG("A modsInitializedHook failed: ", err)
		end
	end
	modApi.modsInitializedHooks = nil
	
	modApi:finalize()
	
	self:loadModContent(self:getModConfig(), self:getSavedModOrder())
	self:loadPilotList()
	modApi:affirmProfileData()
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
	
	ANIMS.placeholder_mech = ANIMS.SingleImage:new{Image = "units/placeholder_mech.png"}
	ANIMS.placeholder_enemy = ANIMS.SingleImage:new{Image = "units/placeholder_enemy.png"}
end

function mod_loader:enumerateMods()
	self.mod_dirs = self:enumerateDirectoriesIn("mods")

	for i, dir in pairs(self.mod_dirs) do
		local err = ""
		local path = string.format("mods/%s/scripts/init.lua",dir)
		local function fn()
			return dofile(path)
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
		
		--Proper version control could be handy, but there's no standardized format atm so whatever, each mod can use what they want
		
		--[[if ok and type(data.version) ~= "string" then
			ok = false
			err = "Missing version"
		end
		
		if ok and not version.parseVersion(data.version) then
			ok = false
			err = "Invalid version format"
		end]]

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
			data.dir = dir
			data.path = path
			data.scriptPath = string.format("mods/%s/scripts/",dir)
			data.resourcePath = string.format("mods/%s/",dir)
			
			data.initialized = false
			data.installed = false
			
			self.mods[data.id] = data
			
			self.mod_options[data.id] = {
				options = {},--For configurable mods
				enabled = true,
				version = data.version,
			}
		end
		
		if not ok then
			LOG(string.format("Unable to mount mod at [%s]: %s",dir,err))
			self.unmountedMods[dir] = err
		end
	end
end

function mod_loader:enumerateDirectoriesIn(dirPathRelativeToGameDir)
	dirPathRelativeToGameDir = dirPathRelativeToGameDir:gsub("/", "\\")

	if os and os.listdirs then
		return os.listdirs(dirPathRelativeToGameDir)
	else
		local result = {}
		local directory = io.popen(string.format([[dir ".\%s\" /B /AD]], dirPathRelativeToGameDir))
		for dir in directory:lines() do
			table.insert(result, dir)
		end

		directory:close()

		return result
	end
end

function mod_loader:initMod(id)
	local mod = self.mods[id]

	-- Process version in init, so that mods that are not enabled don't
	-- trigger the warning dialog.
	if mod.modApiVersion and not modApi:isVersion(mod.modApiVersion) then
		mod.initialized = false
		mod.installed = false
		mod.outOfDate = true

		LOG(string.format(
			"Could not initialize mod [%s] with id [%s], because it requires mod loader version %s or higher (installed: %s).",
			mod.name, id, mod.modApiVersion, modApi.version
		))
		return
	end

	local ok, err = xpcall(
		function()
			mod.init(mod)
		end,
		function(e)
			return string.format(
				"Initializing mod [%s] with id [%s] failed:\n%s\n\n%s",
				mod.name, id, e, debug.traceback("", 2)
			)
		end
	)

	if ok then
		mod.initialized = true
		LOG(string.format(
			"Initialized mod [%s] with id [%s] successfully!",
			mod.name,
			id
		))
	else
		mod.initialized = false
		mod.installed = false
		mod.error = err
		if not self.firsterror then self.firsterror = err end
		LOG(err)
	end
end

function mod_loader:initMetadata(id)
	local mod = self.mods[id]

	if mod.icon then
		mod.icon = mod.resourcePath .. mod.icon
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
	return self.mods[id] and self.mod_options[id].enabled
end

function mod_loader:getModContentDefaults()
	local options = {}
	
	for id, mod in pairs(self.mod_options) do
		if self:hasMod(id) then
			local new = { enabled = true, version = mod.version, options = {} }
			
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
				to[id].enabled = mod.enabled
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
	if modApi.profileConfig then
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
	
	return ordered
end

function mod_loader:loadModContent(mod_options,savedOrder)
	LOG("--------LOADING MODS--------")
	
	self.currentModContent = mod_options
	
	--For helping with the standardized mod API--
	modApi:resetModContent()
	
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
						"Loading mod [%s] with id [%s] failed:\n%s\n\n%s",
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

	for i, hook in ipairs(modApi.modsLoadedHooks) do
		local ok, err = pcall(function() hook() end)

		if not ok then
			LOG("A modsLoadedHook failed: ", err)
		end
	end
end

function mod_loader:loadPilotList()
	loadPilotsOrder()
	PilotList = {}
	
	local max_pilots = 13
	for i = 1, max_pilots do
		PilotList[i] = PilotListExtended[i]
	end
end

modApi:init()
mod_loader:init()
