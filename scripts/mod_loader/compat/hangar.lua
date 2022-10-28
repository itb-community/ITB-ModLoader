
function HangarIsSecretSquadUnlocked()
	return modApi:isSecretSquadUnlocked()
end

function HangarIsSecretPilotsUnlocked()
	return modApi:isSecretPilotsUnlocked()
end

function HangarIsRandomOrCustomSquad()
	return modApi.hangar:getSelectedSquad() == "Custom"
end

function IsSecretPilotsUnlocked(profile)
	return modApi:isSecretPilotsUnlocked(profile)
end

function IsHangarWindowState()
	return modApi.hangar:isWindowState()
end

function IsHangarWindowlessState()
	return modApi.hangar:isWindowlessState()
end

function GetHangarOrigin()
	return modApi.hangar:getOrigin()
end

function HangarGetSelectedMechs()
	return modApi.hangar:getSelectedMechs()
end

function HangarGetSelectedSquad()
	return modApi.hangar:getSelectedSquad()
end

function GetBackButtonRect(languageIndex)
	return modApi.hangar:getBackButtonRect()
end

function GetStartButtonRect(languageIndex)
	return modApi.hangar:getStartButtonRect()
end
