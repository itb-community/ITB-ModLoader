local languageDisplayNames = {}
languageDisplayNames[1] = Language_English
languageDisplayNames[2] = Language_Chinese_Simplified
languageDisplayNames[3] = Language_French
languageDisplayNames[4] = Language_German
languageDisplayNames[5] = Language_Italian
languageDisplayNames[6] = Language_Polish
languageDisplayNames[7] = Language_Portuguese_Brazil
languageDisplayNames[8] = Language_Russian
languageDisplayNames[9] = Language_Spanish
languageDisplayNames[10] = Language_Japanese

local languageIndices = {
	English = 1,
	Chinese_Simplified = 2,
	French = 3,
	German = 4,
	Italian = 5,
	Polish = 6,
	Portuguese_Brazil = 7,
	Russian = 8,
	Spanish = 9,
	Japanese = 10
}

function modApi:getLanguage()
	return Settings.language
end

function modApi:listLanguages()
	return copy_table(languageIndices)
end

function modApi:getLanguageDisplayName()
	return languageDisplayNames[self:getLanguage()]
end

function modApi:getText(id, r1, r2, r3)
	assert(type(id) == "string", "Expected string, got: "..type(id))
	local result = GetText(id, r1, r2, r3)

	if not result then
		LOG("Attempt to reference non-existing text id '"..id.."', "..debug.traceback())
	end

	return result
end

