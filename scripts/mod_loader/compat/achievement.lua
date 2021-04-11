
-- compatibility code for legacy achievement library
lmn_achievements = {
	version = "0", -- this allows us detect when a mod attempts to initialize their library
	chievos = {},
	toasts = modApi.toasts,
	modApiFinalize = true, -- this ensures no mods will initialize their library
}
