local itb_rs_lua = nil

local function lazy_load()
	if itb_rs_lua ~= nil then
		return
	end

	try(function()
		LOG("Loading itb_rs_lua.dll...")
		package.loadlib("itb_rs_lua.dll", "luaopen_itb_rs")()
		itb_rs_lua = itb_rs
		itb_rs = nil
		LOG("Successfully loaded itb_rs_lua.dll!")
	end)
	:catch(function(err)
		error(string.format(
				"Failed to load itb_rs_lua.dll: %s",
				tostring(err)
		))
	end)
end

function load_itb_rs_lua_bridge()
	lazy_load()
	return itb_rs_lua
end
