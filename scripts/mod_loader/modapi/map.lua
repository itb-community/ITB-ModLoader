
-- //////////////////////////////////////////////////////////////////////////////
-- Map handling

--[[
	Returns a list of names of all *.map files in maps/ directory,
	without the .map extension
--]]
function modApi:getMapsList()
	local list = {}

	for i, file in pairs(os.listfiles("maps")) do
		if modApi:stringEndsWith(file, ".map") then
			table.insert(list, self:pruneExtension(file))
		end
	end

	return list
end

function modApi:deleteModdedMaps()
	for i, mapname in ipairs(self:getMapsList()) do
		if not list_contains(self.defaultMaps, mapname) then
			os.remove("maps/"..mapname..".map")
		end
	end
end

function modApi:addMap(path)
	local idx = (string.find(path, "/[^/]*$") or 0) + 1
	local mapfile = string.sub(path, idx)
	local mapname = self:pruneExtension(mapfile)

	if list_contains(self.defaultMaps, mapname) then
		LOG(string.format("Unable to add map '%s', because it would overwrite a vanilla map.", path))
	else
		self:copyFile(path, "maps/"..mapfile)
	end
end
