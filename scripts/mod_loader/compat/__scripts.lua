local scripts = {
	"sdlext",
	"modApi",
	"event",
	"asserts",
	"achievement",
	"dialog_helper",
	"difficulty",
	"furl"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
