deco = {}

deco.colors = {}
deco.colors.white =                         sdl.rgb(255, 255, 255)
deco.colors.black =                         sdl.rgb(0, 0, 0)
deco.colors.halfblack =                     sdl.rgba(0, 0, 0, 128)
deco.colors.framebg =                       sdl.rgb(13, 15, 23)
deco.colors.framebglight =                  sdl.rgb(30, 36, 50)
deco.colors.buttoncolor =                   sdl.rgb(24, 28, 41)
deco.colors.buttonhlcolor =                 sdl.rgb(35, 42, 59)
deco.colors.buttonbordercolor =             sdl.rgb(73, 92, 121)
deco.colors.buttonborderhlcolor =           sdl.rgb(217, 235, 200)
deco.colors.buttondisabledcolor =           deco.colors.framebg
deco.colors.buttonborderdisabledcolor =     sdl.rgb(43, 53, 72)
deco.colors.mainMenuButtonColor =           sdl.rgba(7 , 10, 18, 187)
deco.colors.mainMenuButtonColorDisabled =   sdl.rgba(7 , 10, 18, 84 )
deco.colors.mainMenuButtonColorHighlight =  sdl.rgba(24, 26, 34, 255)

deco.textset = function(color, outlineColor, outlineWidth, antialias)
	local res = sdl.textsettings()
	
	res.antialias = antialias or false
	res.color = color
	res.outlineColor = outlineColor or deco.colors.white
	res.outlineWidth = outlineWidth or 0

	return res
end

deco.fonts = {}
deco.fonts.justin12 = sdlext.font("fonts/JustinFont12Bold.ttf", 12)
deco.fonts.menufont = sdlext.font("fonts/JustinFont11Bold.ttf", 24)
deco.fonts.tooltipTitle = sdlext.font("fonts/NunitoSans_Bold.ttf", 14)
deco.fonts.tooltipText = sdlext.font("fonts/NunitoSans_Regular.ttf", 12)

deco.uifont = {
	default = {
		font = deco.fonts.justin12,
		set = deco.textset(deco.colors.white),
	},
	title = {
		font = deco.fonts.menufont,
		set = deco.textset(deco.colors.white, deco.colors.buttonhlcolor, 2),
	},
	tooltipTitle = {
		font = deco.fonts.tooltipTitle,
		set = deco.textset(deco.colors.white, nil, nil, true)
	},
	tooltipText = {
		font = deco.fonts.tooltipText,
		set = deco.textset(deco.colors.white, nil, nil, true)
	}
}

deco.surfaces = {}
