function sdlext.executeAddModContent()
	sdlext.addModContent(
		GetText("ModContent_Button_ModConfig"),
		ConfigureMods,
		GetText("ModContent_ButtonTooltip_ModConfig")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_SquadSelect"),
		SelectSquads,
		GetText("ModContent_ButtonTooltip_SquadSelect")
	)

	arrangePilotsButton = sdlext.addModContent(
		GetText("ModContent_Button_PilotArrange"),
		ArrangePilots,
		GetText("ModContent_ButtonTooltip_PilotArrange")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_PaletteArrange"),
		ArrangePalettes,
		GetText("ModContent_ButtonTooltip_PaletteArrange")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_ConfigureWeaponDeck"),
		ConfigureWeaponDeck,
		GetText("ModContent_ButtonTooltip_ConfigureWeaponDeck")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_Achievements"),
		DisplayAchievements,
		GetText("ModContent_ButtonTooltip_Achievements")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_ModLoaderConfig"),
		ConfigureModLoader,
		GetText("ModContent_ButtonTooltip_ModLoaderConfig")
	)
end
