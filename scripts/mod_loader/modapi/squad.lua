
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

function modApi:addSquad(squad, name, desc, icon)
	Assert.ModInitializingOrLoading()

	Assert.Equals('table', type(squad), "Argument #1")
	Assert.Equals(4, #squad, "Argument #1 - table size")
	Assert.Equals('string', type(squad[1]), "Argument #1 - entry 1")
	Assert.Equals('string', type(name), "Argument #2")
	Assert.Equals('string', type(desc), "Argument #3")

	squad.id = squad.id or buildSquadId(squad)
	Assert.Equals(nil, modApi.mod_squads_by_id[squad.id], string.format("Squad with id %q already exists", squad.id))

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

		if i > 2 then
			local ptable_prev = _G[squad[i-1]]
			local pri = CLASS_ORDER[ptable.Class] or INT_MAX
			local pri_prev = CLASS_ORDER[ptable_prev.Class] or INT_MAX

			if pri < pri_prev then
				-- swap entries
				squad[i-1], squad[i] = squad[i], squad[i-1]
			end
		end
	end

	modApi.mod_squads_by_id[squad.id] = squad

	table.insert(self.mod_squads, squad)
	table.insert(self.squad_text, name)
	table.insert(self.squad_text, desc)
	table.insert(self.squad_icon, icon or "resources/mods/squads/unknown.png")
end
