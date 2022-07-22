local scripts = {
	"misc",
	"drops",
	"missions",
	"globalize_enemy_tables",
	"skills",
	"spawn_point",
	"squad",
	"text",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
