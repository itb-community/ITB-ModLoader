
local Scanner = Class.new()

Scanner.STATUS_RUNNING = "RUNNING"
Scanner.STATUS_STOPPED = "STOPPED"

Scanner.scandefs = {
	vital = require("scripts/mod_loader/memedit/scans_vital"),
	pawn = require("scripts/mod_loader/memedit/scans_pawn"),
	-- weapon = require("scripts/mod_loader/memedit/scans_weapon"),
	-- board = require("scripts/mod_loader/memedit/scans_board"),
	tile = require("scripts/mod_loader/memedit/scans_tile"),
	-- game = require("scripts/mod_loader/memedit/scans_game"),
}

local AccessEnum = {
	R = 0,
	W = 1,
	RW = 2,
}

local TypeEnum = {
	int = 0,
	unsigned_int = 1,
	byte = 2,
	bool = 3,
	double = 4,
	string = 5,
}

function Scanner:new()
	self.status = self.STATUS_STOPPED
	self.output = {}
	self.logLevel = 0
	self.logoutFirstPrompt = 10 -- 1/6 seconds
	self.logoutIterationInterval = 150 -- 2.5 seconds
	self.iteratingFunction = nil

	-- Events for the scanner.
	self.onStatusChanged = Event()
	self.onStarted = Event()
	self.onFinishedSuccessfully = Event()
	self.onFinishedUnsuccessfully = Event()

	-- Events for each individual scans.
	self.onScanStarted = Event()
	self.onScanSkipped = Event()
	self.onScanCompleted = Event()

	self.onScanCompleted:subscribe(function(completedScan)
		local id = completedScan.fullId
		local status = completedScan.failed and "Failed" or "Completed"

		LOGF(string.format("Memory Scanner - %s scan - %s: %s",
			status, id, completedScan:getResultString(self.logLevel)
		))

		self:addToOutput(completedScan)

		if completedScan.objType == "vital" then
			-- reload memedit with new vital functions
			local options = shallow_copy(self.output)
			options.debug = true
			options.silent = true
			modApi.memedit:load(options)
		end

		for i = #self.scans_blocked, 1, -1 do
			local scan = self.scans_blocked[i]
			remove_element(id, scan.prerequisiteScans)

			if #scan.prerequisiteScans == 0 then
				table.remove(self.scans_blocked, i)
				table.insert(self.scans_queued, scan)
			end
		end
	end)

	self:reset()
end

function Scanner:changeStatus(newStatus)
	local oldStatus = self.status
	self.status = newStatus

	self.onStatusChanged:dispatch(self, oldStatus, newStatus)

	return self
end

function Scanner:setIterator(iterator)
	self:destroyIterator()
	self.iterator = iterator
	modApi.events.onFrameDrawStart:subscribe(iterator)

	return self
end

function Scanner:destroyIterator()
	self:cleanupLastScan()
		:changeStatus(self.STATUS_STOPPED)

	if self.iterator then
		modApi.events.onFrameDrawStart:unsubscribe(self.iterator)
		self.iterator = nil
	end

	return self
end

function Scanner:reset()
	self:destroyIterator()

	-- arrays
	self.scans_succeeded = {}
	self.scans_failed = {}
	self.scans_queued = {}
	self.scans_blocked = {}

	for objType, bucket in pairs(self.scandefs) do
		for _, scandef in pairs(bucket) do
			if modApi:isVersion(scandef.gameVersion, modApi.gameVersion) then
				local scan = scandef()
				scan.objType = objType
				scan.scanner = self
				scan.fullId = objType.."."..scan.id

				if #scan.prerequisiteScans == 0 then
					table.insert(self.scans_queued, scan)
				else
					table.insert(self.scans_blocked, scan)
				end
			end
		end
	end

	self:changeStatus(self.STATUS_STOPPED)

	return self
end

function Scanner:cleanupLastScan()
	if self.lastScan then
		if self.lastScan:condition() then
			self.lastScan:reset()
		end

		self.lastScan = nil
	end

	return self
end

function Scanner:restart()
	self:cleanupLastScan()
		:reset()
		:start()

	return self
end

