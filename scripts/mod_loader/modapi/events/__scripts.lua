local scripts = {
	"events",
	"global",
	"missions",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
