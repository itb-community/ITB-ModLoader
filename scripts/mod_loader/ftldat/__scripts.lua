local scripts = {
	"lua-struct",
	"kaitai_struct_lua_runtime/kaitaistruct",
	"ftldat"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
