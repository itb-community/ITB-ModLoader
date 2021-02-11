local scripts = {
	"sdlext",
	"modApi",
	"event",
	"asserts"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
