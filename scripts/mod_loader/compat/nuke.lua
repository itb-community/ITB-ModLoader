
-- nuke libraries that have been migrated to the mod loader

SquadEvents = { version = tostring(INT_MAX) }
DifficultyEvents = { version = tostring(INT_MAX) }

modApi.events.onRealDifficultyChanged = modApi.events.onDifficultyChanged
