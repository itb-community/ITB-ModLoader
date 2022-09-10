modApi = modApi or {}

function modApi:fileExists(name)
	Assert.Equals('string', type(name), "Argument #1")
	return File(name):exists()
end

function modApi:directoryExists(path)
	return Directory(path):exists()
end

function modApi:writeFile(path, content)
	assert(type(path) == "string")
	assert(type(content) == "string")

	File(path):write_string(content)
end

function modApi:copyFile(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	File(src):copy(dst)
end

modApi.copyFileOS = modApi.copyFile

function modApi:pruneExtension(filename)
	-- gsub() returns multiple values, store the first
	-- value in a variable so that we correctly ignore
	-- the retvalues that come after it.
	local r = string.gsub(filename, "\.[^.]*$", "")
	return r
end
