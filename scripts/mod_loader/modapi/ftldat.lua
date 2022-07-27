-- //////////////////////////////////////////////////////////////////////////////
-- Resource.dat handling

local FtlDat = require("scripts/mod_loader/ftldat/ftldat")

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
	Assert.Equals("string", type(content))

	local existing = self.resource:find_existing_file(resource)
	if existing ~= nil then
		existing._meta.body = content
		existing._meta._fileSize = content:len()
		-- Overwriting an existing file, return early
		return
	end

	-- Writing a new file to the archive
	local file = FtlDat.File(self.resource._io,self.resource,self.resource.m_root)
	file._meta = FtlDat.Meta(file._io, file, file.m_root)

	file._meta._filenameSize = resource:len()
	file._meta._filename = resource
	file._meta.body = content
	file._meta._fileSize = file._meta.body:len()

	self.resource:insert_file(file)
end

--[[
	Reads the specified file from the resouce.dat archive.
	Throws an error if the file could not be found.

	resource:
		Path of the file to read
	returns:
		Content of the file in string format
--]]
function modApi:readAsset(resource)
	Assert.ResourceDatIsOpen("readAsset")
	Assert.Equals("string", type(resource))

	local existing = self.resource:find_existing_file(resource)
	if existing ~= nil then
		return existing._meta.body
	end

	error(string.format("Could not find file '%s' in resource.dat archive", resource))
end

function modApi:appendAsset(resource, filePath)
	Assert.Equals("string", type(resource))
	Assert.Equals("string", type(filePath))
	local f = io.open(filePath,"rb")
	Assert.NotEquals(nil, f, "File doesn't exist: ".. filePath)
	local content = f:read("*all")
	f:close()

	self:writeAsset(resource, content)
end

--[[
	Copies an existing asset within the resource.dat archive to
	another path within the resource.dat archive. Can overwrite
	existing files.
--]]
function modApi:copyAsset(src, dst)
	Assert.Equals("string", type(src))
	Assert.Equals("string", type(dst))

	self:writeAsset(dst, self:readAsset(src))
end

function modApi:appendDat(filePath)
	local instance = FtlDat.FtlDat:from_file(filePath)

	for i, file in ipairs(instance._files) do
		local existing = self.resource:find_existing_file(file._meta._filename)
		if existing ~= nil then
			existing._meta.body = file._meta.body
			existing._meta._fileSize = file._meta._fileSize
		else
			self.resource:insert_file(file)
		end
	end
end

function modApi:fileDirectoryToDat(path)
	Assert.Equals("string", type(path))
	local len = path:len()
	assert(len > 0)
	
	if path:sub(len) ~= [[/]] and path:sub(len) ~= [[\]] then
		path = path.."/"
	end
	
	local ftldat = FtlDat.FtlDat()
	ftldat:remove_all_files()

	local function addDir(directory)
		for i, dir in pairs(os.listdirs(path..directory)) do
			addDir(directory..dir.."/")
		end
		for i, dirfile in pairs(os.listfiles(path..directory)) do
			
			local f = io.open(path..directory..dirfile,"rb")

			local file = FtlDat.File()
			file._meta = FtlDat.Meta()
	
			file._meta._filename = directory..dirfile
			file._meta._filenameSize = file._meta._filename:len()
			file._meta.body = f:read("*all")
			file._meta._fileSize = file._meta.body:len()
			
			f:close()

			ftldat:insert_file(file)
		end
	end
	
	addDir("")
	
	local f = io.open(path.."resource.dat","wb+")
	local output = ftldat:_write()
	f:write(output)
	f:close()
end

function modApi:getSignature()
	return "ModLoaderSignature"
end

function modApi:finalize()
	local f = nil
	try(function()
		f = io.open("resources/resource.dat","wb")

		if not self.resource.signature then
			self.resource.signature = true
			local file = FtlDat.File(self.resource._io,self.resource,self.resource.m_root)
			file._meta = FtlDat.Meta(file._io, file, file.m_root)

			file._meta._filename = self:getSignature()
			file._meta._filenameSize = file._meta._filename:len()
			file._meta.body = "OK"
			file._meta._fileSize = file._meta.body:len()
			self.resource:insert_file(file)
		end

		local output = self.resource:_write()
		f:write(output)
	end)
	:catch(function(err)
		LOG("Failed to finalize resource.dat: ", err)
	end)
	:finally(function()
		if f then
			f:close()
		end
	end)

	self.resource = nil
end
