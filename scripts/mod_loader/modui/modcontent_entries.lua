function sdlext.executeAddModContent()
	sdlext.addModContent(
		modApi:getText("ModContent_Button_ModConfig"),
		ConfigureMods,
		modApi:getText("ModContent_ButtonTooltip_ModConfig")
	)

	sdlext.addModContent(
		modApi:getText("ModContent_Button_SquadSelect"),
		SelectSquads,
		modApi:getText("ModContent_ButtonTooltip_SquadSelect")
	)

	arrangePilotsButton = sdlext.addModContent(
		modApi:getText("ModContent_Button_PilotArrange"),
		ArrangePilots,
		modApi:getText("ModContent_ButtonTooltip_PilotArrange")
	)

	sdlext.addModContent(
		modApi:getText("ModContent_Button_ModLoaderConfig"),
		ConfigureModLoader,
		modApi:getText("ModContent_ButtonTooltip_ModLoaderConfig")
	)
end
