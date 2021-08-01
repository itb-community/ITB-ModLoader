
HOTKEY = {
	MUTE = 1,
	UNDO_MOVE = 2,
	RESET_TURN = 3,
	SELECT_MECH1 = 4,
	SELECT_MECH2 = 5,
	SELECT_MECH3 = 6,
	SELECT_DEPLOYED1 = 7,
	SELECT_DEPLOYED2 = 8,
	SELECT_DEPLOYED3 = 9,
	SELECT_MISSION_UNIT1 = 13,
	SELECT_MISSION_UNIT2 = 14,
	CYCLE_UNITS = 15,
	DESELECT_WEAPON = 16,
	INFO_OVERLAY = 17,
	ATTACK_ORDER_OVERLAY = 18,
	WEAPON1 = 19,
	WEAPON2 = 20,
	REPAIR = 21,
	END_TURN = 22,
	TOGGLE_FULLSCREEN = 23
}

local keystatus = {}

modApi.hotkey = {
	keys = {},
	suppressed = {},
	hooks_down = {},
	hooks_up = {}
}

function modApi.hotkey:resetHooks()
	self.hooks_down = {}
	self.hooks_up = {}
end

modApi.events.onSettingsInitialized:subscribe(function(settings)
	Assert.Equals("table", type(settings))
	modApi.hotkey.keys = settings.hotkeys
end)

modApi.events.onSettingsChanged:subscribe(function(oldSettings, newSettings)
	modApi.hotkey.keys = newSettings.hotkeys
end)

modApi.events.onKeyPressed:subscribe(function(keycode)
	local index = list_indexof(modApi.hotkey.keys, keycode)
	if sdlext.isConsoleOpen() then return false end
	if index == -1 then return false end
	
	if modApi.hotkey.hooks_down[index] then
		for _, v in ipairs(modApi.hotkey.hooks_down[index]) do
			v.fn(unpack(v.params))
		end
	end
	
	keystatus[index] = true
	
	if modApi.hotkey.suppressed[index] then
		return true
	end
	
    return false
end)

modApi.events.onKeyReleased:subscribe(function(keycode)
	local index = list_indexof(modApi.hotkey.keys, keycode)
	if index == -1 then return false end
	if not keystatus[index] then return false end
	
	if modApi.hotkey.hooks_up[index] then
		for _, v in ipairs(modApi.hotkey.hooks_up[index]) do
			v.fn(unpack(v.params))
		end
	end
	
	keystatus[index] = nil
	
	return false
end)

function modApi:suppressHotkey(keyIndex, suppress)
	Assert.Equals('number', type(keyIndex), "Argument #1")
	Assert.Range(1, 23, keyIndex, "Argument #1")
	Assert.Equals({'nil', 'boolean'}, type(suppress), "Argument #2")
	
	suppress = suppress ~= false
	if suppress then
		if keyIndex then
			modApi.hotkey.suppressed[keyIndex] = true
		else
			for i = 1, 23 do
				modApi.hotkey.suppressed[i] = true
				keystatus[i] = false -- release key
			end
		end
	else
		if keyIndex then
			modApi.hotkey.suppressed[keyIndex] = nil
		else
			modApi.hotkey.suppressed = {}
		end
	end
end

function modApi:unsuppressHotkey(keyIndex)
	self:suppressHotkey(keyIndex, false)
end

function modApi:addHotkeyDownHook(keyIndex, fn, ...)
	Assert.Equals('number', type(keyIndex), "Argument #1")
	Assert.Range(1, 23, keyIndex, "Argument #1")
	Assert.Equals('function', type(fn), "Argument #2")
	
	modApi.hotkey.hooks_down[keyIndex] = modApi.hotkey.hooks_down[keyIndex] or {}
	table.insert(modApi.hotkey.hooks_down[keyIndex], {fn = fn, params = {...}})
end

function modApi:addHotkeyUpHook(keyIndex, fn, ...)
	Assert.Equals('number', type(keyIndex), "Argument #1")
	Assert.Range(1, 23, keyIndex, "Argument #1")
	Assert.Equals('function', type(fn), "Argument #2")
	
	modApi.hotkey.hooks_up[keyIndex] = modApi.hotkey.hooks_up[keyIndex] or {}
	table.insert(modApi.hotkey.hooks_up[keyIndex], {fn = fn, params = {...}})
end

function modApi:remHotkeyDownHook(keyIndex, fn)
	Assert.Equals('number', type(keyIndex), "Argument #1")
	Assert.Range(1, 23, keyIndex, "Argument #1")
	Assert.Equals('function', type(fn), "Argument #2")
	
	local hooks = modApi.hotkey.hooks_down[keyIndex]
	if hooks then
		for i, v in ipairs(hooks) do
			if v.fn == fn then
				table.remove(hooks, i)
				break
			end
		end
	end
end

function modApi:remHotkeyUpHook(keyIndex, fn)
	Assert.Equals('number', type(keyIndex), "Argument #1")
	Assert.Range(1, 23, keyIndex, "Argument #1")
	Assert.Equals('function', type(fn), "Argument #2")
	
	local hooks = modApi.hotkey.hooks_up[keyIndex]
	if hooks then
		for i, v in ipairs(hooks) do
			if v.fn == fn then
				table.remove(hooks, i)
				break
			end
		end
	end
end

function modApi:isHotkeyDown(keyIndex)
	Assert.Equals('number', type(keyIndex), "Argument #1")
	Assert.Range(1, 23, keyIndex, "Argument #1")
	
	return keystatus[keyIndex] == true
end

function modApi:isHotkeyUp(keyIndex)
	Assert.Equals('number', type(keyIndex), "Argument #1")
	Assert.Range(1, 23, keyIndex, "Argument #1")
	
	return keystatus[keyIndex] ~= true
end
