modApi = modApi or {}

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
