
local function relpath(dir)
	return dir:path():gsub("^"..Directory():path(), "")
end

local function appendAssets(gameRoot, modPath, prefix)
	Assert.ResourceDatIsOpen("Unable to append assets after init")

	local modDir = Directory(modApi:getCurrentMod().resourcePath, modPath)
	local modRoot = relpath(modDir)
	for _, file in ipairs(modDir:files()) do
		local filename = file:name()
		if filename:find(".png$") then
			modApi:appendAsset(gameRoot..prefix..filename, modRoot..filename)
		end
	end
end

function modApi:appendPlayerUnitAssets(path, prefix)
	appendAssets("img/units/player/", path, prefix)
end

function modApi:appendEnemyUnitAssets(path, prefix)
	appendAssets("img/units/aliens/", path, prefix)
end

function modApi:appendMissionUnitAssets(path, prefix)
	appendAssets("img/units/mission/", path, prefix)
end

function modApi:appendBotUnitAssets(path, prefix)
	appendAssets("img/units/snowbots/", path, prefix)
end

function modApi:appendCombatAssets(path, prefix)
	appendAssets("img/combat/", path, prefix)
end

function modApi:appendCombatIconAssets(path, prefix)
	appendAssets("img/combat/icons/", path, prefix)
end

function modApi:appendEffectAssets(path, prefix)
	appendAssets("img/effects/", path, prefix)
end

function modApi:appendWeaponAssets(path, prefix)
	appendAssets("img/weapons/", path, prefix)
end

function modApi:appendPassiveWeaponAssets(path, prefix)
	appendAssets("img/weapons/passives/", path, prefix)
end

modApi.appendMechAssets = modApi.appendPlayerUnitAssets
modApi.appendVekAssets = modApi.appendEnemyUnitAssets
modApi.appendBotAssets = modApi.appendBotUnitAssets
