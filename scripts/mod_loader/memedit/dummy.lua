
-- Dummy objects used for scanning memory.

ScanPawn = Pawn:new{}
Item_Scan = {Image = "", Damage = SpaceDamage(), Tooltip = "", Icon = "", UsedImage = ""}
ScanWeapon = Skill:new{}

function ScanWeapon:GetTargetArea(p)
	local ret = PointList()

	for i,v in ipairs(Board) do
		ret:push_back(v)
	end

	return ret
end

function ScanWeapon:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddDamage(SpaceDamage(p2))

	return ret
end

ScanWeaponQueued = ScanWeapon:new{}

function ScanWeaponQueued:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddQueuedDamage(SpaceDamage(p2))

	return ret
end