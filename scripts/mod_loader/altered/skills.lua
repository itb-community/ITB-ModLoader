
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
