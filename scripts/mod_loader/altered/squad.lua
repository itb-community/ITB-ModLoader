
local oldGetStartingSquad = getStartingSquad
function getStartingSquad(choice)
	if choice == 0 then
		loadPilotsOrder()
		loadSquadSelection()
	end

	-- squads 0-7 are the first 8 vanilla squads
	-- 8 and 9 are random and custom
	-- squad 10 is secret, 11-16 are Advanced
	if (choice >= 0 and choice <= 7) or (choice >= 10 and choice <= (modApi.constants.MAX_SQUADS + 2)) then
		if choice >= 10 then
			choice = choice - 2
		end
		local index = modApi.squadIndices[choice + 1]

		modApi:setText(
			"TipTitle_"..modApi.squadKeys[choice + 1],
			modApi.squad_text[2 * (index - 1) + 1]
		)
		modApi:setText(
			"TipText_"..modApi.squadKeys[choice + 1],
			modApi.squad_text[2 * (index - 1) + 2]
		)

		-- Create a copy of the squad table, and remove 'id'
		-- from it before returning, in order for the game
		-- not to mistake the entry for a mech.
		local squad = copy_table(modApi.mod_squads[index])
		squad.id = nil

		return squad
	else
		return oldGetStartingSquad(choice)
	end
end
