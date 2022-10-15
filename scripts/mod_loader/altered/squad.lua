
local oldGetStartingSquad = getStartingSquad
function getStartingSquad(choice)
	if choice == modApi.constants.SQUAD_CHOICE_START then
		loadPilotsOrder()
		loadSquadSelection()
	end

	if true
		and choice ~= modApi.constants.SQUAD_CHOICE_RANDOM
		and choice ~= modApi.constants.SQUAD_CHOICE_CUSTOM
		and choice >= modApi.constants.SQUAD_CHOICE_START
		and choice <= modApi.constants.SQUAD_CHOICE_END
	then
		local index = modApi:squadChoice2Index(choice)
		local redirectedIndex = modApi.squadIndices[index]

		modApi:setText(
			"TipTitle_"..modApi.squadKeys[index],
			modApi.squad_text[2 * (redirectedIndex - 1) + 1]
		)
		modApi:setText(
			"TipText_"..modApi.squadKeys[index],
			modApi.squad_text[2 * (redirectedIndex - 1) + 2]
		)

		local squad = modApi:getSquadForChoice(choice)

		-- Return the squad in a flat list as the game expects
		return { squad.name, squad.mechs[1], squad.mechs[2], squad.mechs[3] }
	else
		return oldGetStartingSquad(choice)
	end
end
