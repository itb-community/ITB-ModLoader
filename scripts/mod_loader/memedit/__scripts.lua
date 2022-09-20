local scripts = {
	"dummy",
	"memedit",
	"tests",
	"ui_meminspect",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end

return modApi.memedit
