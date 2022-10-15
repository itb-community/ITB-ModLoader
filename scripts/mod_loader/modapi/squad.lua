
-- Generate id for squad, based on mod id followed by
-- squad name, with spaces replaced by underscores.
local function buildSquadId(squad)
	return string.format("%s_%s", modApi.currentMod, squad[1]:gsub("%s","_"))
end

function modApi:addSquadTrue(squad, name, desc, icon)
	return self:addSquad(squad, name, desc, icon)
end

local validMechClasses = {
	"Prime",
	"Brute",
	"Ranged",
	"Science",
	"TechnoVek",
}

local CLASS_ORDER = {
	Prime = 0,
	Brute = 1,
	Ranged = 2,
	Science = 3,
	TechnoVek = 4,
}

local INVALID_SQUAD_ID = {
	"Custom",
	"Random",
}

function modApi:addSquad(squad, name, desc, icon)
	Assert.ModInitializingOrLoading()

	Assert.Equals('table', type(squad), "Argument #1")
	Assert.Equals(4, #squad, "Argument #1 - table size")
	Assert.Equals('string', type(squad[1]), "Argument #1 - entry 1")
	Assert.Equals('string', type(name), "Argument #2")
	Assert.Equals('string', type(desc), "Argument #3")

	squad.id = squad.id or buildSquadId(squad)
	Assert.Equals(nil, modApi.mod_squads_by_id[squad.id], string.format("Squad with id %q already exists", squad.id))
	Assert.NotEquals(INVALID_SQUAD_ID, squad.id, string.format("Squad id %s is invalid", squad.id))

	-- sort the squad name first
	local mechOrder = {[squad[1]] = -1}

	-- Validate the squad
	for i = 2, 4 do
		local mechType = squad[i]
		local ptable = _G[mechType]

		Assert.Equals(
				"table", type(ptable),
				string.format("Squad %q - contains pawn with id %q, but no global pawn table with such identifier exists", squad.id, mechType)
		)
		Assert.Equals(
				validMechClasses,
				ptable.Class,
				string.format("Squad %q - pawn with id %q has an invalid Class", squad.id, mechType)
		)

		mechOrder[mechType] = CLASS_ORDER[ptable.Class] or INT_MAX
	end

	-- sort mechs in squad by class
	table.sort(squad, function(a, b) return mechOrder[a] < mechOrder[b] end)

	modApi.mod_squads_by_id[squad.id] = squad

	table.insert(self.mod_squads, squad)
	table.insert(self.squad_text, name)
	table.insert(self.squad_text, desc)
	table.insert(self.squad_icon, icon or "resources/mods/squads/unknown.png")
end

-- Convert from how the mod loader indexes squads to how the game indexes squads
function modApi:squadIndex2Choice(index)
	Assert.Equals("table", type(self), "Check for . vs :")

	if false
		or index < self.constants.SQUAD_INDEX_START
		or index > self.constants.SQUAD_INDEX_END
	then
		LOG("WARNING: Invalid squad index -> choice conversion")
		return -1
	end

	if index >= self.constants.SQUAD_INDEX_SECRET then
		return index + 1
	else
		return index - 1
	end
end

-- Convert from how the game indexes squads to how the mod loader indexes squads
function modApi:squadChoice2Index(choice)
	Assert.Equals("table", type(self), "Check for . vs :")

	if false
		or choice == self.constants.SQUAD_CHOICE_RANDOM
		or choice == self.constants.SQUAD_CHOICE_CUSTOM
		or choice < self.constants.SQUAD_CHOICE_START
		or choice > self.constants.SQUAD_CHOICE_END
	then
		LOG("WARNING: Invalid squad choice -> index conversion")
		return -1
	end

	if choice >= self.constants.SQUAD_CHOICE_SECRET then
		return choice - 1
	else
		return choice + 1
	end
end

function modApi:getSquadForChoice(choice)
	Assert.Equals("table", type(self), "Check for . vs :")

	if false
		or choice == self.constants.SQUAD_CHOICE_RANDOM
		or choice == self.constants.SQUAD_CHOICE_CUSTOM
		or choice < self.constants.SQUAD_CHOICE_START
		or choice > self.constants.SQUAD_CHOICE_END
	then
		Assert.Error("Invalid squad choice")
	end

	if self.squadIndices == nil then
		loadSquadSelection()
	end

	local index = self:squadChoice2Index(choice)
	local squad_flat = self.mod_squads[self.squadIndices[index]]

	return {
		name = squad_flat[1],
		id = squad_flat.id,
		mechs = {
			squad_flat[2],
			squad_flat[3],
			squad_flat[4],
		}
	}
end

local function onGameEntered()
	local squadData = GAME.additionalSquadData
	local squadId = squadData.squad

	if squadId ~= nil then
		modApi.events.onSquadEnteredGame:dispatch(squadId)
	end
end

local function onGameExited()
	local squadData = GAME.additionalSquadData
	local squadId = squadData.squad

	if squadId ~= nil then
		modApi.events.onSquadExitedGame:dispatch(squadId)
	end
end

modApi.events.onGameEntered:subscribe(onGameEntered)
modApi.events.onGameExited:subscribe(onGameExited)
