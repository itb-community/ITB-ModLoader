--lfs = require("lfs")
mod_loader = {}

function mod_loader:init()
	self.mod_dirs = {}
	self.mods = {}
	self.unmountedMods = {} -- mods which had malformed init.lua
	self.mod_options = {}
	
	self:enumerateMods()
	
	local orderedMods = self:orderMods(self:getModConfig(),self:getSavedModOrder())
	for i, id in ipairs(orderedMods) do
		modApi:setCurrentMod(id)
		self:initMod(id)
	end
	
	modApi:finalize()
	
	self:loadModContent(self:getModConfig(),self:getSavedModOrder())
end

function mod_loader:enumerateMods()
	if os and os.listdirs then
		self.mod_dirs = os.listdirs("mods")
	else
		for dir in io.popen([[dir ".\mods\" /b /ad]]):lines() do table.insert(self.mod_dirs,dir) end
	end
	
	for i, dir in pairs(self.mod_dirs) do
		local err = ""
		local path = string.format("mods/%s/scripts/init.lua",dir)
		local function fn()
			return dofile(path)
		end
		
		local ok, data = xpcall(fn,function(e) err = e end)
		
		if ok and type(data) ~= "table" then
			ok = false
			err = "Missing data"
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
		
		if ok then
			data.dir = dir
			data.path = path
			data.scriptPath = string.format("mods/%s/scripts/",dir)
			data.resourcePath = string.format("mods/%s/",dir)
			
			data.initialized = false
			data.installed = true
			
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

function mod_loader:initMod(id)
	local mod = self.mods[id]
	
	local function pinit()
		mod.init(mod)
	end
	local ok, err = xpcall(pinit,function(e) return string.format("Initializing mod [%s] with id [%s] failed: %s, %s",mod.name,id,e,debug.traceback()) end)
	if ok then
		mod.initialized = true
		LOG(string.format("Initialized mod [%s] with id [%s] successfully!",mod.name,id))
	else
		mod.initialized = false
		mod.installed = false
		mod.error = err
		LOG(err)
	end
end

function mod_loader:hasMod(id)
	return self.mods[id] and self.mods[id].installed
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
	
	sdlext.config("modcontent.lua",function(obj)
		if not obj.modOptions then return end
		
		for id,mod in pairs(obj.modOptions) do
			if options[id] then
				options[id].enabled = mod.enabled
				for i, option in pairs(mod.options) do
					if options[id].options[i] then
						options[id].options[i] = mod.options[i]
					end
				end
			end
		end
	end)
	
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

--This allows a mod to specify requirements = {"mod_id"} which will force the mod with the id "mod_id" to load before your mod
--Partially based off Lemonymous/Lemonhead's Sequential Mod Loader library for Invisible, Inc.
local function requireMod(self,options,ordered,traversed,id)
	if not traversed[id] and self:hasMod(id) and options[id] and options[id].enabled then
		traversed[id] = true
		
		if type(self.mods[id].requirements) == "table" then
			for i, requiredmod in ipairs(self.mods[id].requirements) do
				requireMod(self,options,ordered,traversed,requiredmod)
			end
		end
		
		options[id] = nil
		table.insert(ordered,id)
	end
end

function mod_loader:orderMods(options,savedOrder)
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
	
	local orderedMods = self:orderMods(mod_options,savedOrder)
	
	for i, id in ipairs(orderedMods) do
		local mod = self.mods[id]
		modApi:setCurrentMod(id)
		
		local function pload()
			mod.load(mod,mod_options[id].options,mod_options[id].version)
		end
		local ok, err = xpcall(pload,function(e) return string.format("Loading mod [%s] with id [%s] failed: %s, %s",mod.name,id,e,debug.traceback()) end)
		if ok then
			mod.installed = true
			LOG(string.format("Loaded mod [%s] with id [%s] successfully!",mod.name,id))
		else
			mod.installed = false
			mod.error = err
			LOG(err)
		end
	end
end

modApi:init()
mod_loader:init()