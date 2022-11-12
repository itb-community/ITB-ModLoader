
local IMG = "img/"
local ROOT_MECH = "units/player/"
local ROOT_VEK = "units/aliens/"
local PNG = ".png"
local TILE_HALF_HEIGHT = 21

local function createAnimation(id, animDef)
	if type(animDef.Image) ~= 'string' then
		Assert.Error("Animation 'Image' must be a 'string'")
	end

	local filePath = animDef.Image
	local fullFilePath = IMG..filePath

	if not modApi:assetExists(fullFilePath) then
		Assert.Error(string.format("Asset %q not found in resource.dat", fullFilePath))
	end

	local base = animDef.Base or "Animation"
	local baseAnim = ANIMS[base]

	if baseAnim == nil then
		Assert.Error(string.format("Base animation %s not found", base))
	end

	local anim = baseAnim:new(animDef)

	if anim.CenterX then
		anim.PosX = -anim.CenterX
	end

	if anim.CenterY then
		anim.PosY = -anim.CenterY + TILE_HALF_HEIGHT 
	end

	ANIMS[id] = anim
end

function modApi:createMechAnimations(animDefs)
	Assert.Equals('table', type(animDefs), "Argument #1")

	for id, animDef in pairs(animDefs) do
		if animDef.Image == nil then
			animDef.Image = ROOT_MECH..id..PNG
		end

		if animDef.Base == nil then
			animDef.Base = "MechUnit"
		end

		createAnimation(id, animDef)
	end
end

function modApi:createVekAnimations(animDefs)
	Assert.Equals('table', type(animDefs), "Argument #1")

	for id, animDef in pairs(animDefs) do
		if animDef.Image == nil then
			animDef.Image = ROOT_VEK..id..PNG
		end

		if animDef.Base == nil then
			animDef.Base = "EnemyUnit"
		end

		createAnimation(id, animDef)
	end
end

function modApi:createAnimations(animDefs)
	Assert.Equals('table', type(animDefs), "Argument #1")

	for id, animDef in pairs(animDefs) do
		createAnimation(id, animDef)
	end
end
