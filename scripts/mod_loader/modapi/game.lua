
local gameClass = GameMap
local gameInitialized = false


local function initializeGameClass(game)
	gameInitialized = true


	-- Override existing Game class functions here


	modApi.events.onGameClassInitialized:dispatch(gameClass, game)
	modApi.events.onGameClassInitialized:unsubscribeAll()

	gameClass = nil
end

local oldSetGame = SetGame
function SetGame(game)
	if true
		and game ~= nil
		and gameInitialized == false
	then
		initializeGameClass(game)
	end

	oldSetGame(game)
end
