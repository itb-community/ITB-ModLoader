
-- Generate id for squad, based on mod id followed by
-- squad name, with spaces replaced by underscores.
local function buildSquadId(squad)
	return string.format("%s_%s", modApi.currentMod, squad[1]:gsub("%s","_"))
end

function modApi:addSquadTrue(squad, name, desc, icon)
	return self:addSquad(squad, name, desc, icon)
end

function modApi:addSquad(squad, name, desc, icon)
	Assert.ModInitializingOrLoading()

	Assert.Equals('table', type(squad), "Argument #1")
	Assert.Equals(4, #squad, "Argument #1 - table size")
	Assert.Equals('string', type(squad[1]), "Argument #1 - entry 1")
	Assert.Equals('string', type(name), "Argument #2")
	Assert.Equals('string', type(desc), "Argument #3")

	squad.id = squad.id or buildSquadId(squad)
	Assert.Equals(nil, modApi.mod_squads_by_id[squad.id], string.format("Squad with id %q already exists", squad.id))
	modApi.mod_squads_by_id[squad.id] = squad

	table.insert(self.mod_squads, squad)
	table.insert(self.squad_text, name)
	table.insert(self.squad_text, desc)
	table.insert(self.squad_icon, icon or "resources/mods/squads/unknown.png")
end
