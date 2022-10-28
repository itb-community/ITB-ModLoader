-- TODO: a lot of these are constants now, can cleanup code
local SURFACE_PLATFORM
local SURFACE_MEDAL

modApi.events.onFtldatFinalized:subscribe(function()
	SURFACE_PLATFORM = sdlext.surface("img/strategy/hangar_platform_L.png")
	SURFACE_MEDAL = sdlext.surface("img/ui/hangar/victory_2.png")
end)

local isRandomOrCustomSquad = false
local isMechlessCustomSquad = false

local function isWindowOpen()
	return sdlext.isSquadSelectionWindowVisible() or
	       sdlext.isCustomizeSquadWindowVisible() or
	       sdlext.isPilotSelectionWindowVisible() or
	       sdlext.isDifficultySettingsWindowVisible() or
	       sdlext.isMechColorWindowVisible()
end

local function isSquadSelectionOpen()
	return false
		or sdlext.isSquadSelectionWindowVisible()
		or sdlext.isCustomizeSquadWindowVisible()
end

local hangar = {}
modApi.hangar = hangar

--[[
	If this returns true, it means that there is some sort of window
	open (pilots, squads, acievements, custom squad edit), and normal
	hangar UI is not accessible.
--]]
function hangar:isWindowState()
	return sdlext.isHangar() and isWindowOpen()
end

--[[
	If this returns true, it means that there are no windows open,
	and the player can interact with normal hangar UI
	(back/start game buttons, color picker, mech skill icons, etc.)
--]]
function hangar:isWindowlessState()
	return sdlext.isHangar() and not isWindowOpen()
end

function hangar:getOrigin()
	local origin = GetScreenCenter()

	-- Hangar UI is drawn at a different offset when
	-- window height is less than 1032px.
	-- This probably scales at certain thresholds when
	-- the UI can be scaled cleanly, but I can't test
	-- resolutions greater than 1920x1080, and it's
	-- difficult to extrapolate from one data point.
	if ScreenSizeY() < 1032 then
		origin.x = origin.x - 460
		origin.y = origin.y - 335
	else
		origin.x = origin.x - 385
		origin.y = origin.y - 285
	end

	return origin
end


-- //////////////////////////////////////////////////////////////////////
-- Current mech detection

local selectedSquad = nil
local selectedSquadChoice = nil
local selectedSquadIndex = nil
local selectedMechs = {}
local fetchedMechs = {}
local oldGetImages = {}
local pawns = {}

local function clearFetchedMechs()
	for i = #fetchedMechs, 1, -1 do
		fetchedMechs[i] = nil
	end
end

local function clearSelectedMechs()
	local clearedSquad = selectedSquad
	local clearedSquadChoice = selectedSquadChoice
	local clearedSquadIndex = selectedSquadIndex
	local clearedMechs = copy_table(selectedMechs)

	selectedSquad = nil
	selectedSquadChoice = nil
	selectedSquadIndex = nil
	for i = #selectedMechs, 1, -1 do
		selectedMechs[i] = nil
	end

	if clearedSquad then
		modApi.events.onHangarSquadCleared:dispatch(clearedSquad, clearedSquadChoice, clearedSquadIndex)
		modApi.events.onHangarMechsCleared:dispatch(clearedMechs)
	end
end

local function tryPopulateSelectedSquad(squadId, squad)
	for i = 1, 3 do
		if squad[i+1] ~= selectedMechs[i] then
			-- Mech mismatch, continue to next squad
			break
		end

		if i == 3 then
			-- Found a squad with 3 matching mech ids
			selectedSquad = squadId

			-- Find corresponding squad index
			for index, squadData in ipairs(modApi.mod_squads) do
				if squadData.id == squadId then
					selectedSquadIndex = index
					break
				end
			end

			-- Find corresponding squad choice
			for index, redirectedIndex in ipairs(modApi.squadIndices) do
				if redirectedIndex == selectedSquadIndex then
					selectedSquadChoice = modApi:squadIndex2Choice(index)
					break
				end
			end

			return true
		end
	end
end

