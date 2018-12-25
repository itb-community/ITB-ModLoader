
local oldGetDifficulty = GetDifficulty
function GetDifficulty()
	if Game and GAME and GAME.CustomDifficulty then
		return GAME.CustomDifficulty
	else
		local customDiff = modApi:readModData("CustomDifficulty")
		if customDiff then
			return customDiff
		end
	end

	return oldGetDifficulty()
end

-- /////////////////////////////////////////////////////////////////////////////////////
-- Tweak existing code to work with custom difficulty levels
-- Replacing instances of GetDifficulty() with GetBaselineDifficulty()

function Mission_Final:StartMission()
	self:GetSpawner():SetSpawnIsland(5)
	local pylons = extract_table(Board:GetZone("pylons"))
	for i,v in ipairs(pylons) do
		Board:BlockSpawn(v,BLOCKED_PERM)
	end
	
	if GetBaselineDifficulty() == DIFF_HARD then
		Board:SpawnPawn(random_element(self.BossList))
	end
end

function getEnvironmentChance(sectorType, tileType)
	--numbers are just a raw percentage chance
	--example: TERRAIN_FOREST = 10 means 10% chance any plain tile will become Forest
	if sectorType == "lava" or sectorType == "volcano" then
		return 0
	end
	
	if tileType == TERRAIN_ACID then
		if sectorType == "acid" then
			return random_element({0,0,10,20})
		else
			return 0
		end
	end
	
	-- "normal" mode uses the same numbers as "hard"
	
	local data = { 	
		grass = { 
			--easy 
			{[TERRAIN_FOREST] = 10, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0, },
			--hard
			{[TERRAIN_FOREST] = 16, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0, },
		},
		sand = {
			--easy
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 10, [TERRAIN_ICE] = 0, },
			--hard
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 16, [TERRAIN_ICE] = 0, },
		},
		snow = {
			--easy
			{ [TERRAIN_FOREST] = 10, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 75,  },
			--hard
			{ [TERRAIN_FOREST] = 10, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 75,  },
		},
		acid = {
			--easy
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0,},
			--hard
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0,   },
		}
	}

	--translate easy => 1, normal or hard => 2
	local difficulty = (GetBaselineDifficulty() == DIFF_EASY) and 1 or 2
	
	--haha this is ugly
	if data[sectorType] ~= nil and data[sectorType][difficulty] ~= nil and data[sectorType][difficulty][tileType] ~= nil then
		return data[sectorType][difficulty][tileType]
	else
		LOG("Failed environment chance: terrain = "..sectorType..", tile = "..tileType)
		return 0
	end
end

function Mission_SpiderBoss:SpawnSpiderlings()
	if self:IsBossDead() then
		return
	end
	
	if Board:GetPawn(self.BossID):IsFrozen() then
		return
	end
	
	if self.EggCount == -1 or GetBaselineDifficulty() == DIFF_EASY then
		self.EggCount = 2
	else
		self.EggCount = self.EggCount == 2 and 3 or 2
	end
	
	local proj_info = { image = "effects/shotup_spider.png", launch = "/enemy/spider_boss_1/attack_egg_launch", impact = "/enemy/spider_boss_1/attack_egg_land" }
	return self:FlyingSpawns(Board:GetPawnSpace(self.BossID),self.EggCount,"SpiderlingEgg1",proj_info)
end

function Mission:GetKillBonus()
	if GetBaselineDifficulty() == DIFF_EASY then
		return 5
	else
		return 7
	end
end

function Mission:GetStartingPawns()
	local spawnCount = self.SpawnStart
	
	if GetBaselineDifficulty() == DIFF_EASY and self.SpawnStart_Easy ~= -1 then
		spawnCount = self.SpawnStart_Easy
	end

	local mod = self.GlobalSpawnMod + self.SpawnStartMod
	local count = 0
	if type(spawnCount) == "table" then
		local sector = math.max(1,math.min(GetSector(),#spawnCount))
		count = spawnCount[sector]
	else
		count = spawnCount
	end
	
	local new_count = count + mod
			
	return math.max(0,new_count)
end

function Mission:GetSpawnsPerTurn()
	local spawnCount = copy_table(self.SpawnsPerTurn)
	
	if GetBaselineDifficulty() == DIFF_EASY and self.SpawnsPerTurn_Easy ~= -1 then
		spawnCount = copy_table(self.SpawnsPerTurn_Easy)
	end
	
	if type(spawnCount) ~= "table" then
		spawnCount = {spawnCount, spawnCount}
	end
	
	local mod = self.GlobalSpawnMod + self.SpawnMod
	
	while mod ~= 0 do
		local curr = getMinIndex(spawnCount)
		if subsign(mod) < 0 then
			curr = getMaxIndex(spawnCount)
		end
		
		spawnCount[curr] = math.max(1,spawnCount[curr] + subsign(mod))
		
		mod = mod - subsign(mod)
	end
	
	local spawns = " {"
	for i = 1, #spawnCount do
		spawns = spawns..spawnCount[i]..","
	end
	spawns = spawns.."}"
	--LOG("Modified spawns per turn: "..spawns)
	
	return spawnCount
end

function Mission:GetMaxEnemy()
	if GetBaselineDifficulty() == DIFF_EASY and self.MaxEnemy_Easy ~= -1 then
		return self.MaxEnemy_Easy
	else
		return self.MaxEnemy
	end
end

function Mission:GetSpawnCount()
	if not self.InfiniteSpawn then return 0 end
	
	if self:IsFinalTurn() then return 0 end
	
	--LOG("Turn counter: "..Game:GetTurnCount())
	
	local spawnCount = self:GetSpawnsPerTurn()

--	LOG("Current index: "..(Game:GetTurnCount() % #spawnCount) + 1)
	spawnCount = spawnCount[(Game:GetTurnCount() % #spawnCount) + 1]
	
	local enemies = Board:GetPawnCount(TEAM_ENEMY_MAJOR)
	local all_enemies = Board:GetPawnCount(TEAM_ENEMY)
	
--	LOG("All enemy count = "..all_enemies)
--	LOG("Enemy count = "..enemies)
	--LOG("Enemy max = "..self:GetMaxEnemy())
	--LOG("Spawn goal = "..spawnCount)
	
	if enemies <= 2 and all_enemies <= 3 and spawnCount < 3 and GetBaselineDifficulty() ~= DIFF_EASY then
		LOG("2 or less enemies present. Increasing spawn count")
		spawnCount = spawnCount + 1
	end
	
	spawnCount = math.min(math.max(0,self:GetMaxEnemy() - enemies), spawnCount)
	LOG("Final spawn = "..spawnCount)
	
	return spawnCount
end