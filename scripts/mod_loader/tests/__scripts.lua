local scripts = {
	"base",
	
	"sandbox",
	"pawn"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
