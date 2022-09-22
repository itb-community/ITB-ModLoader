local factory
local function lazy_load()
	if factory ~= nil then
		return
	end

	try(function()
		LOG("Loading itb_io.dll...")
		package.loadlib("itb_io.dll", "luaopen_itb_io")()
		factory = itb_io
		itb_io = nil
		LOG("Successfully loaded itb_io.dll!")
	end)
	:catch(function(err)
		error(string.format(
				"Failed to load itb_io.dll: %s",
				tostring(err)
		))
	end)
end

File = Class.new();

--- path - Path to the file. If the path points to a File outside the game's
---	       directory or save data directory, an error is thrown.
---
--- returns a File instance
function File:new(path)
	Assert.Equals("string", type(path), "Path must be a string")
	lazy_load()

	try(function()
		self.instance = factory.file(path)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to create File instance for path %q: %s",
				path, tostring(err)
		))
	end)
end

function File.of(instance)
	Assert.Equals("userdata", type(instance))

	local file_new = File.new
	File.new = nil
	local result = File()
	result.instance = instance
	File.new = file_new

	return result
end

--- returns string representation of the path to this file
function File:path()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:path()
end

--- returns name of this file, including extension
function File:name()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:name()
end

--- returns name of this file, without extension
function File:name_without_extension()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:name_without_extension()
end

--- returns the file's extension, or nil if there's none
function File:extension()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:extension()
end

--- returns the parent directory of this file.
function File:parent()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result
	try(function()
		result = Directory.of(self.instance:parent())
	end)
	:catch(function(err)
		error(string.format(
				"Failed to access parent of %q: %s",
				self:path(), tostring(err)
		))
	end)
	return result
end

--- returns contents of the file as string
function File:read_to_string()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result
	try(function()
		result = self.instance:read_to_string()
	end)
	:catch(function(err)
		error(string.format(
				"Failed to read file %q as string: %s",
				self:path(), tostring(err)
		))
	end)
	return result
end

--- returns contents of the file as byte array
function File:read_to_byte_array()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result
	try(function()
		result = self.instance:read_to_byte_array()
	end)
	:catch(function(err)
		error(string.format(
				"Failed to read file %q as byte array: %s",
				self:path(), tostring(err)
		))
	end)
	return result
end

--- Replaces the file's content with the specified string content
function File:write_string(content)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(content))

	try(function()
		self.instance:write_string(content)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to write string to file %q: %s",
				self:path(), tostring(err)
		))
	end)
end

--- Replaces the file's content with the specified byte array content
function File:write_byte_array(content)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("table", type(content))

	try(function()
		self.instance:write_byte_array(content)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to write byte array to file %q: %s",
				self:path(), tostring(err)
		))
	end)
end

--- Copies this file to the specified destination path
function File:copy(destination)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(destination))

	try(function()
		self.instance:copy(destination)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to copy file %q to %q: %s",
				self:path(), destination, tostring(err)
		))
	end)
end

--- Moves this file to the specified destination path
--- Moving a file to a different location within the same directory is
--- functionally the same as renaming it.
function File:move(destination)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(destination))

	try(function()
		self.instance:move(destination)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to move file %q to %q: %s",
				self:path(), destination, tostring(err)
		))
	end)
end

--- returns true if this file exists, false otherwise
function File:exists()
	Assert.Equals("table", type(self), "Check for . vs :")

	return self.instance:exists()
end

function File:delete()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result
	try(function()
		result = self.instance:delete()
	end)
	:catch(function(err)
		error(string.format(
				"Failed to delete file %q: %s",
				self:path(), tostring(err)
		))
	end)
	return result
end


Directory = Class.new();

--- path - Path to the directory. If the path points to a Directory outside the game's
---	       directory or save data directory, an error is thrown.
---
--- returns a Directory instance
function Directory:new(path)
	Assert.Equals("string", type(path))
	lazy_load()

	try(function()
		self.instance = factory.directory(path)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to create Directory instance for path %q: %s",
				path, tostring(err)
		))
	end)
end

function Directory.of(instance)
	Assert.Equals("userdata", type(instance))

	local directory_new = Directory.new
	Directory.new = nil
	local result = Directory()
	result.instance = instance
	Directory.new = directory_new

	return result
end

local savedata
function Directory.savedata()
	lazy_load()

	if savedata == null then
		try(function()
			savedata = factory.save_data_directory();
		end)
		:catch(function(err)
			error(string.format(
					"Failed to create Directory instance for save data directory: %s",
					path, tostring(err)
			))
		end)
	end

	return Directory.of(savedata)
end

--- returns string representation of the path to this directory
function Directory:path()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:path()
end

--- returns name of this directory
function Directory:name()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:name()
end

--- returns the parent directory of this directory.
function Directory:parent()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result
	try(function()
		result = Directory.of(self.instance:parent())
	end)
	:catch(function(err)
		error(string.format(
				"Failed to access parent of %q: %s",
				self:path(), tostring(err)
		))
	end)
	return result
end

function Directory:file(path)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(path))

	local finalPath = string.gsub(self:path(), "\\", "/")
	if not modApi:stringEndsWith(finalPath, "/") then
		finalPath = finalPath .. "/"
	end
	finalPath = finalPath .. path

	return File(finalPath)
end

function Directory:directory(path)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(path))

	local finalPath = string.gsub(self:path(), "\\", "/")
	if not modApi:stringEndsWith(finalPath, "/") then
		finalPath = finalPath .. "/"
	end
	finalPath = finalPath .. path

	return Directory(finalPath)
end

function Directory:files()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result = {}
	try(function()
		local instances = self.instance:files()
		for _, instance in ipairs(instances) do
			table.insert(result, File.of(instance))
		end
	end)
	:catch(function(err)
		error(string.format(
				"Failed to list child files of %q: %s",
				self:path(), tostring(err)
		))
	end)

	return result
end

function Directory:directories()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result = {}
	try(function()
		local instances = self.instance:directories()
		for _, instance in ipairs(instances) do
			table.insert(result, Directory.of(instance))
		end
	end)
	:catch(function(err)
		error(string.format(
				"Failed to list child directories of %q: %s",
				self:path(), tostring(err)
		))
	end)

	return result
end

--- returns true if this directory exists, false otherwise
function Directory:exists()
	Assert.Equals("table", type(self), "Check for . vs :")

	return self.instance:exists()
end

--- Deletes this directory and all its contents
function Directory:delete()
	Assert.Equals("table", type(self), "Check for . vs :")

	local result
	try(function()
		result = self.instance:delete()
	end)
	:catch(function(err)
		error(string.format(
				"Failed to delete directory %q: %s",
				self:path(), tostring(err)
		))
	end)
	return result
end
