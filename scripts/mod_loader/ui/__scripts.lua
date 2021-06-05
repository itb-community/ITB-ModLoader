local scripts = {
	"ui_anim",

	"decorations/decoration",
	"decorations/ui_deco",
	"decorations/deco_align",
	"decorations/deco_surface",
	"decorations/deco_solid",
	"decorations/deco_text",
	"decorations/deco_frame",
	"decorations/deco_button",
	"decorations/deco_checkbox",
	"decorations/deco_dropdown",
	"decorations/deco_animsheet",
	"decorations/deco_label",
	"decorations/deco_textbox",

	"widgets/base",
	"widgets/draggable",
	"widgets/dragdroplist",
	"widgets/boxlayout",
	"widgets/flowlayout",
	"widgets/weightlayout",
	"widgets/wrappedtext",
	"widgets/tooltip",
	"widgets/root",
	"widgets/scrollarea",
	"widgets/checkbox",
	"widgets/dropdown",
	"widgets/mainmenubutton",
	"widgets/textbox",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
