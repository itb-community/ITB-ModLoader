
FinalEnemyList = FinalEnemyList or {
	"Firefly", "Hornet", "Scarab", "Scorpion",
	"Crab", "Beetle", "Digger", "Blobber",
	"Jelly_Lava", "Jelly_Lava", "Jelly_Lava" --make it more likely
}

local oldGetSpawnList = GameObject.GetSpawnList
function GameObject:GetSpawnList(island)
	local result = oldGetSpawnList(self, island)
	
	if island == 5 then -- final island!
		result = FinalEnemyList
	end
	
	return result
end

EnemyLists.Bots = EnemyLists.Bots or {"Snowtank", "Snowlaser", "Snowart"}

function Mission:NextRobot(name_only)
	name_only = name_only or false
	return self:NextPawn(EnemyLists.Bots, name_only)
end

-- Mission_Stasis has hard coded its bot table.
-- Doing a full override to use our new bot table.
function Mission_Stasis:StartMission()
	local choices = {}
	self.Bots = {}
	
	for i = 3, 6 do
		for j = 1, 6 do
			if 	not Board:IsBlocked(Point(i,j),PATH_GROUND) then
				choices[#choices+1] = Point(i,j)
			end
		end
	end
	
	if #choices < 2 then
		LOG("Didn't find locations for stasis bots")
		return
	end
	
	local levels = {"1", "2"}
	if GetSector() > 2 then
		levels = {"2", "2"}
	end
	
	for i = 1, 2 do
		local pawn = PAWN_FACTORY:CreatePawn(random_element(EnemyLists.Bots)..levels[i])
		local choice = random_removal(choices)
		self.Bots[i] = pawn:GetId()
		Board:AddPawn(pawn,choice)
		--pawn:SetPowered(false)
		pawn:SetFrozen(true)
		pawn:SetMissionCritical(true)
	end
end
