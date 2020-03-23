
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
