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

	if shield then
		self:AddShield(loc)
	else
		self:RemoveShield(loc)
	end
end

-- gets the currently active psion on the board, returns a value from the LEADER globals if found, nil if not
BoardClass.GetMutation = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local enemies = self:GetPawns(TEAM_ENEMY)
	-- scan the board for a psion, if found return its effect
	-- note that when multiple psions exist, the mutation is the newest psion, this is consistent with the game logic
	-- this also may give inaccurate results in the mech tester, as spawning a psion does not update mutations there
	for i = enemies:size(), 1, -1 do
		local leader = _G[self:GetPawn(enemies:index(i)):GetType()]:GetLeader()
		if leader ~= LEADER_NONE then
			return leader
		end
	end
	return nil
end

-- checks if the given mutation is active on the board. Note that for health, regen, and explision, returns true for th especific psion and the boss
BoardClass.IsMutation = function(self, predicate)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("number", type(predicate), "Argument #1")

	-- for boss psions, return true if any of the three were passed as the argument
	local mutation = self:GetMutation()
	return mutation == predicate or (mutation == LEADER_BOSS and (predicate == LEADER_HEALTH or predicate == LEADER_REGEN or predicate == LEADER_EXPLODE))
end

BoardClass.GetLuaString = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	local size = self:GetSize()
	return string.format("Board [width = %s, height = %s]", size.x, size.y)
end
BoardClass.GetString = BoardClass.GetLuaString

BoardClass.IsMissionBoard = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	return self:GetSize() ~= Point(6,6)
end

BoardClass.IsTipImage = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	return self:GetSize() == Point(6,6)
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

BoardClass.GetTile = function(self, predicateFn)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("function", type(predicateFn), "Argument #1")

	for _, p in ipairs(self) do
		if predicateFn(p) then
			return p
		end
	end

	return nil
end

BoardClass.GetTiles = function(self, predicateFn)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals({"nil", "function"}, type(predicateFn), "Argument #1")

	local result = PointList()

	for _, p in ipairs(self) do
		if not predicateFn or (predicateFn and predicateFn(p)) then
			result:push_back(p)
		end
	end

	return result
end

BoardClass.__ipairs = function(self, ...)
	Assert.Equals("userdata", type(self), "Argument #0")

	local index = 0
	local size = self:GetSize()
	return function()
		if index < size.x * size.y then
			index = index + 1
			return index, index2point(index)
		end
	end
end


local boardClass = BoardClass
local boardInitialized = false

local function initializeBoardClass(board)
	boardInitialized = true


	-- Override existing Board class functions here


	modApi.events.onBoardClassInitialized:dispatch(boardClass, board)
	modApi.events.onBoardClassInitialized:unsubscribeAll()

	boardClass = nil
end

local oldSetBoard = SetBoard
function SetBoard(board)
	if true
		and board ~= nil
		and boardInitialized == false
	then
		initializeBoardClass(board)
	end

	oldSetBoard(board)
end
