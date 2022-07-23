local class = require("scripts/mod_loader/ftldat/kaitai_struct_lua_runtime/class")

local FtlDat = class.class(KaitaiStruct)
local File = class.class(KaitaiStruct)
local Meta = class.class(KaitaiStruct)

--FtlDat

function FtlDat:from_file(filename)
	return KaitaiStruct.from_file(self,filename)
end

function FtlDat:from_string(s)
	return KaitaiStruct.from_string(self,s)
end

function FtlDat:_init(p__io, p__parent, p__root)
	KaitaiStruct._init(self,p__io)
	self.m_parent = p__parent
	self.m_root = p__root or self
	self.signature = false
end

function FtlDat:_read(signature_scan)
	self._numFiles = self._io:read_u4le()

	self._files = {}
	self._filesByName = {}
	for i = 1, self._numFiles do
		local file = File(self._io, self, self.m_root)
		file:_read(signature_scan)
		self:_insert_file(file)
	end
end

function FtlDat:_write()
	local ret = {lua_struct.pack("<I",self._numFiles)}

	local meta = {}

	local metaOfs = 4 * (1 + self._numFiles)
	for i = 1, self._numFiles do
		local data = self._files[i]._meta:_write()
		table.insert(meta,data)
		table.insert(ret,lua_struct.pack("<I",metaOfs))
		metaOfs = metaOfs + data:len()
	end
	for i, data in ipairs(meta) do
		table.insert(ret,data)
	end
	return table.concat(ret)
end

--File

function File:_init(p__io, p__parent, p__root)
	KaitaiStruct._init(self,p__io)
	self.m_parent = p__parent
	self.m_root = p__root
end

function File:_read(signature_scan)
	self._metaOfs = self._io:read_u4le()

	if (self._metaOfs ~= 0) then
		local _pos = self._io:pos()
		self._io:seek(self._metaOfs)
		self._meta = Meta(self._io, self, self.m_root)
		self._meta:_read(signature_scan)
		self._io:seek(_pos)
	end
end

function File:_write()
	--return lua_struct.pack("<I",self._metaOfs)
end

--Meta

function Meta:_init(p__io, p__parent, p__root)
	KaitaiStruct._init(self,p__io)
	self.m_parent = p__parent
	self.m_root = p__root
end

function Meta:_read(signature_scan)
	self._fileSize = self._io:read_u4le()
	self._filenameSize = self._io:read_u4le()
	self._filename = self._io:read_bytes(self._filenameSize)
	-- signature scan means we only want filenames to see if the signature is set
	-- the position will be reset after reading this meta, so as long as we read everything before the filename, we do not have the read the body
	if not signature_scan then
		self.body = self._io:read_bytes(self._fileSize)
	end

	if self._filename == modApi:getSignature() then
		self.m_root.signature = true
	end
end

function Meta:_write()
	local size = lua_struct.pack("<I",self._fileSize)
	local nameSize = lua_struct.pack("<I",self._filenameSize)
	return table.concat({size,nameSize,self._filename,self.body})
end


-- ITB mod loader added helpers

function FtlDat:remove_all_files()
	self._files = {}
	self._filesByName = {}
	self._numFiles = 0
end

-- internal - inserts without increasing file count
function FtlDat:_insert_file(file)
	table.insert(self._files, file)
	self._filesByName[file._meta._filename] = file
end

-- helper to add a file and store its index in the by name lookup
-- ensures we do not lose ordering info
function FtlDat:insert_file(file)
	self:_insert_file(file)
	self._numFiles = self._numFiles + 1
end

-- Helper to check if a file exists
function FtlDat:file_exists(name)
	return self._filesByName[name] ~= nil
end

-- helper to look up a file by name
function FtlDat:find_existing_file(name)
	return self._filesByName[name]
end

return {
	FtlDat = FtlDat,
	File = File,
	Meta = Meta,
}
