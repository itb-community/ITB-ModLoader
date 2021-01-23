
-------------------------------------------------------------
--- Override default Move:GetSkillEffect to fix leap movement
-------------------------------------------------------------

function Move:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	if Pawn:IsJumper() then
		local plist = PointList()
		plist:push_back(p1)
		plist:push_back(p2)
		ret:AddLeap(plist, FULL_DELAY)
	elseif Pawn:IsTeleporter() then
		ret:AddTeleport(p1, p2, FULL_DELAY)
	else
		ret:AddMove(Board:GetPath(p1, p2, Pawn:GetPathProf()), FULL_DELAY)
	end

	return ret
end

-------------------------------------------------------------
--- Override default Move:GetSkillEffect to implement handling
--- of pawn Move Skills
-------------------------------------------------------------

local oldMoveGetTargetArea = Move.GetTargetArea
function Move:GetTargetArea(point)
	local moveSkill = _G[Pawn:GetType()].MoveSkill
	
	if moveSkill ~= nil and moveSkill.GetTargetArea ~= nil then
		return moveSkill:GetTargetArea(point)
	end

	return oldMoveGetTargetArea(self, point)
end


local oldMoveGetSkillEffect = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2)
	local moveSkill = _G[Pawn:GetType()].MoveSkill

	if moveSkill ~= nil and moveSkill.GetSkillEffect ~= nil then
		return moveSkill:GetSkillEffect(p1, p2)
	end

	return oldMoveGetSkillEffect(self, p1, p2)
end

-------------------------------------------------------------
--- Override all Skills' GetTipDamage to implement
--- tooltip hide & show hooks
-------------------------------------------------------------

local tipSkillLast = nil
local tipSkillCurrent = nil
local function buildGetTipDamageOverride(skill)
	local originalFn = skill.GetTipDamage

	return function(self, pawn, ...)
		tipSkillCurrent = self

		return originalFn(self, pawn, ...)
	end
end

sdlext.addFrameDrawnHook(function()
	if tipSkillLast and tipSkillCurrent ~= tipSkillLast then
		modApi:fireTipImageHiddenHooks(tipSkillLast)
	end

	if tipSkillCurrent and tipSkillCurrent ~= tipSkillLast then
		modApi:fireTipImageShownHooks(tipSkillCurrent)
	end

	tipSkillLast = tipSkillCurrent
	tipSkillCurrent = nil
end)

local function overrideSkillFunction(skill, functionName, fn)
	Assert.Equals("table", type(skill), "Argument #1")
	Assert.Equals(
			"function", type(skill.GetSkillEffect),
			string.format("Argument #1 does not reference a Skill", skill)
	)
	Assert.Equals("string", type(functionName), "Argument #2")
	Assert.Equals("function", type(fn), "Argument #3")

	skill[functionName] = fn
	-- TODO: Could add a metatable with with __newindex function to protect overrides
	-- added by the mod loader / reapply the override with the new argument as originalFn
	-- This would remove the need for ModsInitializedHook here, but what about newly added
	-- weapons, or weapons created dynamically, after the game is initialized?
	-- Add metatable with __newindex to _G, that checks if newly added variable is a Skill...?
end

local function overrideAllSkills()
	for k, v in pairs(_G) do
		if type(v) == "table" and v.GetSkillEffect then
			-- Make it possible to identify skills with no ambiguity
			v.__Id = k

			overrideSkillFunction(v, "GetTipDamage", buildGetTipDamageOverride(v))
		end
	end
end

modApi:addModsInitializedHook(function()
	-- Defer the call until all mods have been loaded, so that they don't break the detection
	overrideAllSkills()
end)

function modApi:getHoveredSkill()
	return tipSkillLast
end

function modApi:isHoveredSkill(id)
	Assert.Equals("string", type(id), "Argument #1")
	return tipSkillLast and tipSkillLast.__Id == id
end

function modApi:isTipImage()
	return tipSkillLast ~= nil
end
