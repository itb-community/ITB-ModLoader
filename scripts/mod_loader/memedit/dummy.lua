
-- Dummy objects used for scanning memory.

ScanPawn = Pawn:new{}
Item_Scan = {Image = "", Damage = SpaceDamage(), Tooltip = "", Icon = "", UsedImage = ""}
ScanWeapon = Skill:new{}
ScanWeaponReset = ScanWeapon:new{
	Name = "Reset Scan Pawn",
	Description = "Remove the current Scan Pawn, and retry.",
}

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

	self.TargetEvent = nil
	self.BeforeEffectEvent = nil
	self.AfterEffectEvent = nil
	self.Caller = nil
	self.Teardown = nil
end

function ScanMove:SetEvents(options)
	self:TeardownEvent()

	self.TargetEvent = options.TargetEvent
	self.BeforeEffectEvent = options.BeforeEffectEvent
	self.AfterEffectEvent = options.AfterEffectEvent
	self.Caller = options.Caller
	self.Teardown = options.Teardown
end

function ScanMove:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local pawn = Board:GetPawn(p1)

	if pawn and self.TargetEvent then
		self.TargetEvent(self.Caller, pawn, p1, p2)
	end

	if pawn then
		ret:AddScript(string.format([[
			local pawn = Board:GetPawn(%s) 
			if pawn then 
				if ScanMove.BeforeEffectEvent then 
					ScanMove.BeforeEffectEvent(ScanMove.Caller, pawn, %s, %s) 
				end 
			end
		]], pawn:GetId(), p1:GetString(), p2:GetString()))
	end

	ret:AddMove(Board:GetPath(p1, p2, PATH_FLYER), FULL_DELAY)

	if pawn then
		ret:AddScript(string.format([[
			local fx = SkillEffect() 
			fx:AddScript([=[
				local pawn = Board:GetPawn(%s) 
				if pawn then 
					if ScanMove.AfterEffectEvent then 
						ScanMove.AfterEffectEvent(ScanMove.Caller, pawn, %s, %s) 
					end 
				end
			]=]) 
			Board:AddEffect(fx)
		]], pawn:GetId(), p1:GetString(), p2:GetString()))
	end

	return ret
end
