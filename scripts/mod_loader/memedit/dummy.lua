
-- Dummy objects used for scanning memory.

ScanPawn = Pawn:new{}
Item_Scan = {Image = "", Damage = SpaceDamage(), Tooltip = "", Icon = "", UsedImage = ""}
ScanWeapon = Skill:new{}

function ScanWeapon:GetTargetArea(p)
	local ret = PointList()

	for i,p in ipairs(Board) do
		ret:push_back(p)
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

ScanMove = Move:new{}
ScanMove.GetTargetArea = ScanWeapon.GetTargetArea

function ScanMove:TeardownEvent()
	if self.Teardown then
		self.Teardown(self.Caller)
	end

	self.Event = nil
	self.Caller = nil
	self.Teardown = nil
end

function ScanMove:RegisterEvent(options)
	self:TeardownEvent()

	self.Event = options.Event
	self.Caller = options.Caller
	self.Teardown = options.Teardown
end

function ScanMove:GetSkillEffect(p1, p2)
	if self.Event then
		self.Event(self.Caller, p2)
	end

	local ret = SkillEffect()
	ret:AddMove(Board:GetPath(p1, p2, PATH_FLYER), FULL_DELAY)
	return ret
end