function Scanner:start()
	if self.iterator then
		return
	end

	modApi.memedit:load{ debug = true }

	local function condition()
		return self.status == self.STATUS_RUNNING
	end

	local function action()
		local scan = self.scans_queued[#self.scans_queued]

		if scan ~= self.lastScan then
			self:cleanupLastScan()
			self.currentScan = scan
			self.iteration = 0
			scan.iteration = 0

			if scan then
				self.onScanStarted:dispatch(scan)
			end
		end

		self.lastScan = scan

		if scan then
			self.iteration = self.iteration + 1

			if
				(self.iteration - self.logoutFirstPrompt)
				% self.logoutIterationInterval == 0
			then
				local action = scan.issue or "scanning..."
				local results = scan.results and #scan.results or "N/A"

				LOGF(
					"Memory Scanner - %s - %s - #iteration: %s - #results: %s",
					scan.fullId, action, scan.iteration, results
				)
			end

			if scan.completed then
				table.remove(self.scans_queued, #self.scans_queued)
				if scan.failed then
					table.insert(self.scans_failed, scan)
				else
					table.insert(self.scans_succeeded, scan)
				end
				self.onScanCompleted:dispatch(scan)
			else
				local ok, issue = scan:condition()
				if ok then
					scan.issue = nil
					scan.iteration = scan.iteration + 1
					scan:action()
				else
					scan.issue = issue
				end
			end
		end
	end

	local function destroy()
		if #self.scans_queued + #self.scans_blocked == 0 then
			self:stop()
		end

		return self.status == self.STATUS_STOPPED
	end

	local function iterate()
		if condition() then
			action()
		end

		if destroy() then
			self:destroyIterator()
		end
	end

	self:setIterator(iterate)
		:changeStatus(self.STATUS_RUNNING)
		:logStatus()

	self.onStarted:dispatch()

	return self
end

function Scanner:stop()
	self:destroyIterator()
		:logStatus()

	if self:isSuccess() then
		self.onFinishedSuccessfully:dispatch(self.output)
	else
		self.onFinishedUnsuccessfully:dispatch()
	end

	self.onFinishedSuccessfully:unsubscribeAll()
	self.onFinishedUnsuccessfully:unsubscribeAll()

	return self
end

function Scanner:skip()
	self:cleanupLastScan()

	if #self.scans_queued > 0 then
		local scan = self.scans_queued[#self.scans_queued]
		table.remove(self.scans_queued, #self.scans_queued)
		table.insert(self.scans_queued, 1, scan)
		LOGF("Memory Scanner - skipping %s and rescheduling it for last", scan.fullId)

		self.onScanSkipped:dispatch(scan)
	end

	return self
end

function Scanner:isSuccess()
	return true
		and #self.scans_succeeded > 0
		and #self.scans_queued == 0
		and #self.scans_blocked == 0
		and #self.scans_failed == 0
end

function Scanner:logStatus(logLevel)
	local scans = {}
	local separator = " "
	local output = {
		"======== Memory Scanner ========",
		"- Status: %s",
		"- Scans succeeded: %s",
		"- Scans failed: %s",
		"- Scans queued: %s",
		"- Scans blocked: %s",
		"\n%s"
	}

	-- logLevel:
	-- 0: Compact - single line + each failed scan.
	-- 1: Mutiline, but same information.
	-- 2: Additional status for completed/queued/blocked scans.
	logLevel = logLevel or self.logLevel

	if logLevel >= 1 then
		-- Multiline output
		separator = "\n"

		-- Status for completed, queued and blocked scans.
		if logLevel >= 2 then
			for _, scan in ipairs(self.scans_succeeded) do
				scans[#scans+1] = string.format("- [%s] completed with result: %s\n",
									scan.fullId, scan:getResultString())
			end
			for _, scan in ipairs(self.scans_queued) do
				scans[#scans+1] = string.format("- [%s] is queued with result(s): %s\n",
									scan.fullId, scan:getResultString(self.logLevel))
			end
			for _, scan in ipairs(self.scans_blocked) do
				scans[#scans+1] = string.format("- [%s] is blocked by: %s\n",
									scan.fullId, tostring(scan.prerequisiteScans[1]))
			end
		end
	end

	-- Always log out each failed scan.
	for _, scan in ipairs(self.scans_failed) do
		scans[#scans+1] = string.format("- [%s] failed\n", scan.fullId)
	end

	LOG(string.format(
		table.concat(output, separator),
		self.status,
		#self.scans_succeeded,
		#self.scans_failed,
		#self.scans_queued,
		#self.scans_blocked,
		table.concat(scans)
	))

	return self
end

function Scanner:addToOutput(scan)
	if scan.failed then
		return
	end

	local objType = scan.objType
	local objList = self.output[objType]

	if objList == nil then
		objList = {}
		self.output[objType] = objList
	end

	if scan.access then
		objList[scan.id] = {
				scan.result,
				AccessEnum[scan.access],
				TypeEnum[scan.dataType]
			}
	else
		objList[scan.id] = scan.result
	end
end

function Scanner:getOutput()
	return self.output
end

return Scanner
