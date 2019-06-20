local scripts = {
	"base",
	
	"sandbox"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
