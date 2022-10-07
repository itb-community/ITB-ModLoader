-- //////////////////////////////////////////////////////////////////////////////
-- Resource.dat handling

function modApi:assetExists(resource)
	Assert.ResourceDatIsOpen("assetExists")
	Assert.Equals("string", type(resource))

	return self.resource:file_exists(resource)
end

--[[
	Writes a new file to the resource.dat archive with the specified content.

	resource:
		Path to the file within the archive
	content:
		String content to be written to the file
--]]
function modApi:writeAsset(resource, content)
	Assert.ResourceDatIsOpen("writeAsset")
	Assert.Equals("string", type(resource))
	Assert.Equals({ "string", "table" }, type(content))

	if type(content) == "string" then
		self.resource:put_entry_string(resource, content)
	else
		self.resource:put_entry_byte_array(resource, content)
	end
end

--[[
	Reads the specified file from the resource.dat archive.
	Throws an error if the file could not be found.

	resource:
		Path of the file to read
	returns:
		Content of the file in string format
--]]
function modApi:readAsset(resource)
	Assert.ResourceDatIsOpen("readAsset")
	Assert.Equals("string", type(resource))

	return self.resource:entry_content_string(resource)
end

--[[
	Appends content of the specified file to the resource.dat archive.

	resource:
		Path to the file within the archive
	filePath:
		Path to the file containing content to be saved within the archive
--]]
function modApi:appendAsset(resource, filePath)
	Assert.Equals("string", type(resource))
	Assert.Equals("string", type(filePath))

	self.resource:put_entry_file(resource, filePath)
end

--[[
	Copies an existing asset within the resource.dat archive to
	another path within the resource.dat archive. Can overwrite
	existing files.
--]]
function modApi:copyAsset(src, dst)
	Assert.Equals("string", type(src))
	Assert.Equals("string", type(dst))

	self.resource:put_entry_byte_array(dst, self.resource:entry_content_byte_array(src))
end

function modApi:appendDat(filePath)
	local instance = FtlDat(filePath)

	for i, innerPath in ipairs(instance:inner_paths()) do
		self.resource:put_entry_byte_array(innerPath, instance:entry_content_byte_array(innerPath))
	end

	instance:destroy()
end

function modApi:fileDirectoryToDat(path)
	Assert.Equals("string", type(path))
	local len = path:len()
	assert(len > 0)

	local ftldat = FtlDat()

	local function addDir(directory)
		for _, childFile in ipairs(directory:files()) do
			local p = childFile:path()
			ftldat:put_entry_file(directory:path()..path, path)
		end

		for _, childDirectory in ipairs(directory:directories()) do
			addDir(childDirectory)
		end
	end

	addDir(Directory(""))

	ftldat:write(path .. "resource.dat")
	ftldat:destroy()
end

function modApi:getSignature()
	return "ModLoaderSignature"
end

function modApi:finalize()
	try(function()
		if not self.resource.signature then
			self.resource.signature = true
			self.resource:put_entry_string(self:getSignature(), "OK")
		end

		self.resource:write("resources/resource.dat")
	end)
	:catch(function(err)
		LOG("Failed to finalize resource.dat: ", err)
	end)

	self.resource:destroy()
	self.resource = nil
end
