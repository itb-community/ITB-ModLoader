
GAME_STATE = {
	MAIN_MENU = "Main_Menu",
	HANGAR = "Hangar",
	END_GAME_SCREEN = "End_Game_Screen",
	MAP = "Map",
	ISLAND = "Island",
	MISSION = "Mission",
	MISSION_TEST = "Mission_Test",
}

local currentGameState = GAME_STATE.MAIN_MENU

function modApi:getGameState()
	return currentGameState
end

-- Check current sector each frame. If an increment is detected,
-- it means we have left an island. When leaving the 4th island,
-- sector does not increase, so no event is dispatched.
-- Event onGameStateChanged can be used to detect when the island
-- has been fully left, when it is reflected in the save data.
modApi.events.onFrameDrawStart:subscribe(function()
	if not Game or not GAME then
		return
	end

	local sector = Game:GetSector()

	if GAME.currentSector == nil then
		GAME.currentSector = sector
	elseif GAME.currentSector < sector then
		GAME.currentSector = sector

		modApi.events.onIslandLeft:dispatch(GAME.Island)
	end
end)

local function setGameState(gameState)
	local oldGameState = currentGameState

	if currentGameState ~= gameState then
		currentGameState = gameState

		if GAME then
			if currentGameState == GAME_STATE.ISLAND or currentGameState == GAME_STATE.MAP then
				-- fallbackGameState is either map or island.
				-- When exiting a mission, or entering the game outside of a mission,
				-- we will fall back to either of the two.
				GAME.fallbackGameState = currentGameState
			end
			GAME.currentGameState = currentGameState
		end

		modApi.events.onGameStateChanged:dispatch(currentGameState, oldGameState)
	end
end

modApi.events.onMainMenuEntered:subscribe(function()
	setGameState(GAME_STATE.MAIN_MENU)
end)

modApi.events.onHangarEntered:subscribe(function()
	setGameState(GAME_STATE.HANGAR)
end)

modApi.events.onGameExited:subscribe(function()
	if not sdlext.isMainMenu() then
		setGameState(GAME_STATE.END_GAME_SCREEN)
	end
end)

modApi.events.onGameEntered:subscribe(function()
	if GAME.currentGameState == nil or GAME.currentGameState == GAME_STATE.MISSION_TEST then
		setGameState(GAME.fallbackGameState or GAME_STATE.MAP)
	else
		setGameState(GAME.currentGameState)
	end
end)

modApi.events.onPreIslandSelection:subscribe(function()
	setGameState(GAME_STATE.ISLAND)
end)

modApi.events.onIslandLeft:subscribe(function()
	setGameState(GAME_STATE.MAP)
end)

modApi.events.onMissionChanged:subscribe(function(mission, oldMission)
	if mission == Mission_Test then
		setGameState(GAME_STATE.MISSION_TEST)
	elseif mission then
		setGameState(GAME_STATE.MISSION)
	elseif sdlext.isGame() then
		setGameState(GAME.fallbackGameState)
	end
end)
