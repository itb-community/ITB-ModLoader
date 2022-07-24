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

local function handleFURLCall(mod, table)
    LOG("--- MOD LOADER FURL COMPAT ---")
    for i, entry in ipairs(table) do
        local type = entry.Type or "null"
        if type == "enemy" then
            -- handle vek
        elseif type == "mech" then
            -- handle mech
        elseif type == "anim" then
            -- handle animation
        elseif type == "base" then
            -- handle base
        elseif type == "color" then
            -- handle color
        else
            LOG("Error: missing or invalid type value")
        end
    end
end

HandleFURLCall = handleFURLCall
