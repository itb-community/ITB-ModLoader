local ftldat_rs = nil

local function lazy_load()
    if ftldat_rs ~= nil then
        return
    end

    LOG("Loading ftldat.dll...")
    local ok, err = pcall(package.loadlib("ftldat.dll", "luaopen_ftldat"))
    if not ok then
        error(string.format("Failed to load ftldat.dll: %s", err))
    else
        LOG("Successfully loaded ftldat.dll!")
    end
    ftldat_rs = ftldat
    ftldat = nil
end

-- Use a class to serve as a wrapper around the Package userdata returned by ftldat-rs,
-- so that we can more easily evolve both APIs.
FtlDat = Class.new()

function FtlDat:new(filename)
    lazy_load()

    if filename == nil then
        self.package = ftldat_rs.new_package()
    else
        self.package = ftldat_rs.read_package(filename)
        self.signature = self.package:exists(modApi:getSignature())
    end
end

function FtlDat:remove_all_files()
    self.package:clear()
end

function FtlDat:write(outputPath)
    self.package:to_file(outputPath)
end

function FtlDat:put_entry(innerPath, content)
    if type(content) == "string" then
        -- Sending some strings back to ftldat-rs causes an access violation when the string represents
        -- content of a file that is typically binary (eg. images or fonts).
        -- Work around this by communicating with ftldat-rs using byte arrays.
        content = { content:byte(1, -1) }
    end
    Assert.Equals("table", type(content))

    self.package:put_binary_entry(innerPath, content)
end

function FtlDat:file_exists(name)
    return self.package:exists(name)
end

--- Returns content of the specified file, interpreted as text.
function FtlDat:entry_content(innerPath)
    return self.package:content_text_by_path(innerPath)
end

--- Returns content of the specified file as an array of bytes.
function FtlDat:entry_content_binary(innerPath)
    return self.package:content_binary_by_path(innerPath)
end

function FtlDat:inner_paths()
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
    local content = self.package:content_binary_by_path(innerPath)
    content = utf8_from(content)

	local f = assert(io.open(destinationPath, "wb"), destinationPath)
	f:write(content)
	f:close()
end

function FtlDat:destroy()
    self.package = nil
    collectgarbage()
end
