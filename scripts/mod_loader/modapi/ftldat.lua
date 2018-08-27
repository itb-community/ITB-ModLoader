-- //////////////////////////////////////////////////////////////////////////////
-- Resource.dat handling

local FtlDat = require("scripts/mod_loader/ftldat/ftldat")

--[[
	Writes a new file to the resource.dat archive with the specified content.

	resource:
		Path to the file within the archive
	content:
		String content to be written to the file
--]]
function modApi:writeAsset(resource, content)
	assert(type(resource) == "string")
	assert(type(content) == "string")

	for i, file in ipairs(self.resource._files) do
		if file._meta._filename == resource then
			file._meta.body = content
			file._meta._fileSize = file._meta.body:len()

			-- Overwriting an existing file, return early
			return
		end
	end

	-- Writing a new file to the archive
	self.resource._numFiles = self.resource._numFiles + 1

	local file = FtlDat.File(self.resource._io,self.resource,self.resource.m_root)
	file._meta = FtlDat.Meta(file._io, file, file.m_root)
	
	file._meta._filenameSize = resource:len()
	file._meta._filename = resource
	file._meta.body = content
	file._meta._fileSize = file._meta.body:len()

	table.insert(self.resource._files, file)
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
	assert(type(resource) == "string")

	for i, file in ipairs(self.resource._files) do
		if file._meta._filename == resource then
			return file._meta.body
		end
	end

	error(string.format("Could not find file '%s' in resource.dat archive", resource))
end

function modApi:appendAsset(resource, filePath)
	assert(type(resource) == "string")
	local f = io.open(filePath,"rb")
	assert(f, filePath)
	
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
	assert(type(src == "string"))
	assert(type(dst == "string"))

	self:writeAsset(dst, self:readAsset(src))
end

function modApi:appendDat(filePath)
	local instance = FtlDat.FtlDat:from_file(filePath)
	
	for i, file in ipairs(instance._files) do
		local found = false
		for j, og in ipairs(self.resource) do
			if file._meta._filename == og._meta._filename then
				og._meta.body = file._meta.body
				og._meta._fileSize = file._meta._fileSize
				found = true
			
				break
			end
		end
		
		if not found then
			table.insert(self.resource._files,file)
			self.resource._numFiles = self.resource._numFiles + 1
		end
	end
end

function modApi:fileDirectoryToDat(path)
	assert(type(path) == "string")
	local len = path:len()
	assert(len > 0)
	
	if path:sub(len) ~= [[/]] and path:sub(len) ~= [[\]] then
		path = path.."/"
	end
	
	local ftldat = FtlDat.FtlDat()
	ftldat._files = {}
	ftldat._numFiles = 0
	
	local function addDir(directory)
		for i, dir in pairs(os.listdirs(path..directory)) do
			addDir(directory..dir.."/")
		end
		for i, dirfile in pairs(os.listfiles(path..directory)) do
			
			local f = io.open(path..directory..dirfile,"rb")
			
			ftldat._numFiles = ftldat._numFiles + 1
	
			local file = FtlDat.File()
			file._meta = FtlDat.Meta()
	
			file._meta._filename = directory..dirfile
			file._meta._filenameSize = file._meta._filename:len()
			file._meta.body = f:read("*all")
			file._meta._fileSize = file._meta.body:len()
			
			f:close()
			
			table.insert(ftldat._files,file)
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
	local f = io.open("resources/resource.dat","wb")
	
	if not self.resource.signature then
		self.resource.signature = true
		self.resource._numFiles = self.resource._numFiles + 1
		local file = FtlDat.File(self.resource._io,self.resource,self.resource.m_root)
		file._meta = FtlDat.Meta(file._io, file, file.m_root)
		
		file._meta._filename = self:getSignature()
		file._meta._filenameSize = file._meta._filename:len()
		file._meta.body = "OK"
		file._meta._fileSize = file._meta.body:len()
		table.insert(self.resource._files,file)
	end
	
	local output = self.resource:_write()
	f:write(output)
	f:close()
end