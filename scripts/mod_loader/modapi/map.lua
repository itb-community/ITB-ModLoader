
-- //////////////////////////////////////////////////////////////////////////////
-- Map handling

--[[
	Returns a list of names of all *.map files in maps/ directory,
	without the .map extension
--]]
function modApi:getMapsList()
	local list = {}

	local dir = Directory("maps")
	for _, file in ipairs(dir:files()) do
		if file:extension() == "map" then
			table.insert(list, file:name_without_extension())
		end
	end

	return list
end

function modApi:deleteModdedMaps()
	for i, mapname in ipairs(self:getMapsList()) do
		if not list_contains(self.defaultMaps, mapname) then
			File("maps", mapname..".map"):delete()
		end
	end
end

function modApi:addMap(path)
	local idx = (string.find(path, "/[^/]*$") or 0) + 1
	local mapfile = string.sub(path, idx)
	local mapname = self:pruneExtension(mapfile)

	if list_contains(self.defaultMaps, mapname) then
		LOG(string.format("Unable to add map %q, because it would overwrite a vanilla map.", path))
	else
		self:copyFile(path, "maps/"..mapfile)
	end
end

local maps_cached

function modApi:clearCachedMaps()
	maps_cached = nil
end

function modApi:getMaps()
	return maps_cached or self:fetchMaps()
end

function modApi:fetchMaps()
	local files = mod_loader:enumerateFilesIn("maps/")
	local maps = {}

	for _, file in ipairs(files) do
		if modApi:stringEndsWith(file, ".map") then
			local map = {}
			local id
			modApi:loadIntoEnv("maps/"..file, map)
			id, map = next(map)
			map.id = id
			maps[#maps+1] = map
		end
	end

	return maps
end

local function filterMapsByIds(maps, ids)
	local result = {}

	for _, map in ipairs(maps) do
		if list_contains(ids, map.id) then
			result[#result+1] = map
		end
	end

	return result
end

local function filterMapsByTags(maps, tags)
	local result = {}

	if type(tags) ~= 'table' then
		tags = { tags }
	end

	for _, map in ipairs(maps) do
		for _, tag in ipairs(map.tags) do
			if list_contains(tags, tag) then
				result[#result+1] = map
				break
			end
		end
	end

	return result
end

local function filterMapsByTileset(maps, tileset)
	local result = {}

	for _, map in ipairs(maps) do
		for _, tag in ipairs(map.tags) do
			if tag == "any_sector" or tag == tileset then
				result[#result+1] = map
				break
			end
		end
	end

	return result
end

local function filterMapsByVetoes(maps, vetoes)
	local result = {}

	for _, map in ipairs(maps) do
		if not list_contains(vetoes, map.id) then
			result[#result+1] = map
		end
	end

	return result
end

function modApi:fetchMissionMaps(mission, tileset)
	Assert.Equals('string', type(mission), "Argument #1")
	Assert.Equals('string', type(tileset), "Argument #2")
	Assert.Equals('table', type(_G[mission]), "Mission '"..mission.."' does not exist")

	local maps = self:getMaps()
	local mission = _G[mission]

	if #mission.MapList > 0 then
		maps = filterMapsByIds(maps, mission.MapList)
	else
		maps = filterMapsByTags(maps, mission.MapTags)
		maps = filterMapsByTileset(maps, tileset)
		maps = filterMapsByVetoes(maps, mission.MapVetoes)
	end

	return maps
end
