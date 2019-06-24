local DequeList = require("scripts/mod_loader/deque_list")

BoardClass = Board

BoardClass.MovePawnsFromTile = function(self, loc)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertTypePoint(loc, "Argument #1")

	-- In case there are multiple pawns on the same tile
	local pawnStack = DequeList()
	local point = Point(-1, -1)

	while self:IsPawnSpace(loc) do
		local pawn = self:GetPawn(loc)
		pawnStack:pushLeft(pawn)
		pawn:SetSpace(point)
	end

	return pawnStack
end

BoardClass.RestorePawnsToTile = function(self, loc, pawnStack)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertTypePoint(loc, "Argument #1")
	Tests.AssertEquals("table", type(pawnStack), "Argument #2")

	while not pawnStack:isEmpty() do
		local pawn = pawnStack:popLeft()
		pawn:SetSpace(loc)
	end
end

BoardClass.SetFire = function(self, loc, fire)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertTypePoint(loc, "Argument #1")
	Tests.AssertEquals("boolean", type(fire), "Argument #2")

	local pawnStack = self:MovePawnsFromTile(loc)

	local dmg = SpaceDamage(loc)
	dmg.iFire = fire and EFFECT_CREATE or EFFECT_REMOVE
	self:DamageSpace(dmg)

	self:RestorePawnsToTile(loc, pawnStack)
end

BoardClass.SetShield = function(self, loc, shield)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertTypePoint(loc, "Argument #1")
	Tests.AssertEquals("boolean", type(shield), "Argument #2")

	local dmg = SpaceDamage(loc)
	dmg.iShield = shield and EFFECT_CREATE or EFFECT_REMOVE
	self:DamageSpace(dmg)
end

BoardClass.GetLuaString = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	local size = self:GetSize()
	return string.format("Board [width = %s, height = %s]", size.x, size.y)
end
BoardClass.GetString = BoardClass.GetLuaString

BoardClass.IsMissionBoard = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	return self.isMission == true
end

BoardClass.IsTipImage = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	return self.isMission == nil
end

BoardClass.GetHighlighted = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	if GetCurrentMission() == nil then
		return
	end
	
	return mouseTile()
end

BoardClass.IsHighlighted = function(self, loc)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertEquals("userdata", type(loc), "Argument #1")
	
	if GetCurrentMission() == nil then
		return
	end
	
	return loc == mouseTile()
end
