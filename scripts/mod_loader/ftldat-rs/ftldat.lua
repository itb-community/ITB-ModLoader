local ftldat_rs = nil

local function lazy_load()
	if ftldat_rs ~= nil then
		return
	end

	try(function()
		LOG("Loading ftldat.dll...")
		package.loadlib("ftldat.dll", "luaopen_ftldat")()
		ftldat_rs = ftldat
		ftldat = nil
		LOG("Successfully loaded ftldat.dll!")
	end)
	:catch(function(err)
		error(string.format(
				"Failed to load ftldat.dll: %s",
				tostring(err)
		))
	end)
end

-- Use a class to serve as a wrapper around the Package userdata returned by ftldat-rs,
-- so that we can more easily evolve both APIs.
FtlDat = Class.new()

function FtlDat:new(filename)
	lazy_load()

	if filename == nil then
		self.package = ftldat_rs.new_package()
	else
		try(function()
			self.package = ftldat_rs.read_package(filename)
			self.signature = self.package:exists(modApi:getSignature())
		end)
		:catch(function(err)
			error(string.format(
					"Failed to create FtlDat package for file '%s'. Does it exist?\n%s",
					filename, tostring(err)
			))
		end)
	end
end

function FtlDat:remove_all_files()
	Assert.Equals("table", type(self))
	self.package:clear()
end

function FtlDat:write(outputPath)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(outputPath))

	try (function()
		self.package:to_file(outputPath)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to write ftldat archive to %s\n%s",
				outputPath, tostring(err)
		))
	end)
end

function FtlDat:put_entry_string(innerPath, content)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(innerPath))
	Assert.Equals("string", type(content))

	try(function()
		self.package:put_entry_from_string(innerPath, content)
	end)
	:catch(function(err_string)
		try(function()
			self.package:put_entry_from_byte_array(innerPath, content)
		end)
		:catch(function(err_byte_array)
			error(string.format(
					"Failed to put entry '%s' content from string\nas string: %s\nas byte array: %s",
					innerPath, tostring(err_string), tostring(err_byte_array)
			))
		end)
	end)
end

function FtlDat:put_entry_byte_array(innerPath, content)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(innerPath))
	Assert.Equals("table", type(content))

	try(function()
		self.package:put_entry_from_byte_array(innerPath, content)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to put entry '%s' content from byte array\n%s",
				innerPath, tostring(err)
		))
	end)
end

function FtlDat:put_entry_file(innerPath, sourcePath)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(innerPath))
	Assert.Equals("string", type(sourcePath))

	try(function()
		self.package:put_entry_from_file(innerPath, sourcePath)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to put entry '%s' content from file '%s'\n%s",
				innerPath, sourcePath, tostring(err)
		))
	end)
end

function FtlDat:file_exists(name)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(name))
	return self.package:exists(name)
end

--- Returns content of the specified file, interpreted as text.
function FtlDat:entry_content_string(innerPath)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(innerPath))

	local result
	try(function()
		result = self.package:read_content_as_string(innerPath)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to read entry '%s' content as string\n%s",
				innerPath, tostring(err)
		))
	end)

	return result
end

--- Returns content of the specified file as an array of bytes.
function FtlDat:entry_content_byte_array(innerPath)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(innerPath))

	local result
	try(function()
		result = self.package:read_content_as_byte_array(innerPath)
	end)
	:catch(function(err)
		error(string.format(
				"Failed to read entry '%s' content as byte array\n%s",
				innerPath, tostring(err)
		))
	end)

	return result
end

function FtlDat:inner_paths()
	Assert.Equals("table", type(self))
	return self.package:inner_paths()
end

local function utf8_from(t)
	local bytearr = {}
	for _, v in ipairs(t) do
		local utf8byte = v < 0 and (0xff + v + 1) or v
		table.insert(bytearr, string.char(utf8byte))
	end
	return table.concat(bytearr)
end

--- Extract the specified file from .dat and save it to the specified destination.
function FtlDat:extract_file(innerPath, destinationPath)
	Assert.Equals("table", type(self))
	Assert.Equals("string", type(innerPath))
	Assert.Equals("string", type(destinationPath))

	try(function()
		local content = self.entry_content_byte_array(innerPath)
		content = utf8_from(content)

		local f = assert(io.open(destinationPath, "wb"), destinationPath)
		f:write(content)
		f:close()
	end)
	:catch(function(err)
		error(string.format(
				"Failed to extract '%s' from ftldat archive to '%s'\n%s",
				innerPath, destinationPath, tostring(err)
		))
	end)
end

function FtlDat:destroy()
	self.package = nil
	collectgarbage()
end
