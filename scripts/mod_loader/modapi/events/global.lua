
modApi:newEvent("GameLoaded")
modApi:newEvent("preGameLoaded")
modApi:newEvent("postGameLoaded")
modApi:newEvent("GameSaved")
modApi:newEvent("preGameSaved")
modApi:newEvent("postGameSaved")

modApi:addEventTriggers(_G, 'LoadGame', "GameLoaded")
modApi:addEventTriggers(_G, 'SaveGame', "GameSaved")
