return {
	["Button_Ok"] = "OK",
	["Button_Yes"] = "YES",
	["Button_No"] = "NO",
	["Button_DisablePopup"] = "GOT IT, DON'T TELL ME AGAIN",
	["ButtonTooltip_DisablePopup"] = "This dialog will not be shown anymore. You can re-enable it in Mod Content > Configure Mod Loader.",

	["MainMenu_Button_ModContent"] = "Mod Content",
	["ModContent_FrameTitle"] = "Mod Content",

	["ModContent_Button_ModConfig"] = "Configure Mods",
	["ModContent_ButtonTooltip_ModConfig"] = "Turn on and off individual mods, and configure any settings they might have.",
	["ModConfig_FrameTitle"] = "Mod Configuration",

	["ModContent_Button_SquadSelect"] = "Edit Squads",
	["ModContent_ButtonTooltip_SquadSelect"] = "Select which squads will be available to pick.",
	["SquadSelect_FrameTitle"] = "Squad Selection",
	["SquadSelect_Total"] = "Total selected",
	["SquadSelect_Default_Text"] = "Default",
	["SquadSelect_Default_Tooltip"] = "Select only vanilla squads.",
	["SquadSelect_Random_Text"] = "Random",
	["SquadSelect_Random_Tooltip"] = "Select random squads.",

	["ModContent_Button_PilotArrange"] = "Arrange Pilots",
	["ModContent_ButtonTooltip_PilotArrange"] = "Select which pilots will be available to pick.",
	["PilotArrange_ButtonTooltip_Off"] = "Pilots can only be arranged before the New Game button is pressed.\n\nRestart the game to be able to arrange pilots.",
	["PilotArrange_FrameTitle"] = "Arrange Pilots",

	["ModContent_Button_ModLoaderConfig"] = "Configure Mod Loader",
	["ModContent_ButtonTooltip_ModLoaderConfig"] = "Configure some features of the mod loader.",
	["ModLoaderConfig_FrameTitle"] = "Mod Loader Configuration",

	["ModLoaderConfig_Text_LogLevel"] = "Logging level",
	["ModLoaderConfig_Tooltip_LogLevel"] = "Controls where the game's logging messages are printed.",
	["ModLoaderConfig_DD_LogLevel_0"] = "None",
	["ModLoaderConfig_DD_LogLevel_1"] = "Only console",
	["ModLoaderConfig_DD_LogLevel_2"] = "File and console",

	["ModLoaderConfig_Text_Caller"] = "Print Caller Information",
	["ModLoaderConfig_Tooltip_Caller"] = "Include timestamp and stacktrace in LOG messages.",

	["ModLoaderConfig_Text_DevMode"] = "Development Mode",
	["ModLoaderConfig_Tooltip_DevMode"] = "Enable debug mod loader features. May disrupt normal gameplay.\n\n"..
	                                      "You shouldn't enable this, unless you're a mod creator or mod loader maintainer.",

	["ModLoaderConfig_Text_FloatyTooltips"] = "Attach Tooltips To Mouse Cursor",
	["ModLoaderConfig_Tooltip_FloatyTooltips_On"] = "Tooltips follow the mouse cursor around.",
	["ModLoaderConfig_Tooltip_FloatyTooltips_Off"] = "Tooltips show to the side of the UI element that spawned them, similar to the game's own tooltips.",

	["ModLoaderConfig_Text_ProfileConfig"] = "Profile-Specific Configuration",
	["ModLoaderConfig_Tooltip_ProfileConfig"] = "Configuration for the mod loader and individual mods will be remembered per profile, instead of globally.\n\n"..
	                                            "Note: with this option enabled, switching profiles will require you to restart the game to apply the different mod configurations.",

	["ModLoaderConfig_Text_ScriptError"] = "Show Script Error Popup",
	["ModLoaderConfig_Tooltip_ScriptError"] = "Show an error popup at startup if a mod fails to mount, init, or load.",

	["ModLoaderConfig_Text_OldVersion"] = "Show Mod Loader Outdated Popup",
	["ModLoaderConfig_Tooltip_OldVersion"] = "Show a popup if the mod loader is out-of-date for installed mods.",

	["ModLoaderConfig_Text_ResourceError"] = "Show Resource Error Popup",
	["ModLoaderConfig_Tooltip_ResourceError"] = "Show an error popup at startup if the mod loader fails to load the game's resources.",

	["ModLoaderConfig_Text_GamepadWarning"] = "Show Gamepad Warning Popup",
	["ModLoaderConfig_Tooltip_GamepadWarning"] = "Show a warning popup when Gamepad Mode is enabled.",

	["ModLoaderConfig_Text_RestartReminder"] = "Show Restart Reminder Popup",
	["ModLoaderConfig_Tooltip_RestartReminder"] = "Show a popup reminding to restart the game when enabling mods.",

	["ModLoaderConfig_Text_ProfileFrame"] = "Show Profile Settings Change Popup",
	["ModLoaderConfig_Tooltip_ProfileFrame"] = "Show a popup reminding to restart the game when switching profiles with Profile-Specific Configuration enabled.",

	["ScriptError_FrameTitle"] = "Script Error",
	["ScriptError_FrameText_Mount"] = "Unable to mount mod at [%s]:\n%s",

	["RestartRequired_FrameTitle"] = "Restart Required",
	["RestartRequired_FrameText"] = "You have enabled one or more mods. In order to apply them, game restart is required.",

	["OldVersion_FrameTitle"] = "Mod Loader Outdated",
	["OldVersion_FrameText"] = "The following mods could not be loaded, because they require a newer version of the mod loader:\n\n%s\nYour installed version: %s",
	["OldVersion_ListEntry"] = "- [%s] requires at least version %s.",

	["ResourceError_FrameTitle"] = "Resource Error",
	["ResourceError_FrameText"] = "The mod loader failed to load game resources. "..
	                              "This will cause some elements of modded UI to be invisible or incorrectly positioned. "..
	                              "This happens sometimes, but so far the cause is not known.\n\n"..
	                              "Restarting the game should fix this.",

	["GamepadWarning_FrameTitle"] = "Gamepad Warning",
	["GamepadWarning_FrameText"] = "Gamepad Mode has been enabled.\n\n" ..
	                               "The mod loader does not support input via a gamepad. Since many of the mod loader's features rely on detecting " ..
	                               "mouse and keyboard inputs, it is recommended to uninstall the mod loader if you plan to play with a gamepad.",

	["OpenGL_FrameTitle"] = "Restart Required",
	["OpenGL_FrameText"] = "Mod loader has updated game settings, please restart the game for the changes to take effect.\n\n" ..
	                       "Most mods are likely be broken until then.\n\n" ..
	                       "These changes are likely to be overwritten by the game unless you restart immediately.",
	["OpenGL_Button_Quit"] = "OK, QUIT",
	["OpenGL_Button_Stay"] = "GOT IT, I'LL RESTART LATER",

	["ProfileSettings_FrameTitle"] = "Profile Settings Changed",
	["ProfileSettings_FrameText"] = "Active profile has been changed, and profile-specific configuration is enabled.\n\n"..
	                                "You need to restart the game in order to apply the changes made by the profile's configuration.",

	["VersionString"] = "Mod loader version: ",

	["Difficulty_Custom_Note"] = "Note: this is a modded difficulty level. It won't change anything without mods providing content for this difficulty.",

	["Difficulty_Name_VeryHard"] = "V. Hard",
	["Difficulty_Title_VeryHard"] = "Very Hard Mode",
	["Difficulty_Description_VeryHard"] = "Intended for veteran Commanders looking for a challenge.",

	["Difficulty_Name_Impossible"] = "Imposs.",
	["Difficulty_Title_Impossible"] = "Impossible Mode",
	["Difficulty_Description_Impossible"] = "A punishing difficulty allowing no mistakes.",

	["TestingConsole_ToggleButton_Text"] = "TESTING CONSOLE",
	["TestingConsole_ToggleButton_Tooltip"] = "Opens a console for running mod loader integration tests.",
	["TestingConsole_FrameTitle"] = "Testing Console",
	["TestingConsole_RunAll"] = "Run All",
	["TestingConsole_RunSelected"] = "Run Selected",
	["TestingConsole_RootTestsuite"] = "Root Testsuite",
	["TestingConsole_FailSummary_FrameTitle"] = "Failure Summary",
	["TestingConsole_FailSummary_Tooltip"] = "This test has failed. Click to bring up a detailed summary.",
}
