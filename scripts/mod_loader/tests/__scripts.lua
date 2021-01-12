local scripts = {
	"base",
	"test_runner",
	"main"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
