function modApi:addModsInitializedHook(fn)
	return modApi.events.onModsInitialized:subscribe(fn)
end

function modApi:addModsLoadedHook(fn)
	return modApi.events.onModsLoaded:subscribe(fn)
end

function modApi:addModsFirstLoadedHook(fn)
	return modApi.events.onModsFirstLoaded:subscribe(fn)
end
