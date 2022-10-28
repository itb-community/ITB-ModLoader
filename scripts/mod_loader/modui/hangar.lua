-- TODO: a lot of these are constants now, can cleanup code
local SURFACE_PLATFORM = sdlext.getSurface({path = "img/strategy/hangar_platform_L.png"})
local SURFACE_MEDAL = sdlext.getSurface({path = "img/ui/hangar/victory_2.png"})

local isSecretSquadUnlocked = false
local isSecretPilotsUnlocked = false
local isRandomOrCustomSquad = false
local secretPilots = {
	"Pilot_Mantis",
	"Pilot_Rock",
	"Pilot_Zoltan"
}

Hangar_lastProfileHadSecretPilots = false

function modApi:isSecretSquadAvailable()
	-- TODO: always available in AE, is this still needed?
	-- if not Profile then return false end
	--
	-- for i = 1, 8 do
	-- 	if Profile.squads[i] == false then
	-- 		return false
	-- 	end
	-- end

	return true
end

function HangarIsSecretSquadUnlocked()
	return isSecretSquadUnlocked
end

function HangarIsSecretPilotsUnlocked()
	return isSecretPilotsUnlocked
end

function HangarIsRandomOrCustomSquad()
	return isRandomOrCustomSquad
end

function IsSecretPilotsUnlocked(profile)
	profile = profile or Profile

	if profile == nil then
		return false
	end

	for i, v in ipairs(secretPilots) do
		if list_contains(Profile.pilots, v) then
			return true
		end
	end

	return false
end

local function isWindowOpen()
	return sdlext.isSquadSelectionWindowVisible() or
	       sdlext.isCustomizeSquadWindowVisible() or
	       sdlext.isPilotSelectionWindowVisible() or
	       sdlext.isDifficultySettingsWindowVisible() or
	       sdlext.isMechColorWindowVisible()
end

--[[
	If this returns true, it means that there is some sort of window
	open (pilots, squads, acievements, custom squad edit), and normal
	hangar UI is not accessible.
--]]
function IsHangarWindowState()
	return sdlext.isHangar() and isWindowOpen()
end

--[[
	If this returns true, it means that there are no windows open,
	and the player can interact with normal hangar UI
	(back/start game buttons, color picker, mech skill icons, etc.)
--]]
function IsHangarWindowlessState()
	return sdlext.isHangar() and not isWindowOpen()
end

function GetHangarOrigin()
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
	local clearedMechs = copy_table(selectedMechs)

	selectedSquad = nil
	for i = #selectedMechs, 1, -1 do
		selectedMechs[i] = nil
	end

	modApi.events.onHangarSquadCleared:dispatch(clearedSquad)
	modApi.events.onHangarMechsCleared:dispatch(clearedMechs)
end

local function populateSelectedMechs(fetchedMechs)
	if #selectedMechs > 0 then
		clearSelectedMechs()
	end

	for i = 1, 3 do
		selectedMechs[i] = fetchedMechs[i]
	end

	modApi.events.onHangarMechsSelected:dispatch(HangarGetSelectedMechs())

	if HangarIsRandomOrCustomSquad() or #fetchedMechs < 3 then
		-- Random or Custom squads have no associated squad id
		return
	end

	for squad_id, squad in pairs(modApi.mod_squads_by_id) do
		for i = 1, 3 do
			if squad[i+1] ~= fetchedMechs[i] then
				-- Mech mismatch, continue to next squad
				break
			end

			if i == 3 then
				-- Found a squad with 3 matching mech ids
				selectedSquad = squad_id
				modApi.events.onHangarSquadSelected:dispatch(squad_id)
				return
			end
		end
	end
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

				if
					isPrimaryCall             and
					IsHangarWindowlessState() and
					#fetchedMechs < 3
				then
					table.insert(fetchedMechs, k)

					if #fetchedMechs == 3 then
						for i, _ in ipairs(fetchedMechs) do
							if fetchedMechs[i] ~= selectedMechs[i] then
								populateSelectedMechs(fetchedMechs)
								break
							end
						end
					end
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

function HangarGetSelectedMechs()
	return copy_table(selectedMechs)
end

function HangarGetSelectedSquad()
	return selectedSquad
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

function GetBackButtonRect(languageIndex)
	return GetLanguageButton("btnBack", languageIndex)
end

function GetStartButtonRect(languageIndex)
	return GetLanguageButton("btnStart", languageIndex)
end

modApi.events.onHangarEntered:subscribe(function()
	overrideGetImages()

	Profile = modApi:loadProfile()
	isSecretSquadUnlocked = Profile.squads[11]
	isSecretPilotsUnlocked = Hangar_lastProfileHadSecretPilots or
							 IsSecretPilotsUnlocked()
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

local function onMechSelectionHidden()
	isRandomOrCustomSquad = isIrregularMedalHeight()
	clearSelectedMechs()

	modApi:scheduleHook(50, function()
		Profile = modApi:loadProfile()
	end)
end

modApi.events.onSquadSelectionWindowHidden:subscribe(onMechSelectionHidden)
modApi.events.onCustomizeSquadWindowHidden:subscribe(onMechSelectionHidden)

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

modApi.events.onHangarUiShown:subscribe(function()
	platform_height = nil
	isLeavingHangar = false

	isRandomOrCustomSquad = isIrregularMedalHeight()

	-- Clear fetchedMechs every frame in order to let the
	-- game populate the 3 first indices with the 3 first
	-- mechs. While in the hangar, these 3 mechs will be
	-- the mechs we have selected.
	modApi.events.onFrameDrawn:subscribe(clearFetchedMechs)
	modApi.events.onFrameDrawn:subscribe(trackPlatformMovement)
end)

modApi.events.onHangarUiHidden:subscribe(function()
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
