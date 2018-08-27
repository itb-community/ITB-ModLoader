local scripts = {
	"difficulty",
	"misc",
	"missions",
	"skills",
	"spawn_point",
	"squad",
	"text"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
