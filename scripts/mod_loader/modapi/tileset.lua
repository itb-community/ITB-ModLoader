
-- The game automatically changes the tileset used in tipimages,
-- missions and test mech scenario at various points.
-- When launching Into the Breach, it starts as "grass".
-- Exiting a run to start a new one without closing the application,
-- will not reset the current tileset.

-- Event               | Tileset
-- --------------------+--------
-- Start game          | grass
-- Enter island        | corp tileset
-- Leave island 2,3,4  | volcano
-- Select final island | volcano
-- Test mech           | corp tileset, or grass if on map screen


local currentTileset = "grass"

function modApi:getCurrentTileset()
	return currentTileset
end

local function getCurrentCorporationTileset()
	local corp = Game:GetCorp().name:sub(1, -6)
	return corp == "" and "grass" or _G[corp].Tileset
end

local function setCurrentTileset(tileset)
	local oldTileset = currentTileset

	if currentTileset ~= tileset then
		currentTileset = tileset

		modApi.events.onTilesetChanged:dispatch(tileset, oldTileset)
	end
end

-- When entering a mission;
-- the enabled tileset changes to that mission's tileset;
-- which is either a custom tileset, or that corporation's tileset.
modApi.events.onMissionChanged:subscribe(function(mission)
	if mission then
		local saveData = mission:GetSaveData()
		local missionTileset = ""

		-- If a mission has already been flagged as won,
		-- the game will not check its CustomTile variable.
		if not saveData or saveData.victory ~= 1 then
			missionTileset = mission.CustomTile:sub(7, -1)
		end

		if missionTileset == "" then
			missionTileset = getCurrentCorporationTileset()
		end

		setCurrentTileset(missionTileset)
	end
end)

modApi.events.onGameStateChanged:subscribe(function(newState, oldState)
	-- Entering an island from map or main menu changes
	-- the tileset to the current corporation's tileset
	if true
		and newState == GAME_STATE.ISLAND
		and (oldState == GAME_STATE.MAP or oldState == GAME_STATE.MAIN_MENU)
	then
		setCurrentTileset(getCurrentCorporationTileset())
	end

	-- When the final island is available;
	-- entering the map from island or main menu changes
	-- the tileset to "volcano"
	if true
		and modApi.final:isAvailable()
		and newState == GAME_STATE.MAP
		and (oldState == GAME_STATE.ISLAND or oldState == GAME_STATE.MAIN_MENU)
	then
		setCurrentTileset("volcano")
	end

	-- Entering test mech scenario changes the tileset to
	-- the current corporation's tileset.
	if newState == GAME_STATE.MISSION_TEST then
		setCurrentTileset(getCurrentCorporationTileset())
	end
end)

modApi.events.onFinalIslandSelected:subscribe(function()
	setCurrentTileset("volcano")
end)
