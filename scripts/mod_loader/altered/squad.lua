
local function findVanillaSquads()
	modApi.vanillaSquadsByIndex = {}

	for i = modApi.constants.SQUAD_INDEX_START, modApi.constants.SQUAD_INDEX_END do
		if true
			and i ~= modApi.constants.SQUAD_INDEX_RANDOM
			and i ~= modApi.constants.SQUAD_INDEX_CUSTOM
		then
			local vanillaSquad = getStartingSquad(i)

			-- For some reason the vanilla getStartingSquad returns a list:
			-- { [1] = "name", [3] = "pawn1", [6] = "pawn2", [9] = "pawn3" }

			-- The mod loader's getStartingSquad override returns a list:
			-- { [1] = "name", [2] = "pawn1", [3] = "pawn2", [4] = "pawn3" }

			-- If the game at some point changes its returned indices, the
			-- following code will have to be updated.
			modApi.vanillaSquadsByIndex[i] = {
				id = vanillaSquad[1],
				mechs = {
					vanillaSquad[3],
					vanillaSquad[6],
					vanillaSquad[9]
				}
			}
		end
	end
end

findVanillaSquads()

local oldGetStartingSquad = getStartingSquad
function getStartingSquad(choice)
	if choice == 0 then
		loadPilotsOrder()
		loadSquadSelection()
	end

	if true
		and choice ~= modApi.constants.SQUAD_INDEX_RANDOM
		and choice ~= modApi.constants.SQUAD_INDEX_CUSTOM
		and choice >= modApi.constants.SQUAD_INDEX_START
		and choice <= modApi.constants.SQUAD_INDEX_END
	then
		-- If choice is above the custom squad index,
		-- reduce the index by 2 to account for random
		-- and custom squad.
		if choice > modApi.constants.SQUAD_INDEX_CUSTOM then
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
