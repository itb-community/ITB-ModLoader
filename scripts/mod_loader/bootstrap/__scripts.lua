local scripts = {
	"security",
	"assert",
	"classes",
	"try_catch",
	"itb_io",
	"io",
	"utils",
	"event",
	"modApi",
	"constants",
	"binarySearch",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
