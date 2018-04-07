deco = {}

deco.colors = {}
deco.colors.white = sdl.rgb(255, 255, 255)
deco.colors.black = sdl.rgb(0, 0, 0)
deco.colors.buttoncolor = sdl.rgb(24, 28, 40)
deco.colors.buttonbordercolor = sdl.rgb(73, 92, 121)
deco.colors.buttonhlcolor = sdl.rgb(217, 235, 200)
deco.colors.buttondisabledcolor = sdl.rgb(80, 80, 80)

deco.textset = function(color, outlineColor, outlineWidth)
	local res = sdl.textsettings()
	
	res.antialias = false
	res.color = color
	res.outlineColor = outlineColor or deco.colors.white
	res.outlineWidth = outlineWidth or 0

	return res
end

deco.fonts = {}
deco.fonts.justin12 = sdlext.font("fonts/JustinFont12Bold.ttf", 12)
deco.fonts.menufont = sdlext.font("fonts/JustinFont11Bold.ttf", 24)

deco.uifont = {
	default = {
		font = deco.fonts.justin12,
		set = deco.textset(deco.colors.white),
	},
	title = {
		font = deco.fonts.menufont,
		set = deco.textset(deco.colors.white, sdl.rgb(35, 42, 59), 2),
	},
}

deco.surfaces = {}
