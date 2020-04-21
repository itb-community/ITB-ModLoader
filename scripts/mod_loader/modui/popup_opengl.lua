--[[
	Updates game settings for post-1.2.20 version of the game, and adds
	a popup telling the player to restart the game.
--]]

local function responseFn(btnIndex)
	if btnIndex == 1 then
		os.exit()
	end
end

local function showOpenGLWarning()
	sdlext.showButtonDialog(
			GetText("OpenGL_FrameTitle"),
			GetText("OpenGL_FrameText"),
			responseFn, nil, nil,
			{ GetText("OpenGL_Button_Quit"), GetText("OpenGL_Button_Stay") },
			nil
	)
end

-- Hook into GetText to detect when we enter the main menu, since when OpenGL 1.0 is disabled,
-- the regular way of detecting main menu doesn't work (is the big robot visible?)
local mainMenuReady = false
local oldGetText = GetText
function GetText(id, ...)
	if id == "Button_MainContinue" then
		mainMenuReady = true
	end

	return oldGetText(id, ...)
end

local replaceFileContent = ReplaceFileContent
ReplaceFileContent = nil
local function updateGameSettings()
	local settingsPath = GetSavedataLocation() .. "settings.lua"
	replaceFileContent(settingsPath, "force_opengl_1\"\] = 0", "force_opengl_1\"\] = 1")
	replaceFileContent(settingsPath, "language\"\] = 0", "language\"\] = 1")
end

modApi:conditionalHook(
	function()
		return mainMenuReady
	end,
	function()
		GetText = oldGetText

		if Settings.force_opengl_1 == nil or Settings.force_opengl_1 == 0 then
			updateGameSettings()

			showOpenGLWarning()
		end
	end
)
