
function CreatePilotPersonality(label, name)
	local t = PilotPersonality:new()

	-- Name of the pilot, leave nil for random name
	t.Name = name
	-- Pilot label, used in debug messages
	t.Label = label or "NULL"

	return t
end

PilotListExtended = shallow_copy(PilotList)

function CreatePilot(data)
	_G[data.Id] = Pilot:new(data)

	-- Make sure we don't create duplicates if the PilotList
	-- already contains entry for this pilot
	if data.Rarity ~= 0 and not list_contains(PilotListExtended, data.Id) then
		if #PilotList < 13 then
			PilotList[#PilotList + 1] = data.Id
		end
		PilotListExtended[#PilotListExtended + 1] = data.Id
	end
end

function IsTestMechScenario()
	if not Game then return false end

	local p0 = Game:GetPawn(0) ~= nil
	local p1 = Game:GetPawn(1) ~= nil
	local p2 = Game:GetPawn(2) ~= nil

	-- In test mech scenario, only one of the three
	-- player mechs will not be nil.
	return (    p0 and not p1 and not p2) or
	       (not p0 and     p1 and not p2) or
	       (not p0 and not p1 and     p2)
end

--[[
	Returns the table instance of the current mission. Returns nil when not in a mission.
--]]
function GetCurrentMission()
	if IsTestMechScenario() or sdlext.isMapEditor() then
		return Mission_Test
	end

	return modApi.current_mission
end

Emitter_Blank = Emitter:new({
    timer = 0,
    lifespan = 0,
    max_particles = 0
})


---------------------------------------------------------------
-- Screenpoint to tile conversion

GetUiScale = function()
	-- ScreenSizeY() reports (window height + 1), which leads to a
	-- slightly different Y scale than in reality. However, Y scale
	-- always matches the X scale, even when the window is twice as
	-- tall as it is wide, therefore we can just use X scale for
	-- both axes.
	if Settings.stretched == 1 then
		return screen:w() / ScreenSizeX()
	end

	return 1
end

initializeMouseTile = function()
	--[[
		Returns currently highlighted board tile, or nil.
	--]]
	function mouseTile()
		-- Use custom table instead of the existing Point class, since Point
		-- can only hold integer values and automatically rounds them.
		return screenPointToTile({ x = sdl.mouse.x(), y = sdl.mouse.y() }, false)
	end

	--[[
		Returns currently highlighted board tile and closest tile edge as DIR, or nil.
	--]]
	function mouseTileAndEdge()
		return screenPointToTile({ x = sdl.mouse.x(), y = sdl.mouse.y() }, true)
	end

	function getScreenRefs(scale)
		scale = scale or GetBoardScale()

		local tw = 28
		local th = 21

		-- Top corner of the (0, 0) tile
		local tile00 = {
			x = screen:w() / 2,
			y = screen:h() / 2 - 8 * th * scale
		}

		tile00.y = tile00.y + (30 - 10 * scale)

		local lineX = function(x) return x * th/tw end
		local lineY = function(x) return -lineX(x) end

		return tile00, lineX, lineY, tw, th
	end

	local function computeTile(tilex, tiley, tilew, tileh, sourcePointBoardSpace)
		return {
			x = sourcePointBoardSpace.x - tilew * (tilex - tiley),
			y = sourcePointBoardSpace.y - tileh * (tilex + tiley)
		}
	end

	local function isPointAboveLine(point, lineFn)
		return point.y >= lineFn(point.x)
	end

	local function tileContains(tile, lineX, lineY)
		return isPointAboveLine(tile, lineX)
			and isPointAboveLine(tile, lineY)
	end

	local function computeClosestTileEdge(sourcePointTileSpaceTop, tileh)
		local sourcePointTileSpaceCenter = {
			x = sourcePointTileSpaceTop.x,
			y = sourcePointTileSpaceTop.y - tileh
		}

		if
			sourcePointTileSpaceCenter.x >= 0 and
			sourcePointTileSpaceCenter.y <  0
		then
			return DIR_UP
		elseif
			sourcePointTileSpaceCenter.x >= 0 and
			sourcePointTileSpaceCenter.y >= 0
		then
			return DIR_RIGHT
		elseif
			sourcePointTileSpaceCenter.x <  0 and
			sourcePointTileSpaceCenter.y >= 0
		then
			return DIR_DOWN
		else
			return DIR_LEFT
		end
	end

	--[[
		Returns a board tile at the specified point on the screen, or nil.
	--]]
	function screenPointToTile(sourcePointScreenSpace, findTileEdge)
		if not Board then return nil end

		local scale = GetBoardScale()

		local tile00, lineX, lineY, tw, th = getScreenRefs(scale)

		-- Change sourcePointScreenSpace to be relative to the (0, 0) tile
		-- and move to unscaled space.
		local sourcePointBoardSpace = {
			x = (sourcePointScreenSpace.x - tile00.x) / scale,
			y = (sourcePointScreenSpace.y - tile00.y) / scale
		}

		-- Start at the end of the board and move backwards.
		-- That way we only need to check 2 lines instead of 4 on each tile.
		-- The tradeoff is that we need to check an additional row and column
		-- of tiles outside of the board.
		local bsize = Board:GetSize()
		for tileY = bsize.y, 0, -1 do
			for tileX = bsize.x, 0, -1 do
				local tile = computeTile(tileX, tileY, tw, th, sourcePointBoardSpace)
				if tileContains(tile, lineX, lineY) then
					if tileY == bsize.y or tileX == bsize.x then
						-- outside of the board
						return nil
					end

					if findTileEdge then
						local closestTileEdge = computeClosestTileEdge(tile, th, sourcePointBoardSpace)

						return Point(tileX, tileY), closestTileEdge
					else
						return Point(tileX, tileY)
					end
				end
			end
		end

		return nil
	end
end

initializeMouseTile()
-- Setup mouseTile-related functions again each time mods are loaded,
-- since every version of modApiExt overwrites these globals on init,
-- and then most recent on each load.
modApi.events.onModsLoaded:subscribe(initializeMouseTile)

function isUserdataPoint(var)
	return type(var) == 'userdata' and type(var.x) == 'number' and type(var.y) == 'number'
end

function alphanum(a, b)
	local function conv(s)
		local res, dot = "", ""
		for n, m, c in tostring(s):gmatch"(0*(%d*))(.?)" do
			if n == "" then
				dot, c = "", dot..c
			else
				res = res..(dot == "" and ("%03d%s"):format(#m, m)
						or "."..n)
				dot, c = c:match"(%.?)(.*)"
			end
			res = res..c:gsub(".", "\0%0")
		end
		return res
	end

	local ca, cb = conv(a), conv(b)
	return ca < cb or ca == cb and a < b
end


local function less_than_comp(a, b)
	return a < b
end

--- Sort a table. This interface should be identical to table.sort().
--- The difference to table.sort() is that this sort is stable.
---
--- Parameters:
---
--- list - The table to sort (we do an in-place sort!).
---
--- comp - Comparator used for the sorting
function stablesort(list, comp)
	local comp = comp or less_than_comp

	-- A table could contain non-integer keys which we have to ignore.
	local num = 0
	for k, v in ipairs(list) do
		num = num + 1
	end

	if num <= 1 then
		-- Nothing to do
		return
	end

	-- Sort until everything is sorted :)
	local sorted = false
	local n = num
	while not sorted do
		sorted = true
		for i = 1, n - 1 do
			-- Two equal elements won't be swapped -> we are stable
			if comp(list[i+1], list[i]) then
				local tmp = list[i]
				list[i] = list[i+1]
				list[i+1] = tmp

				sorted = false
			end
		end
		-- The last element is now guaranteed to be in the right spot
		n = n - 1
	end
end
