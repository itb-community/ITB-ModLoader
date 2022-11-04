
function modApi:appendAssets(appendPath, path_relativeToMod, prefix)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.ResourceDatIsOpen("Unable to append assets after init")
	Assert.Equals("string", type(appendPath), "Argument #1")
	Assert.Equals("string", type(path_relativeToMod), "Argument #2")
	Assert.Equals({"nil", "string"}, type(prefix), "Argument #3")

	prefix = prefix or ""

	local dir = Directory(self:getCurrentMod().resourcePath, path_relativeToMod)
	local path_relativeToITB = dir:relative_path()
	for _, file in ipairs(dir:files()) do
		local filename = file:name()
		if filename:find(".png$") then
			self:appendAsset(appendPath..prefix..filename, path_relativeToITB..filename)
		end
	end
end

function modApi:appendPlayerUnitAssets(path, prefix)
	self:appendAssets("img/units/player/", path, prefix)
end

function modApi:appendEnemyUnitAssets(path, prefix)
	self:appendAssets("img/units/aliens/", path, prefix)
end

function modApi:appendMissionUnitAssets(path, prefix)
	self:appendAssets("img/units/mission/", path, prefix)
end

function modApi:appendBotUnitAssets(path, prefix)
	self:appendAssets("img/units/snowbots/", path, prefix)
end

function modApi:appendCombatAssets(path, prefix)
	self:appendAssets("img/combat/", path, prefix)
end

function modApi:appendCombatIconAssets(path, prefix)
	self:appendAssets("img/combat/icons/", path, prefix)
end

function modApi:appendEffectAssets(path, prefix)
	self:appendAssets("img/effects/", path, prefix)
end

function modApi:appendWeaponAssets(path, prefix)
	self:appendAssets("img/weapons/", path, prefix)
end

function modApi:appendPassiveWeaponAssets(path, prefix)
	self:appendAssets("img/weapons/passives/", path, prefix)
end

modApi.appendMechAssets = modApi.appendPlayerUnitAssets
modApi.appendVekAssets = modApi.appendEnemyUnitAssets
modApi.appendBotAssets = modApi.appendBotUnitAssets
