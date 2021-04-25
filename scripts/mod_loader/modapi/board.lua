local DequeList = require("scripts/mod_loader/deque_list")

BoardClass = Board

BoardClass.MovePawnsFromTile = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")

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
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	Assert.Equals("table", type(pawnStack), "Argument #2")

	while not pawnStack:isEmpty() do
		local pawn = pawnStack:popLeft()
		pawn:SetSpace(loc)
	end
end

BoardClass.SetFire = function(self, loc, fire)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	Assert.Equals("boolean", type(fire), "Argument #2")

	local pawnStack = self:MovePawnsFromTile(loc)

	local dmg = SpaceDamage(loc)
	dmg.iFire = fire and EFFECT_CREATE or EFFECT_REMOVE
	self:DamageSpace(dmg)

	self:RestorePawnsToTile(loc, pawnStack)
end

BoardClass.SetShield = function(self, loc, shield)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	Assert.Equals("boolean", type(shield), "Argument #2")

	local dmg = SpaceDamage(loc)
	dmg.iShield = shield and EFFECT_CREATE or -1
	self:DamageSpace(dmg)
end

BoardClass.GetLuaString = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	local size = self:GetSize()
	return string.format("Board [width = %s, height = %s]", size.x, size.y)
end
BoardClass.GetString = BoardClass.GetLuaString

BoardClass.IsMissionBoard = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	return self.isMission == true
end

BoardClass.IsTipImage = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	return self.isMission == nil
end

BoardClass.GetHighlighted = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	if GetCurrentMission() == nil then
		return
	end
	
	return mouseTile()
end

BoardClass.IsHighlighted = function(self, loc)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.TypePoint(loc, "Argument #1")
	
	if GetCurrentMission() == nil then
		return
	end
	
	return loc == mouseTile()
end

BoardClass.GetSelectedPawn = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	local pawns = Board:GetPawns(TEAM_ANY)
	for i = 1, pawns:size() do
		local pawn = Board:GetPawn(pawns:index(i))
		if pawn and pawn:IsSelected() then
			return pawn
		end
	end
	
	return nil
end

BoardClass.GetSelectedPawnId = function(self)
	local selectedPawn = self:GetSelectedPawn()
	
	if selectedPawn then
		return selectedPawn:GetId()
	end
	
	return nil
end
