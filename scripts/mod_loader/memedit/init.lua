
modApi.memedit = {
	dll = nil,
	calibrated = false,
	calibrating = false,
	onCalibrateStart = Event(),
	onCalibrateUpdate = Event(),
	onCalibrateFinished = Event(),
}

local function configureAddresses(filename, func)
	local obj = persistence.load(filename)
	obj = obj or {}

	func(obj)

	persistence.store(filename, obj)
end

configureAddresses(
	"scripts/mod_loader/memedit/__addresses.lua",
	function(obj)
		for version, addresses in pairs(obj) do
			if version == modApi.gameVersion then
				if obj.calibrated == true then
					modApi.memedit.calibrated = true
				end
			end
		end

		if not modApi.memedit.calibrated then
			obj[modApi.gameVersion] = {
				calibrated = false
			}
		end
	end
)

function modApi.memedit:startCalibrate()
	self.calibrated = false
	self.calibrating = true

	self.onCalibrateStart:dispatch()
end