local function setupDictionary_English()
	local dictionary = {}

	dictionary["Button_Ok"] = "OK"
	dictionary["Button_Yes"] = "YES"
	dictionary["Button_No"] = "NO"
	dictionary["Button_DisablePopup"] = "GOT IT, DON'T TELL ME AGAIN"
	dictionary["ButtonTooltip_DisablePopup"] = "This dialog will not be shown anymore. You can re-enable it in Mod Content > Configure Mod Loader."

	dictionary["MainMenu_Button_ModContent"] = "Mod Content"
	dictionary["ModContent_FrameTitle"] = "Mod Content"

	dictionary["ModContent_Button_ModConfig"] = "Configure Mods"
	dictionary["ModContent_ButtonTooltip_ModConfig"] = "Turn on and off individual mods, and configure any settings they might have."
	dictionary["ModConfig_FrameTitle"] = "Mod Configuration"

	dictionary["ModContent_Button_SquadSelect"] = "Edit Squads"
	dictionary["ModContent_ButtonTooltip_SquadSelect"] = "Select which squads will be available to pick."
	dictionary["SquadSelect_FrameTitle"] = "Squad Selection"
	dictionary["SquadSelect_Total"] = "Total selected"
	dictionary["SquadSelect_Default_Text"] = "Default"
	dictionary["SquadSelect_Default_Tooltip"] = "Select only vanilla squads."
	dictionary["SquadSelect_Random_Text"] = "Random"
	dictionary["SquadSelect_Random_Tooltip"] = "Select random squads."

	dictionary["ModContent_Button_PilotArrange"] = "Arrange Pilots"
	dictionary["ModContent_ButtonTooltip_PilotArrange"] = "Select which pilots will be available to pick."
	dictionary["PilotArrange_ButtonTooltip_Off"] = "Pilots can only be arranged before the New Game button is pressed.\n\nRestart the game to be able to arrange pilots."
	dictionary["PilotArrange_FrameTitle"] = "Arrange Pilots"

	dictionary["ModContent_Button_ModLoaderConfig"] = "Configure Mod Loader"
	dictionary["ModContent_ButtonTooltip_ModLoaderConfig"] = "Configure some features of the mod loader."
	dictionary["ModLoaderConfig_FrameTitle"] = "Mod Loader Configuration"

	dictionary["ModLoaderConfig_Text_LogLevel"] = "Logging level"
	dictionary["ModLoaderConfig_Tooltip_LogLevel"] = "Controls where the game's logging messages are printed."
	dictionary["ModLoaderConfig_DD_LogLevel_0"] = "None"
	dictionary["ModLoaderConfig_DD_LogLevel_1"] = "Only console"
	dictionary["ModLoaderConfig_DD_LogLevel_2"] = "File and console"

	dictionary["ModLoaderConfig_Text_Caller"] = "Print Caller Information"
	dictionary["ModLoaderConfig_Tooltip_Caller"] = "Include timestamp and stacktrace in LOG messages."

	dictionary["ModLoaderConfig_Text_DevMode"] = "Development Mode"
	dictionary["ModLoaderConfig_Tooltip_DevMode"] = "Enable debug mod loader features. May disrupt normal gameplay.\n\nYou shouldn't enable this, unless you're a mod creator or mod loader maintainer."

	dictionary["ModLoaderConfig_Text_FloatyTooltips"] = "Attach Tooltips To Mouse Cursor"
	dictionary["ModLoaderConfig_Tooltip_FloatyTooltips_On"] = "Tooltips follow the mouse cursor around."
	dictionary["ModLoaderConfig_Tooltip_FloatyTooltips_Off"] = "Tooltips show to the side of the UI element that spawned them, similar to the game's own tooltips."

	dictionary["ModLoaderConfig_Text_ProfileConfig"] = "Profile-Specific Configuration"
	dictionary["ModLoaderConfig_Tooltip_ProfileConfig"] = "Configuration for the mod loader and individual mods will be remembered per profile, instead of globally.\n\nNote: with this option enabled, switching profiles will require you to restart the game to apply the different mod configurations."

	dictionary["ModLoaderConfig_Text_ScriptError"] = "Show Script Error Popup"
	dictionary["ModLoaderConfig_Tooltip_ScriptError"] = "Show an error popup at startup if a mod fails to mount, init, or load."

	dictionary["ModLoaderConfig_Text_OldVersion"] = "Show Mod Loader Outdated Popup"
	dictionary["ModLoaderConfig_Tooltip_OldVersion"] = "Show a popup if the mod loader is out-of-date for installed mods."

	dictionary["ModLoaderConfig_Text_ResourceError"] = "Show Resource Error Popup"
	dictionary["ModLoaderConfig_Tooltip_ResourceError"] = "Show an error popup at startup if the mod loader fails to load the game's resources."

	dictionary["ModLoaderConfig_Text_GamepadWarning"] = "Show Gamepad Warning Popup"
	dictionary["ModLoaderConfig_Tooltip_GamepadWarning"] = "Show a warning popup when Gamepad Mode is enabled."

	dictionary["ModLoaderConfig_Text_RestartReminder"] = "Show Restart Reminder Popup"
	dictionary["ModLoaderConfig_Tooltip_RestartReminder"] = "Show a popup reminding to restart the game when enabling mods."

	dictionary["ModLoaderConfig_Text_ProfileFrame"] = "Show Profile Settings Change Popup"
	dictionary["ModLoaderConfig_Tooltip_ProfileFrame"] = "Show a popup reminding to restart the game when switching profiles with Profile-Specific Configuration enabled."

	dictionary["ScriptError_FrameTitle"] = "Script Error"
	dictionary["ScriptError_FrameText_Mount"] = "Unable to mount mod at [%s]:\n%s"

	dictionary["RestartRequired_FrameTitle"] = "Restart Required"
	dictionary["RestartRequired_FrameText"] = "You have enabled one or more mods. In order to apply them, game restart is required."

	dictionary["OldVersion_FrameTitle"] = "Mod Loader Outdated"
	dictionary["OldVersion_FrameText"] = "The following mods could not be loaded, because they require a newer version of the mod loader:\n\n%s\nYour installed version: %s"
	dictionary["OldVersion_ListEntry"] = "- [%s] requires at least version %s."

	dictionary["ResourceError_FrameTitle"] = "Resource Error"
	dictionary["ResourceError_FrameText"] =
	"The mod loader failed to load game resources. "..
			"This will cause some elements of modded UI to be invisible or incorrectly positioned. "..
			"This happens sometimes, but so far the cause is not known.\n\n"..
			"Restarting the game should fix this."

	dictionary["GamepadWarning_FrameTitle"] = "Gamepad Warning"
	dictionary["GamepadWarning_FrameText"] =
	"Gamepad Mode has been enabled.\n\n" ..
			"The mod loader does not support input via a gamepad. Since many of the mod loader's features rely on detecting " ..
			"mouse and keyboard inputs, it is recommended to uninstall the mod loader if you plan to play with a gamepad."

	dictionary["ProfileSettings_FrameTitle"] = "Profile Settings Changed"
	dictionary["ProfileSettings_FrameText"] = "Active profile has been changed, and profile-specific configuration is enabled.\n\nYou need to restart the game in order to apply the changes made by the profile's configuration."

	dictionary["VersionString"] = "Mod loader version: "

	dictionary["Difficulty_Custom_Note"] = "Note: this is a modded difficulty level. It won't change anything without mods providing content for this difficulty."

	dictionary["Difficulty_Name_VeryHard"] = "V. Hard"
	dictionary["Difficulty_Title_VeryHard"] = "Very Hard Mode"
	dictionary["Difficulty_Description_VeryHard"] = "Intended for veteran Commanders looking for a challenge."

	dictionary["Difficulty_Name_Impossible"] = "Imposs."
	dictionary["Difficulty_Title_Impossible"] = "Impossible Mode"
	dictionary["Difficulty_Description_Impossible"] = "A punishing difficulty allowing no mistakes."

	dictionary["TestingConsole_ToggleButton_Text"] = "TESTING CONSOLE"
	dictionary["TestingConsole_ToggleButton_Tooltip"] = "Opens a console for running mod loader integration tests."
	dictionary["TestingConsole_FrameTitle"] = "Testing Console"
	dictionary["TestingConsole_RunAll"] = "Run All"
	dictionary["TestingConsole_RunSelected"] = "Run Selected"
	dictionary["TestingConsole_RootTestsuite"] = "Root Testsuite"
	dictionary["TestingConsole_FailSummary_FrameTitle"] = "Failure Summary"
	dictionary["TestingConsole_FailSummary_Tooltip"] = "This test has failed. Click to bring up a detailed summary."

	return dictionary
