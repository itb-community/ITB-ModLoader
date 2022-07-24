-- Attempt to nuke FURL and replace it with functions provided by the mod loader

local function isFURLMod(modScriptPath)
    return modApi:fileExists(modScriptPath .. "FURL.lua")
end

local function isModLoaderFURLCompatApplied(modScriptPath)
    -- Mark mods that we've fixed, so that we don't try to re-apply the fix.
    local markerPath = modScriptPath .. ".furl-compat"
    return modApi:fileExists(markerPath)
end

modApi.events.onModEnumerating:subscribe(function(modDir)
    local modScriptPath = modDir .. "scripts/"
    if not isModLoaderFURLCompatApplied(modScriptPath) and isFURLMod(modScriptPath) then
        modApi:writeFile(
            modScriptPath .. "FURL.lua",
            [[
return function(mod, table)
    HandleFURLCall(mod, table)
end
            ]]
        )

        modApi:writeFile(modScriptPath .. ".furl-compat", "")
    end
end)

local function handleEnemy(mod, entry)
end

local function handleMech(mod, entry)
end

local function handleAnimation(mod, entry)
end

local function handleBase(mod, entry)
end

local function handleColor(mod, entry)
end

local function handleFURLCall(mod, table)
    for i, entry in ipairs(table) do
        local type = entry.Type or "null"
        if type == "enemy" then
            handleEnemy(mod, entry)
        elseif type == "mech" then
            handleMech(mod, entry)
        elseif type == "anim" then
            handleAnimation(mod, entry)
        elseif type == "base" then
            handleBase(mod, entry)
        elseif type == "color" then
            handleColor(mod, entry)
        else
            LOG("Error: missing or invalid type value")
        end
    end
end

HandleFURLCall = handleFURLCall
