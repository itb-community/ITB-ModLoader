
function modApi:addSquadTrue(squad, name, desc, icon)
	return self:addSquad(squad, name, desc, icon)
end

function modApi:addSquad(squad, name, desc, icon)
	assert(type(squad) == "table")
	assert(#squad == 4)
	assert(type(name) == "string")
	assert(type(desc) == "string")

	table.insert(self.mod_squads, squad)
	table.insert(self.squad_text, name)
	table.insert(self.squad_text, desc)
	table.insert(self.squad_icon, icon or "resources/mods/squads/unknown.png")
end
