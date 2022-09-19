
-- Returns the dll instance of memedit,
-- if it is avalable and calibrated
function modApi.getMemedit()
	if modApi.memedit and modApi.memedit.calibrated then
		return modApi.memedit.dll
	end

	return nil
end

-- Returns the dll instance of memedit,
-- if it is avalable and calibrated.
-- Throws an error if it is not.
function modApi.requireMemedit()
	if not modApi.memedit then
		error("Mod loader extension memedit is unavailable")
	elseif not modApi.memedit.calibrated then
		error("Mod loader extension memedit is uncalibrated")
	end

	return modApi.memedit.dll
end
