
-------------------------------------------------------------
--- Override default Move:GetSkillEffect to fix leap movement
-------------------------------------------------------------

-- create Default_Move as a skill for modders to extend if they wished to extend Move
Default_Move = Move

-- helper to apply Adjacent_Heal and Web_Vek
-- modders are free to override this function to easily add additional effects
function Move.DoPostMoveEffects(moveSkill, ret, p1, p2)
	if Pawn:IsAbility("Web_Vek") then
		for i = 0, 3 do
			local curr = p2 + DIR_VECTORS[i]
			if Board:IsPawnSpace(curr) and Board:GetPawn(curr):GetTeam() == TEAM_ENEMY then
				ret:AddGrapple(p2, curr, "hold")
			end
		end
	end

	if Pawn:IsAbility("Adjacent_Heal") then
		for i = 0, 3 do
			local curr = p2 + DIR_VECTORS[i]
			if Board:IsPawnSpace(curr) and Board:GetPawn(curr):GetTeam() == TEAM_PLAYER and Board:GetPawn(curr):GetId() ~= Pawn:GetId() then
				ret:AddDamage(SpaceDamage(curr,-1))
			end
		end
	end
end

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

	-- custom move skill will automatically get the post move effects as part of the modloader's GetSkillEffect below
	-- to prevent running them twice, skip if Default_Move is extended
	if self == Default_Move then
		Move.DoPostMoveEffects(self, ret, p1, p2)
	end

	return ret
end

-------------------------------------------------------------
--- Override default Move:GetTargetArea to fix leap and
--- teleport movement allowing non-flying pawns to move onto chasms
-------------------------------------------------------------

local function getReachableGroundTeleporter(board, p1, maxDistance, pathProf)
	return board:GetTiles(function(p)
		local distance = p:Manhattan(p1)
		if distance <= maxDistance and not board:IsBlocked(p, pathProf) then
			return true
		end

		return false
	end)
end

function Move:GetTargetArea(p)
	if not Pawn:IsFlying() and (Pawn:IsJumper() or Pawn:IsTeleporter()) then
		return getReachableGroundTeleporter(Board, p, Pawn:GetMoveSpeed(), Pawn:GetPathProf())
	end

	return Board:GetReachable(p, Pawn:GetMoveSpeed(), Pawn:GetPathProf())
end

-------------------------------------------------------------
--- Override default Move:GetSkillEffect to implement handling
--- of pawn Move Skills
-------------------------------------------------------------

local function traceback()
	return Assert.Traceback and debug.traceback("\n", 3) or ""
end

local function assertIsStringToSkillTable(skill_id, msg)
	local skill = _G[skill_id]
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected _G[%q] to be a valid Skill/Weapon, but was %s%s", skill_id, type(skill), traceback())
	assert(type(skill) == "table" and type(skill.GetTargetArea) == "function" and type(skill.GetSkillEffect) == "function", msg)
end

-- extend default move to create the new move skill, means any vanilla skills extending Move will not get the injections
Move = Default_Move:new()

-- helper to get the move skill for a pawn, since we use it in multiple places
-- making it public will also help modders use it
function Move.GetPawnMoveSkill()
	local pawnType = Pawn:GetType()
	local moveSkill = _G[pawnType].MoveSkill

	if type(moveSkill) == 'string' then
		assertIsStringToSkillTable(moveSkill, string.format("%s.moveSkill = %q", pawnType, tostring(moveSkill)))

		moveSkill = _G[moveSkill]
	end

	return moveSkill
end

local oldMoveGetTargetArea = Move.GetTargetArea
function Move:GetTargetArea(point)
	local pawnType = Pawn:GetType()
	local moveSkill = Move.GetPawnMoveSkill()

	if moveSkill ~= nil and moveSkill.GetTargetArea ~= nil then
		return moveSkill:GetTargetArea(point)
	end

	return oldMoveGetTargetArea(self, point)
end


local oldMoveGetSkillEffect = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2)
	local pawnType = Pawn:GetType()
	local moveSkill = Move.GetPawnMoveSkill()

	if moveSkill ~= nil and moveSkill.GetSkillEffect ~= nil then
		local ret = moveSkill:GetSkillEffect(p1, p2)
		-- unless they opt out, add in Adjacent_Heal and Web_Vek, prevents old custom move skills from breaking
		-- if their GetSkillEffect is the default logic, that means they extended Default_Move without modifying GetSkillEffect, so they alreay got post move effects
		if not moveSkill.SkipPostMoveEffects then
			Move.DoPostMoveEffects(moveSkill, ret, p1, p2)
		end
		return ret
	end

	-- old move skill will call DoPostMoveEffects directly
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

modApi.events.onFrameDrawStart:subscribe(function()
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
	-- This would remove the need for ModsInitialized event here, but what about newly added
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

-------------------------------------------------------------
--- Override all Pawns' GetIsPortrait to implement
--- pawn unfocuesd & focused hooks.
-------------------------------------------------------------

local focusedPawnLast = nil
local focusedPawnCurrent = nil
local selectedPawnIdLast = nil
local function buildGetIsPortraitOverride(pawn)
	local originalFn = pawn.GetIsPortrait

	return function(self, ...)
		focusedPawnCurrent = self

		return originalFn(self, ...)
	end
end

modApi.events.onFrameDrawStart:subscribe(function()
	local selectedPawnIdCurrent = Board and Board:GetSelectedPawnId() or nil

	if Game and selectedPawnIdCurrent ~= selectedPawnIdLast then
		if selectedPawnIdLast then
			modApi:firePawnDeselectedHooks(Game:GetPawn(selectedPawnIdLast))
		end

		if selectedPawnIdCurrent then
			modApi:firePawnSelectedHooks(Game:GetPawn(selectedPawnIdCurrent))
		end
	end

	if focusedPawnCurrent ~= focusedPawnLast or selectedPawnIdCurrent ~= selectedPawnIdLast then
		if focusedPawnLast then
			modApi:firePawnUnfocusedHooks(focusedPawnLast)
		end

		if focusedPawnCurrent then
			modApi:firePawnFocusedHooks(focusedPawnCurrent)
		end
	end

	selectedPawnIdLast = selectedPawnIdCurrent
	focusedPawnLast = focusedPawnCurrent
	focusedPawnCurrent = nil
end)

local function overridePawnFunction(pawn, functionName, fn)
	Assert.Equals("table", type(pawn), "Argument #1")
	Assert.Equals(
			"function", type(pawn.GetIsPortrait),
			string.format("Argument #1 does not reference IsPortrait", pawn)
	)
	Assert.Equals("string", type(functionName), "Argument #2")
	Assert.Equals("function", type(fn), "Argument #3")

	pawn[functionName] = fn
end

local function overrideAllPawns()
	for k, v in pairs(_G) do
		if type(v) == "table" and v.GetIsPortrait then
			-- Make it possible to identify pawns with no ambiguity
			v.__Id = k

			overridePawnFunction(v, "GetIsPortrait", buildGetIsPortraitOverride(v))
		end
	end
end

modApi.events.onModsInitialized:subscribe(function()
	-- Defer the call until all mods have been loaded, so that they don't break the detection
	overrideAllSkills()
	overrideAllPawns()
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

function modApi:getFocusedPawn()
	return focusedPawnLast
end

function modApi:isPawnFocused(id)
	Assert.Equals("string", type(id), "Argument #1")
	return focusedPawnLast and focusedPawnLast.__Id == id
end

function modApi:isAnyPawnFocused()
	return focusedPawnLast ~= nil
end
