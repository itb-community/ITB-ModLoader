
-- //////////////////////////////////////////////////////////////////////////////
-- Map handling

function modApi:fileExists(name)
	Assert.Equals('string', type(name), "Argument #1")

	-- ignore the error, since typically we don't care about it
	local ok, _, code = os.rename(name, name)

	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end

		-- make sure we always return a non-nil, boolean value
		return false
	end

	return true
end

function modApi:directoryExists(path)
	return self:fileExists(path .."/")
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

function modApi:copyFileOS(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	-- Need Windows-style paths with \ as separator
	src = string.gsub(src, "/", "\\")
	dst = string.gsub(dst, "/", "\\")

	-- Copy via OS command rather than lua open/write, since it's much faster.
	os.execute("COPY /V /Y " .. src .. " " .. dst)
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
