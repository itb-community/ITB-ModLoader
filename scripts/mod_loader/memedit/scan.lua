
local LOG_MAX_RESULTS = 5

local function newClass(base)
	local o = Class.new()

	for i,v in pairs(base) do
		o[i] = v
	end

	return o
end

local memsize = {
	int = 4,
	unsigned_int = 4,
	byte = 1,
	bool = 1,
	double = 8,
	string = 4,
}

local Scan = newClass{
	gameVersion = "0.0.0",
	objType = "undefined",
	id = "undefined",
	new = function(self)
		self.results = shallow_copy(self.results)
		self.prerequisiteScans = shallow_copy(self.prerequisiteScans)
	end,

	-- An array containing all address results of the scan.
	results = nil,

	-- An array or id's of other scans that needs to have been completed,
	-- before this scan can begin.
	prerequisiteScans = {},

	access = nil,
	-- The datatype of the address we are scanning for.
	dataType = "int",

	-- The current iteration of this scan.
	iteration = 0,

	-- For some addresses, there will be multiple hits that fits the criteria
	-- Define how many results we expect, and which of the results we select.
	expectedResults = 1,
	expectedResultIndex = 1,

	-- Tracker for if a scan has multiple actions that run in sequence.
	nextAction = 1,

	condition = function(self) return true end,
	cleanup = function(self) end,
	action = function(self)
		if self.actions then
			self.actions[self.nextAction](self)
			self.nextAction = self.nextAction + 1

			if self.nextAction > #self.actions then
				self.nextAction = 1
			end
		end
	end,
	reset = function(self)
		self.nextAction = 1
		self:cleanup()
	end,

	succeed = function(self, result)
		self.result = result
		self.failed = false
		self.completed = true
	end,

	fail = function(self)
		self.result = nil
		self.failed = true
		self.completed = true
	end,

	getResultString = function(self, logLevel)
		local result = "N/A"

		if self.result then
			result = string.format("0x%x", self.result)

		elseif self.results and #self.results > 0 then
			if logLevel == 0 then
				result = string.format("#%s alternate addresses", #self.results)
			else
				local results = self.results

				if #self.results > LOG_MAX_RESULTS then
					results = {}
					for i = 1, LOG_MAX_RESULTS do
						results[i] = self.results[i]
					end
				end

				result = table.concat(results, ", ")
							:gsub("%x+", function(s) return string.format("0x%x", s) end)
			end
		end

		return result
	end,

	search = function(self, base, from, to, val, dataType)
		local dll = modApi.memedit.dll

		dataType = dataType or self.dataType

		if type(base) == "userdata" then
			base = dll.debug.getObjAddr(base)
		end
		if base == nil then
			LOG(debug.traceback())
		end

		local memget = {
			int = dll.debug.getAddrInt,
			bool = dll.debug.getAddrBool,
			byte = dll.debug.getAddrByte,
			-- getAddrValue is much safer than getAddrString.
			-- getAddrValue will return a string if possible.
			-- getAddrString can cause crashes when used on
			-- non-string values.
			string = dll.debug.getAddrValue,
		}

		local get = memget[dataType]
		local step = memsize[dataType]
		local results = self.results

		if results == nil then
			results = {}
			self.results = results

			for delta = from, to - step, step do
				if val == get(base + delta) then
					results[#results+1] = delta
				end
			end
		else
			for i = #results, 1, -1 do
				local delta = results[i]
				if val ~= get(base + delta) then
					-- swap and remove
					results[i] = results[#results]
					results[#results] = nil
				end
			end
		end
	end,

	searchPawn = function(self, pawn, val, dataType)
		local vital = self.scanner.output.vital

		if false
			or pawn == nil
			or vital.size_pawn == nil
		then
			return
		end

		self:search(pawn, 0, vital.size_pawn, val, dataType)
	end,

	searchTile = function(self, p, val, dataType)
		local dll = modApi.memedit.dll
		local vital = self.scanner.output.vital

		if false
			or Board == nil
			or vital.delta_rows == nil
			or vital.step_rows == nil
			or vital.size_tile == nil
		then
			return
		end

		local boardAddr = dll.debug.getObjAddr(Board)
		local rowAddr = dll.debug.getAddrInt(boardAddr + vital.delta_rows)
		local columnAddr = dll.debug.getAddrInt(rowAddr + vital.step_rows * p.x)
		local tileAddr = columnAddr + vital.size_tile * p.y

		self:search(tileAddr, 0, vital.size_tile, val, dataType)
	end,

	searchWeapon = function(self, pawn, weaponIndex, val, dataType)
		local vital = self.scanner.output.vital
		local dll = modApi.memedit.dll

		if false
			or vital.size_pawn == nil
			or vital.delta_weapons == nil
			or vital.size_weapon == nil
		then
			self:fail()
			return
		end

		local pawnAddr = dll.debug.getObjAddr(pawn)
		local weaponListAddr = dll.debug.getAddrInt(pawnAddr + vital.delta_weapons)
		local weaponAddr = dll.debug.getAddrInt(weaponListAddr + weaponIndex * 0x8)

		self:search(weaponAddr, 0, delta.size_weapon, val, dataType)
	end,

	evaluateResults = function(self)
		if self.results == nil then
			self:fail()
		elseif #self.results < self.expectedResults then
			self:fail()
		elseif #self.results == self.expectedResults then
			table.sort(self.results, function(a,b) return a < b end)
			self:succeed(self.results[self.expectedResultIndex])
		end
	end,
}

return Scan
