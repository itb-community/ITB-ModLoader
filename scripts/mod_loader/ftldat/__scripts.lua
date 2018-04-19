local scripts = {
	"scripts/mod_loader/ftldat/lua-struct",
	"scripts/mod_loader/ftldat/kaitai_struct_lua_runtime/kaitaistruct",
	"scripts/mod_loader/ftldat/ftldat"
}

for i, filepath in ipairs(scripts) do
	require(filepath)
end
