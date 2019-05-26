
-- //////////////////////////////////////////////////////////////////////////////
-- Map handling

function modApi:fileExists(name)
	assert(type(name) == "string", "Expected a string, got: "..type(name))

	local f = io.open(name, "rb")

	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

function modApi:writeFile(path, content)
	assert(type(path) == "string")
	assert(type(content) == "string")

	local f = io.open(path, "w")
	assert(f, "Unable to open " .. path)
	f:write(content)
	f:close()
end

function modApi:copyFile(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	local input = io.open(src, "r")
	assert(input, "Unable to open " .. src)
	local content = input:read("*a")
	input:close()

	local output = io.open(dst, "w")
	assert(output, "Unable to open " .. dst)
	output:write(content)
	output:close()
end

function modApi:pruneExtension(filename)
	-- gsub() returns multiple values, store the first
	-- value in a variable so that we correctly ignore
	-- the retvalues that come after it.
	local r = string.gsub(filename, "\.[^.]*$", "")
	return r
end

--[[
	Returns a list of names of all *.map files in maps/ directory,
	without the .map extension
--]]
function modApi:getMapsList()
	local list = {}

	for i, file in pairs(os.listfiles("maps")) do
		if modApi:stringEndsWith(file, ".map") then
			table.insert(list, self:pruneExtension(file))
		end
	end

	return list
end

function modApi:deleteModdedMaps()
	for i, mapname in ipairs(self:getMapsList()) do
		if not list_contains(self.defaultMaps, mapname) then
			os.remove("maps/"..mapname..".map")
		end
	end
end

function modApi:addMap(path)
	local idx = (string.find(path, "/[^/]*$") or 0) + 1
	local mapfile = string.sub(path, idx)
	local mapname = self:pruneExtension(mapfile)

	if list_contains(self.defaultMaps, mapname) then
		LOG(string.format("Unable to add map '%s', because it would overwrite a vanilla map.", path))
	else
		self:copyFile(path, "maps/"..mapfile)
	end
end
