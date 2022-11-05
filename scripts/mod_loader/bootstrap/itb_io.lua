-- Cache references to commonly used directories for internal use,
-- so that the API's memory footprint is kept constant and low.
local root_directory
local savedata_directory

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
--- Returns a File instance
function File:new(...)
	lazy_load()

	local path = table.concat({...}, "/");

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

--- Returns string representation of the path to this file
function File:path()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:path()
end

--- Returns string representation of the path to this file
--- relative to the ITB directory or the save data directory
function File:relative_path()
	Assert.Equals("table", type(self), "Check for . vs :")

	local path = self.instance:path()

	if root_directory:is_ancestor(path) then
		return root_directory:relativize(path)
	elseif savedata_directory:is_ancestor(path) then
		return savedata_directory:relativize(path)
	end
end

--- Returns name of this file, including extension
function File:name()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:name()
end

--- Returns name of this file, without extension
function File:name_without_extension()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:name_without_extension()
end

--- Returns the file's extension, or nil if there's none
function File:extension()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:extension()
end

--- Returns the parent directory of this file.
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

--- Returns contents of the file as string
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

--- Returns contents of the file as byte array
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

--- Appends the specified string content at the end of the file
function File:append(content)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(content))

	try(function()
		self.instance:append_string(content)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to append string to file %q: %s",
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
--- Returns a new File instance for the destination path
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

	return File(destination)
end

--- Moves this file to the specified destination path
--- Moving a file to a different location within the same directory is
--- functionally the same as renaming it.
--- Returns a new File instance for the destination path
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

	return File(destination)
end

--- Creates missing directories in this File's abstract path, ensuring that they
--- actually exist on the file system.
function File:make_directories()
	Assert.Equals("table", type(self), "Check for . vs :")

	try(function()
		self.instance:parent():make_directories()
	end)
	:catch(function(err)
		error(string.format(
				"Failed to create directories for %q: %s",
				self:path(), tostring(err)
		))
	end)
end

--- Returns true if this file exists, false otherwise
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

function File:GetLuaString()
	return string.format("File(%q)", self:path())
end
File.GetString = File.GetLuaString


Directory = Class.new();

--- path - Path to the directory. If the path points to a Directory outside the game's
---	       directory or save data directory, an error is thrown.
---
--- Returns a Directory instance
function Directory:new(...)
	lazy_load()

	local args = {...}
	local path
	if #args == 0 then
		path = "."
	else
		path = table.concat(args, "/");
	end

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
	if savedata == null then
		lazy_load()
		try(function()
			savedata = factory.save_data_directory();
		end)
		:catch(function(err)
			error(string.format(
					"Failed to create Directory instance for save data directory: %s",
					tostring(err)
			))
		end)
	end

	return Directory.of(savedata)
end

--- Returns string representation of the path to this directory
function Directory:path()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:path()
end

--- Returns string representation of the path to this directory
--- relative to the ITB directory or the save data directory
function Directory:relative_path()
	Assert.Equals("table", type(self), "Check for . vs :")

	local path = self.instance:path()

	if root_directory:is_ancestor(path) then
		return root_directory:relativize(path)
	elseif savedata_directory:is_ancestor(path) then
		return savedata_directory:relativize(path)
	end
end

--- Returns name of this directory
function Directory:name()
	Assert.Equals("table", type(self), "Check for . vs :")
	return self.instance:name()
end

--- Returns the parent directory of this directory.
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

--- Relativizes the specified path relative to this directory. More generally, returns a string
--- that can later be used to navigate to the specified path by invoking `directory` or `file`
--- functions on this Directory instance.
--- Example:
---   Directory("some/path"):relativize("some/path/test") -- returns "test"
---   Directory("some/path/test"):relativize("some/path") -- returns ".."
function Directory:relativize(path)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(path))

	local result
	try(function()
		result = self.instance:relativize(path)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to relativize path %q to %q: %s",
				path, self:path(), tostring(err)
		))
	end)
	return result
end

function Directory:file(...)
	Assert.Equals("table", type(self), "Check for . vs :")
	local args = { ... }

	local result
	try(function()
		result = File.of(self.instance:file(unpack(args)))
	end)
	:catch(function(err)
		local path = self:path() .. table.concat(args, "/")
		error(string.format(
				"Failed to create File instance for path %q: %s",
				path, tostring(err)
		))
	end)

	return result
end

function Directory:directory(...)
	Assert.Equals("table", type(self), "Check for . vs :")
	local args = { ... }

	local result
	try(function()
		result = Directory.of(self.instance:directory(unpack(args)))
	end)
	:catch(function(err)
		local path = self:path() .. table.concat(args, "/")
		error(string.format(
				"Failed to create Directory instance for path %q: %s",
				path, tostring(err)
		))
	end)

	return result
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

--- Creates missing directories in this Directory's abstract path, ensuring that they
--- actually exist on the file system.
function Directory:make_directories()
	Assert.Equals("table", type(self), "Check for . vs :")

	try(function()
		self.instance:make_directories()
	end)
	:catch(function(err)
		error(string.format(
				"Failed to create directories for %q: %s",
				self:path(), tostring(err)
		))
	end)
end

--- Returns true if this directory exists, false otherwise
function Directory:exists()
	Assert.Equals("table", type(self), "Check for . vs :")

	return self.instance:exists()
end

--- Returns true if the specified path starts with this directory's path
function Directory:is_ancestor(path)
	Assert.Equals("table", type(self), "Check for . vs :")
	Assert.Equals("string", type(path))

	local result
	try(function()
		-- *technically* it can fail...
		result = self.instance:is_ancestor(path)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to create directories for %q: %s",
				self:path(), tostring(err)
		))
	end)
	return result
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

function Directory:GetLuaString()
	return string.format("Directory(%q)", self:path())
end
Directory.GetString = Directory.GetLuaString

root_directory = Directory()
savedata_directory = Directory.savedata()