-- These hooks are special in that they're fired only once and then cleared, so we can safely reimplement them as events.

function modApi:addModsInitializedHook(fn)
	return modApi.events.onModsInitialized:subscribe(fn)
end
function modApi:remModsInitializedHook(fn)
	return modApi.events.onModsInitialized:unsubscribe(fn)
end

function modApi:addModsFirstLoadedHook(fn)
	return modApi.events.onModsFirstLoaded:subscribe(fn)
end
function modApi:remModsFirstLoadedHook(fn)
	return modApi.events.onModsFirstLoaded:unsubscribe(fn)
end
