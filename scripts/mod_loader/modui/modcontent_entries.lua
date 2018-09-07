function sdlext.executeAddModContent()
	sdlext.addModContent(
		modApi:getText("Button_ModConfig"),
		ConfigureMods,
		modApi:getText("ButtonTooltip_ModConfig")
	)

	sdlext.addModContent(
		modApi:getText("Button_SquadSelect"),
		SelectSquads,
		modApi:getText("ButtonTooltip_SquadSelect")
	)

	arrangePilotsButton = sdlext.addModContent(
		modApi:getText("Button_PilotArrange"),
		ArrangePilots,
		modApi:getText("ButtonTooltip_PilotArrange")
	)

	sdlext.addModContent(
		modApi:getText("Button_ModLoaderConfig"),
		ConfigureModLoader,
		modApi:getText("ButtonTooltip_ModLoaderConfig")
	)
end
