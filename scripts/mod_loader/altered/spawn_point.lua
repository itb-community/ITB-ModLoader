
--[[
	Scan the game board and return a list of points that have a vek spawning on them.
--]]
function Mission:EnumerateSpawns()
	local result = {}
	local size = self.Board:GetSize()
	for y = 0, size.y - 1 do
		for x = 0, size.x - 1 do
			local p = Point(x, y)
			if self.Board:IsSpawning(p) then
				table.insert(result, p)
			end
		end
	end

	return result
end

--[[
	Compute the difference (complement) of two sets of elements.
	This function assumes that setA is a superset of setB.
--]]
local function setDifference(setA, setB)
	assert(setA)
	assert(setB)
	assert(type(setA) == "table")
	assert(type(setB) == "table")

	local result = {}

	-- This won't find elements in B that aren't in A, but
	-- in our case A is always a superset of B, so this is not an issue.
	for i, el in ipairs(setA) do
		if not list_contains(setB, el) then
			table.insert(result, el)
		end
	end

	return result
end

local function addSpawnData(self, location, type, id, age)
	local el = {}
	-- where the spawn is located
	el.location = location
	-- type of the enemy that will be spawned
	el.type = type
	-- id of the pawn that will be spawned
	el.id = id
	-- how long the spawn has been on the board (in case it's blocked repeatedly)
	el.turns = age or 0

	if not self.QueuedSpawns then
		-- For some reason, QueuedSpawns might be nil here somehow.
		-- Not entirely clear why that happens.
		self.QueuedSpawns = {}
	end

	-- Vek surface in the order defined in this table, but spawn points
	-- appear on the board in reverse order.
	table.insert(self.QueuedSpawns, el)

	if self.Initialized then
		-- Don't trigger the hooks when missions become available
		for i, hook in ipairs(modApi.vekSpawnAddedHooks) do
			hook(self, el)
		end
	end
end

function Mission:SpawnPawnInternal(location, pawn)
	self.Board:SpawnPawn(pawn, location)
	addSpawnData(self, location, pawn:GetType(), pawn:GetId())
end

function Mission:PreprocessSpawningPawn(pawn)
end

function Mission:SpawnPawn(location, pawnType)
	local pawn = nil
	if type(pawnType) == "string" then
		pawn = PAWN_FACTORY:CreatePawn(pawnType)
	elseif type(pawnType) == "userdata" and type(pawnType.GetId) == "function" then
		pawn = pawnType
	elseif not pawnType then
		pawn = self:NextPawn()
	end

	local newLocation = self:PreprocessSpawningPawn(pawn)

	if newLocation then
		location = newLocation
	end

	if location then
		self:SpawnPawnInternal(location, pawn)
	else
		local spawnsStart = self:EnumerateSpawns()

		-- Defer to the game's spawning point-selection logic
		self.Board:SpawnPawn(pawn)

		-- We have access to the pawn instance here, but its GetSpace()
		-- function returns (-1, -1), so we can't use it to identify its
		-- spawn location...
		-- Next best thing is enumerating all spawn locations, and then
		-- finding the element that was added.
		local spawnsEnd = self:EnumerateSpawns()
		local diff = setDifference(spawnsEnd, spawnsStart)

		addSpawnData(self, diff[1], pawn:GetType(), pawn:GetId())
	end
end

function Mission:SpawnPawns(count)
	for i = 1, count do
		if self.Initialized then
			-- Spawns appear roughly one second apart
			modApi:scheduleHook((i - 1) * 1000, function() self:SpawnPawn() end)
		else
			-- Initial spawning of enemies when the mission is created, don't space them out
			-- so that the spawning points don't pop up one by one in the mission preview
			self:SpawnPawn()
		end
	end
end

--[[
	Returns spawn data of the specified point, or nil if there's no Vek spawning
	at that location.
--]]
function Mission:GetSpawnPointData(point)
	local spawn = nil
	for i, e in ipairs(self.QueuedSpawns) do
		if e.location == point then
			spawn = e
			break
		end
	end

	return spawn
end

--[[
	Removes the vek spawn at the specified location. The vek that was
	supposed to be spawned will not appear.
	Has no effect if the specified location is not an existing spawn point.
--]]
function Mission:RemoveSpawnPoint(point)
	if self:GetSpawnPointData(point) then
		local terrain = self.Board:GetTerrain(point)
		local smoke = self.Board:IsSmoke(point)
		local acid = self.Board:IsAcid(point)
		local fire = self.Board:IsFire(point)

		local pawn = self.Board:GetPawn(point)
		if pawn then
			pawn:SetSpace(Point(-1, -1))
		end

		self.Board:SetTerrain(point, TERRAIN_HOLE)

		-- Need to delay terrain restoration so that a single update tick happens,
		-- and the game removes the spawn point
		modApi:runLater(function()
			self.Board:SetTerrain(point, terrain)
			self.Board:SetSmoke(point, smoke, false)
			self.Board:SetAcid(point, acid)
			if fire then
				local d = SpaceDamage(point)
				d.iFIRE = EFFECT_CREATE
				self.Board:DamageSpace(d)
			end

			if pawn then
				pawn:SetSpace(point)
			end

			self:UpdateQueuedSpawns()
		end)
	end
end

--[[
	Moves the specified spawn point to the specified location.
	Has no effect if the specified location is not an existing spawn point.
--]]
function Mission:MoveSpawnPoint(point, newLocation)
	self:ModifySpawnPoint(point, { location = newLocation })
end

--[[
	Changes the type of pawn that will be spawned at the specfiied location.
	Has no effect if the specified location is not an existing spawn point.
--]]
function Mission:ChangeSpawnPointPawnType(point, newPawnType)
	self:ModifySpawnPoint(point, { type = newPawnType })
end

function Mission:ModifySpawnPoint(point, newSpawnData)
	assert(newSpawnData)
	assert(type(newSpawnData) == "table")

	local spawn = self:GetSpawnPointData(point)

	if spawn then
		newSpawnData.type = newSpawnData.type or spawn.type
		newSpawnData.location = newSpawnData.location or spawn.location
		newSpawnData.turns = newSpawnData.turns or spawn.turns

		self:RemoveSpawnPoint(point)

		local id = self.Board:SpawnPawn(newSpawnData.type, newSpawnData.location)
		addSpawnData(self, newSpawnData.location, newSpawnData.type, id, newSpawnData.turns)
	end
end


-- Backwards compatibility
function GetSpawnPointData(point, m)
	m = m or GetCurrentMission()
	m:GetSpawnPointData(point)
end
function RemoveSpawnPoint(point, m)
	m = m or GetCurrentMission()
	m:RemoveSpawnPoint(point)
end
function MoveSpawnPoint(point, newLocation, m)
	m = m or GetCurrentMission()
	m:MoveSpawnPoint(point, newLocation)
end
function ChangeSpawnPointPawnType(point, newPawnType, m)
	m = m or GetCurrentMission()
	m:ChangeSpawnPointPawnType(point, newPawnType)
end
function ModifySpawnPoint(point, newSpawnData, m)
	m = m or GetCurrentMission()
	m:ModifySpawnPoint(point, newSpawnData)
end
