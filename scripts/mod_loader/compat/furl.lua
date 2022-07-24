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
        -- It seems that the only problematic part in FURL is in how it handles palettes,
        -- so we only replace that part, instead of nuking it in full.
        ReplaceFileContent(
            modScriptPath.."FURL.lua",
            "\tloadColors%(mod, object%)",
            "\tHandleFURLColor(mod, object)"
        )

        modApi:writeFile(modScriptPath .. ".furl-compat", "")
    end
end)

local function handleColor(mod, entry)
    modApi:addPalette({
        name = entry.Name,
        colorMap = {
            PlateHighlight = entry.PlateHighlight,
            PlateLight = entry.PlateLight,
            PlateMid = entry.PlateMid,
            PlateDark = entry.PlateDark,
            PlateOutline = entry.PlateOutline,
            PlateShadow = entry.PlateShadow,
            BodyColor = entry.BodyColor,
            BodyHighlight = entry.BodyHighlight
        }
    })

    FURL_COLORS[entry.Name] = GetColorCount()
end

HandleFURLColor = handleColor
