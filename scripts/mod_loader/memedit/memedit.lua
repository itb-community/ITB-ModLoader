
local Scanner = require("scripts/mod_loader/memedit/scanner")

modApi.memedit = {
	initialized = false,
	dll = nil,
	addresses = nil,
	scanner = Scanner(),
	calibrated = false,
	calibrating = false,
	onCalibrateStart = Event(),
	onCalibrateUpdate = Event(),
	onCalibrateFinished = Event(),
}

function modApi.memedit:isDebug()
	return true
		and self.dll ~= nil
		and self.dll.debug ~= nil
end

function modApi.memedit:unload()
	self.dll = nil
end

function modApi.memedit:load(options)
	options = options or {}

	local function loadSilent()
		package.loadlib("cutils.dll", "luaopen_memedit")(options)
		self.dll = memedit
		memedit = nil
	end

	local function load()
		local inDebugMode = options.debug
			and " in debug mode"
			or ""

		LOGF("Memedit - Loading memedit.dll%s...", inDebugMode)
		loadSilent()
		LOG("Memedit - Successfully loaded memedit.dll!")
	end

	if options.silent then
		load = loadSilent
	end

	try(load)
	:catch(function(err)
		error(string.format(
				"Memdit - Failed to load memedit.dll: %s",
				tostring(err)
		))
	end)
end

function modApi.memedit:verifyAndLoad(options)
	LOG("Memedit - Verifying and loading...")
	local ok = true

	for scanType, scandefs in pairs(self.scanner.scandefs) do
		local addresses = options[scanType]

		if type(addresses) == 'table' then
			for _, scandef in pairs(scandefs) do
				if addresses[scandef.id] == nil then
					ok = false
					break
				end
			end
		else
			ok = false
		end

		if not ok then
			break
		end
	end

	if ok then
		LOG("Memedit - Verified!")
		self.calibrated = true
		self:load(options)
	else
		LOG("Memedit - Failed to load - Calibration incomplete")
		self.calibrated = false
	end
end

local function configureAddresses(filename, func)
	local obj = persistence.load(filename)
	obj = obj or {}

	func(obj)

	persistence.store(filename, obj)
end

function modApi.memedit:loadAddressesFromFile()
	local result = nil

	configureAddresses(
		"scripts/mod_loader/memedit/__addresses.lua",
		function(obj)
			for version, addresses in pairs(obj) do
				if version == modApi.gameVersion then
					result = addresses
					return
				end
			end
		end
	)

	return result
end

function modApi.memedit:saveAddressesToFile(addressList)
	configureAddresses(
		"scripts/mod_loader/memedit/__addresses.lua",
		function(obj)
			local versionBucket = obj[modApi.gameVersion]

			if versionBucket == nil then
				versionBucket = {}
				obj[modApi.gameVersion] = versionBucket
			end

			for id, entry in pairs(addressList) do
				versionBucket[id] = entry
			end
		end
	)
end

function modApi.memedit:recalibrate()
	if self.calibrating then return end

	self.calibrated = false
	self.calibrating = true

	LOG("Memedit - Calibration started - Follow the instructions to complete the process...")
	self.scanner:restart()
	self.scanner.onFinishedSuccessfully:subscribe(function(addressLists)
		self.calibrating = false

		LOG("Memedit - Storing results to file...")
		self:saveAddressesToFile(addressLists)
		LOG("Memedit - Results saved!")

		self:verifyAndLoad(addressLists)

		LOG("Memedit - Calibration successful!")
	end)

	self.scanner.onFinishedUnsuccessfully:subscribe(function()
		self.calibrating = false

		LOG("Memedit - Caibration failed!")
	end)

	self.onCalibrateStart:dispatch()
end

function modApi.memedit:init()
	if self.initialized then return end

	LOG("Memedit - Initializing...")
	local options = self:loadAddressesFromFile()

	if options then
		self:verifyAndLoad(options)
	else
		LOG("Memedit - Failed to load - Calibration incomplete.")
	end

	LOG("Memedit - Initialization complete!")
end

modApi.memedit:init()
