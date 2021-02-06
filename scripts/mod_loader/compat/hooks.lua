function modApi:addModsInitializedHook(fn)
	return modApi.events.onModsInitialized:subscribe(fn)
end
function modApi:remModsInitializedHook(fn)
	return modApi.events.onModsInitialized:unsubscribe(fn)
end

function modApi:addModsLoadedHook(fn)
	return modApi.events.onModsLoaded:subscribe(fn)
end
function modApi:remModsLoadedHook(fn)
	return modApi.events.onModsLoaded:unsubscribe(fn)
end

function modApi:addModsFirstLoadedHook(fn)
	return modApi.events.onModsFirstLoaded:subscribe(fn)
end
function modApi:remModsFirstLoadedHook(fn)
	return modApi.events.onModsFirstLoaded:unsubscribe(fn)
end
