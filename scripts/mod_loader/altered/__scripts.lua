local scripts = {
	"text",
	"difficulty",
	"misc",
	"missions",
	"skills",
	"spawn_point",
	"squad"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
