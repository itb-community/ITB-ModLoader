
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

		-- Create a copy of the squad table, and remove 'id'
		-- from it before returning, in order for the game
		-- not to mistake the entry for a mech.
		local squad = copy_table(modApi:getSquadForChoice(choice))
		squad.id = nil

		return squad
	else
		return oldGetStartingSquad(choice)
	end
end
