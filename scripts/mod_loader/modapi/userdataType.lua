
local function isUserdataClass(userdata)
	Assert.Equals("userdata", type(userdata), "Argument #1")

	return getmetatable(userdata).__luabind_classrep == true
end

local function isUserdataInstance(userdata)
	Assert.Equals("userdata", type(userdata), "Argument #1")

	return getmetatable(userdata).__luabind_class == true
end

function GetUserdataType(userdata)
	Assert.Equals("userdata", type(userdata), "Argument #1")

	if userdata.GetUserdataType then
		return userdata:GetUserdataType()
	end

	return "Unknown"
end

function Point:GetUserdataType()
	if isUserdataClass(self) then
		return "PointClass"
	end

	return "Point"
end

function PAWN_FACTORY:GetUserdataType()
	return "PAWN_FACTORY"
end

function Board:GetUserdataType()
	return "Board"
end

function BoardPawn:GetUserdataType()
	return "Pawn"
end

function SkillEffect:GetUserdataType()
	if isUserdataClass(self) then
		return "SkillEffectClass"
	end

	return "SkillEffect"
end

function SpaceDamage:GetUserdataType()
	if isUserdataClass(self) then
		return "SpaceDamageClass"
	end

	return "SpaceDamage"
end

function GameMap:GetUserdataType()
	if isUserdataClass(self) then
		return "GameClass"
	end

	return "Game"
end

modApi.isUserdataClass = isUserdataClass
modApi.isUserdataInstance = isUserdataInstance
