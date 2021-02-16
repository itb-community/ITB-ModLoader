local scripts = {
	"sdlext",
	"modApi",
	"event",
	"asserts",
	"achievement"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
