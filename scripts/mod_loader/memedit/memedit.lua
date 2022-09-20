
local Scanner = require("scripts/mod_loader/memedit/scanner")

modApi.memedit = {
	initialized = false,
	dll = nil,
	scanner = Scanner(),
	calibrated = false,
	calibrating = false,
	onCalibrateStart = Event(),
	onCalibrateFinished = Event(),
}

function modApi.memedit:isDebug()
	return true
		and self.dll ~= nil
		and self.dll.debug ~= nil
end

function modApi.memedit:unload()
	LOG("Memedit - Unloading memedit.dll!")
	self.calibrated = false
	self.dll = nil
end

function modApi.memedit:load(options)
	self.calibrated = false
	options = options or {}

	if not options.silent then
		if options.debug then
			LOGF("Memedit - Loading memedit.dll in debug mode...")
		else
			LOGF("Memedit - Loading memedit.dll...")
		end
	end

	local complete = true
	for scanType, scandefs in pairs(self.scanner.scandefs) do
		local addresses = options[scanType]

		if type(addresses) == 'table' then
			for _, scandef in pairs(scandefs) do
				if addresses[scandef.id] == nil then
					complete = false
					break
				end
			end
		else
			complete = false
		end

		if not complete then
			break
		end
	end

	try(function()
		package.loadlib("memedit.dll", "luaopen_memedit")(options)
		self.dll = memedit
		memedit = nil
	end)
	:catch(function(err)
		error(string.format(
				"Memdit - Failed to load memedit.dll: %s",
				tostring(err)
		))
	end)

	self.calibrated = complete
	if not options.silent then
		if options.debug then
			LOG("Memedit - Successfully loaded memedit.dll in debug mode!")
		elseif complete then
			LOG("Memedit - Successfully loaded fully calibrated memedit.dll!")
		else
			LOG("Memedit - Successfully loaded uncalibrated memedit.dll!")
		end
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

	LOG("Memedit - Calibration started - Follow the instructions to complete the process...")
	self:unload()
	self.failed = false
	self.calibrating = true

	self.scanner:restart()
	self.scanner.onFinishedSuccessfully:subscribe(function(addressLists)
		self.calibrating = false

		self:load(addressLists)

		if self.calibrated then
			LOG("Memedit - Calibration finished successfully!")
			LOG("Memedit - Storing results to file...")
			self:saveAddressesToFile(addressLists)
			LOG("Memedit - Results saved!")
		else
			LOG("Memedit - Calibration ended with incomplete results!")
			LOG("Memedit - Discarding results!")
		end

		self.onCalibrateFinished:dispatch(self.calibrated)
	end)

	self.scanner.onFinishedUnsuccessfully:subscribe(function()
		self.failed = true
		self.calibrating = false
		LOG("Memedit - Caibration ended in failure!")
		self.onCalibrateFinished:dispatch(self.calibrated)
	end)

	self.onCalibrateStart:dispatch()
end

function modApi.memedit:init()
	if self.initialized then return end
	self.initialized = true

	LOG("Memedit - Initializing...")
	local addressLists = self:loadAddressesFromFile()
	self:load(addressLists)
	self.loaded = self.calibrated

	if self.calibrated then
		LOG("Memedit - Initialized successfully!")
	else
		LOG("Memedit - Initialization incomplete - Calibration required!")
	end
end

modApi.memedit:init()