end

local languageLoaders = {}
languageLoaders[languageIndices.English] = setupDictionary_English
-- Can extend with other languages in the future, if anyone ever wants to do it

function modApi:loadLocaleDictionary(localeId)
	local dictionary = nil

	if type(languageLoaders[localeId]) == "function" then
		dictionary = languageLoaders[localeId]()
	else
		-- Fall back to loading English
		dictionary = setupDictionary_English()
	end

	self.dictionary = dictionary

	self:setupVanillaTexts()
end

function modApi:setupVanillaTexts()
	local t = self.dictionary
	self.dictionary = nil

	for i, v in ipairs(self.squadKeys) do
		Global_Texts["Squad_Name_"..v] = GetText("TipTitle_"..v)
		Global_Texts["Squad_Description_"..v] = GetText("TipText_"..v)
	end

	t["Difficulty_Name_Easy"]          = GetText("Toggle_Easy")
	t["Difficulty_Title_Easy"]         = GetText("TipTitle_HangarEasy")
	t["Difficulty_Description_Easy"]   = GetText("TipText_HangarEasy")
	t["Difficulty_Name_Normal"]        = GetText("Toggle_Normal")
	t["Difficulty_Title_Normal"]       = GetText("TipTitle_HangarNormal")
	t["Difficulty_Description_Normal"] = GetText("TipText_HangarNormal")
	t["Difficulty_Name_Hard"]          = GetText("Toggle_Hard")
	t["Difficulty_Title_Hard"]         = GetText("TipTitle_HangarHard")
	t["Difficulty_Description_Hard"]   = GetText("TipText_HangarHard")

	self.dictionary = t
end