local function populateSelectedMechs(fetchedMechs)
	if #selectedMechs > 0 then
		clearSelectedMechs()
	end

	for i = 1, 3 do
		selectedMechs[i] = fetchedMechs[i]
	end

	if isRandomOrCustomSquad then
		selectedSquad = "Custom"
		selectedSquadChoice = -1
		selectedSquadIndex = -1
	else
		Assert.True(#selectedMechs == 3)

		for squadId, squad in pairs(modApi.mod_squads_by_id) do
			if tryPopulateSelectedSquad(squadId, squad) then
				break
			end
		end
	end

	Assert.True(true
		and selectedSquad ~= nil
		and selectedSquadChoice ~= nil
		and selectedSquadIndex ~= nil
	)

	modApi.events.onHangarSquadSelected:dispatch(selectedSquad, selectedSquadChoice, selectedSquadIndex)
	modApi.events.onHangarMechsSelected:dispatch(hangar:getSelectedMechs())
end

local function defaultGetImage(self)
	return self.Image
end

local function restoreGetImages()
	for _, id in ipairs(pawns) do
		_G[id].GetImage = oldGetImages[id]
	end

	pawns = {}
end

local function overrideGetImages()
	if #pawns ~= 0 then
		restoreGetImages()
	end

	local wasPrimaryCallExecuted = false

	for k, v in pairs(_G) do
		if type(v) == "table" and v ~= PawnTable and v.Health and v.Image then
			table.insert(pawns, k)

			if v.GetImage then
				oldGetImages[k] = v.GetImage
			else
				oldGetImages[k] = defaultGetImage
			end

			v.GetImage = function(self)
				local isPrimaryCall = not wasPrimaryCallExecuted

				if true
					and isPrimaryCall
					and hangar:isWindowlessState()
					and #fetchedMechs < 3
				then
					table.insert(fetchedMechs, k)
				end

				if isPrimaryCall then
					wasPrimaryCallExecuted = true
				end
				local result = oldGetImages[k](self)
				if isPrimaryCall then
					wasPrimaryCallExecuted = false
				end

				return result
			end
		end
	end
end

function hangar:getSelectedMechs()
	return copy_table(selectedMechs)
end

function hangar:getSelectedSquad()
	return selectedSquad
end

function hangar:getSelectedSquadChoice()
	return selectedSquadChoice
end

function hangar:getSelectedSquadIndex()
	return selectedSquadIndex
end

-- Associated entries in Buttons global are not updated to reflect changing dimensions,
-- need to hardcode them.
local languageRectsMap
local function getLanguageRectsMap()
	if not languageRectsMap then
		languageRectsMap = {
			-- TODO: these very much have moved
			["btnBack"] = {
				[Languages.English] = { x = 520, w = 103 },
				[Languages.Chinese_Simplified] = { x = 520, w = 89 },
				[Languages.French] = { x = 307, w = 141 },
				[Languages.German] = { x = 429, w = 141 },
				[Languages.Italian] = { x = 471, w = 161 },
				[Languages.Polish] = { x = 280, w = 141 },
				[Languages.Portuguese_Brazil] = { x = 481, w = 129 },
				[Languages.Russian] = { x = 479, w  = 125 },
				[Languages.Spanish] = { x = 459, w = 121 },
				[Languages.Japanese] = { x = 517, w = 106 },
			},
			["btnStart"] = {
				[Languages.English] = { x = 803, w = 117 },
				[Languages.Chinese_Simplified] = { x = 830, w = 89 },
				[Languages.French] = { x = 623, w = 297 },
				[Languages.German] = { x = 763, w = 157 },
				[Languages.Italian] = { x = 807, w = 113 },
				[Languages.Polish] = { x = 645, w = 274 },
				[Languages.Portuguese_Brazil] = { x = 785, w = 135 },
				[Languages.Russian] = { x = 779, w = 141 },
				[Languages.Spanish] = { x = 755, w = 165 },
				[Languages.Japanese] = { x = 798, w = 122 },
			},
		}
	end

	return languageRectsMap
end

local function GetLanguageButton(name, languageIndex)
	languageIndex = languageIndex or modApi:getLanguageIndex()
	local buttons = getLanguageRectsMap()[name]
	return buttons[languageIndex] or buttons[Languages.English]
end

function hangar:getBackButtonRect()
	return GetLanguageButton("btnBack", languageIndex)
end

function hangar:getStartButtonRect()
	return GetLanguageButton("btnStart", languageIndex)
end

modApi.events.onHangarEntered:subscribe(function()
	overrideGetImages()
end)

modApi.events.onHangarLeaving:subscribe(function()
	restoreGetImages()
end)

local expectedMedalOffsets = { 186, 209 }
local function isIrregularMedalHeight()
	-- if victory medals are drawn at y coordinate 186
	-- relative to hangar origin, we know that we have
	-- selected Random or Custom squad.
	-- If this value changes with a game update,
	-- we will default to guessing that we are looking
	-- at a regular squad until the mod loader can
	-- be updated as well.
	if SURFACE_MEDAL:wasDrawn() then
		local medalOffset = SURFACE_MEDAL.y - GetHangarOrigin().y

		if not list_contains(expectedMedalOffsets, medalOffset) then
			LOGF("Unexpected medal offset %s detected - Notify mod loader maintainers", medalOffset)
		end

		return medalOffset == 186
	end

	return false
end

-- Update populated mechs when we detect fetchedMechs is of size 3
-- Remove hook if we detect that we are no longer in the hangar,
-- or a squad selection window is open.
local function conditionalPopulateSelectedMechs()
	modApi:conditionalHook(
		function()
			return false
				-- Remove hook if not in the hangar
				or not sdlext.isHangar()
				or isSquadSelectionOpen()
				or #fetchedMechs == 3
		end,
		function()
			if true
				and sdlext.isHangar()
				and not isSquadSelectionOpen()
			then
				populateSelectedMechs(fetchedMechs)
			end
		end
	)
end

local function populateSelectedSquad()
	isRandomOrCustomSquad = isIrregularMedalHeight()
	isMechlessCustomSquad = SURFACE_PLATFORM:wasDrawn() == false

	clearFetchedMechs()
	clearSelectedMechs()

	if isMechlessCustomSquad then
		populateSelectedMechs({})
	else
		conditionalPopulateSelectedMechs()
	end
end

modApi.events.onSquadSelectionWindowHidden:subscribe(populateSelectedSquad)
modApi.events.onCustomizeSquadWindowHidden:subscribe(populateSelectedSquad)

local old_screen_y = nil
local platform_height = nil
local isLeavingHangar = false
local function trackPlatformMovement()
	if isLeavingHangar then return end

	if SURFACE_PLATFORM:wasDrawn() then
		-- Resizing the screen can make it appear
		-- the platform is moving, since the
		-- whole ui is being repositioned to fit
		-- within the new extents.
		local new_screen_y = ScreenSizeY()
		if old_screen_y ~= new_screen_y then
			old_screen_y = new_screen_y
			platform_height = SURFACE_PLATFORM.y
		end

		if platform_height == nil then
			platform_height = SURFACE_PLATFORM.y
		elseif SURFACE_PLATFORM.y > platform_height then
			isLeavingHangar = true

			local isStartingGame = true
			modApi.events.onHangarLeaving:dispatch(isStartingGame)
		end
	end
end

modApi.events.onHangarEntered:subscribe(function()
	platform_height = nil
	isLeavingHangar = false

	populateSelectedSquad()

	-- Clear fetchedMechs every frame in order to let the
	-- game populate the 3 first indices with the 3 first
	-- mechs. While in the hangar, these 3 mechs will be
	-- the mechs we have selected.
	modApi.events.onFrameDrawn:subscribe(clearFetchedMechs)
	modApi.events.onFrameDrawn:subscribe(trackPlatformMovement)
end)

modApi.events.onHangarUiHidden:subscribe(function()
	clearFetchedMechs()
	clearSelectedMechs()

	if not isLeavingHangar then
		local isStartingGame = false
		modApi.events.onHangarLeaving:dispatch(isStartingGame)
	end

	local unsubscribe_successful = modApi.events.onFrameDrawn:unsubscribe(clearFetchedMechs)
	Assert.True(unsubscribe_successful, "Unsubscribe clearFetchedMechs")
	local unsubscribe_successful = modApi.events.onFrameDrawn:unsubscribe(trackPlatformMovement)
	Assert.True(unsubscribe_successful, "Unsubscribe trackPlatformMovement")
end)
