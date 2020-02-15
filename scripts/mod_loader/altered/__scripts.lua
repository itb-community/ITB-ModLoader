local scripts = {
	"difficulty",
	"misc",
	"missions",
	"missions_additional",
	"skills",
	"spawn_point",
	"squad",
	"text",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
