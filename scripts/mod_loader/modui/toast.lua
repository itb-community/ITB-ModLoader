
local FONT = sdlext.font("fonts/NunitoSans_Bold.ttf", 19)
local TEXT_SET = deco.textset(deco.colors.white, nil, 0, true)
local SHADOW_LEFT = "resources/mods/ui/toast_shadow_left.png"
local SHADOW_CENTER = "resources/mods/ui/toast_shadow_center.png"
local SHADOW_RIGHT = "resources/mods/ui/toast_shadow_right.png"
local NO_ICON = "img/achievements/No_Icon.png"

local function updateToasts(self)
	-- if there is a toast playing, return.
	if self.current and not self.current:isStopped() then
		return
	end

	self.current = nil

	-- start the first pending toast.
	if #self.pending > 0 then
		self:play()
	end
end

local function addToast(self, toast)
	table.insert(self.pending, toast or {})
end

local function playToast(self)
	if self.current ~= nil then return end

	local toast = self.pending[1]
	if toast == nil then return end
	table.remove(self.pending, 1)

	if Game then
		Game:TriggerSound("ui/general/achievement")
	end
	
	local root = sdlext.getUiRoot()
	local title = toast.title or "Achievement!"
	local name = toast.name or "Unnamed Toast"
	local tooltip = toast.tooltip or ""
	local surface = sdlext.getSurface({ path = toast.image or NO_ICON })

	local icon = {
		width = surface:w(),
		height = surface:h(),
		gapr = 13
	}

	local deco_text = DecoText(name, FONT, TEXT_SET)
	local Text = Ui()
		:width(1):height(1)
		:decorate({ deco_text })

	local iconholderWidth = deco_text.surface:w() + icon.width + icon.gapr

	local main = {
		gapt = 12,
		gapr = 15,
		width =  math.max(310, iconholderWidth + 23 * 2),
		height = 143,
		border = 2,
	}

	main.posx = root.w - main.width - main.gapr
	main.posy = main.gapt

	local shadow = {
		posx = 0,
		posy = 48,
		offx = 4,
		offy = -7,
	}

	local Main = Ui()
		:widthpx(main.width):heightpx(main.height)
		:pospx(main.posx, main.posy)

	-- construct shadow.
	local surface_shadow_left = sdlext.getSurface({ path = SHADOW_LEFT })
	local surface_shadow_center = sdlext.getSurface({ path = SHADOW_CENTER })
	local surface_shadow_right = sdlext.getSurface({ path = SHADOW_RIGHT })
	local d = {}
	d[#d+1] = DecoSurface(surface_shadow_left)
	for i = 1, main.width - 8 * 2 do
		d[#d+1] = DecoSurface(surface_shadow_center)
	end
	d[#d+1] = DecoSurface(surface_shadow_right)

	local Shadow = Ui()
		:width(1):height(1)
		:pospx(shadow.posx + shadow.offx, shadow.posy + shadow.offy)
		:decorate(d)

	local Frame = Ui()
		:width(1):height(1)
		:caption(title)
		:settooltip(tooltip)
		:decorate({ DecoFrameHeader(), DecoFrame() })

	local Icon = Ui()
		:widthpx(icon.width):heightpx(icon.height)
		:decorate({
			DecoSurfaceAligned(surface, "center", "center"),
			DecoBorder(deco.colors.buttonborderhl, 1, deco.colors.buttonborderhl, 1),
		})
	icon.posX = (main.width - iconholderWidth) / 2
	icon.posY = (main.height - 48 - icon.height) / 2

	Text:pospx(icon.width + icon.gapr, 0)

	local IconHolder = Ui()
		:widthpx(iconholderWidth):heightpx(icon.height)
		:pospx(icon.posX, icon.posY)

	Shadow.translucent = true
	IconHolder.translucent = true
	Icon.translucent = true
	Text.translucent = true

	IconHolder:add(Icon)
	IconHolder:add(Text)
	Frame:add(IconHolder)
	Main:add(Frame)
	Main:add(Shadow)

	Main.animations.fadeOut = UiAnim(Main, 4000, function() end)
	Main.animations.fadeOut.onFinished = function(self) self.widget:detach() end
	Main.animations.fadeOut:start()
	Main:addTo(root):bringToTop()

	self.current = Main.animations.fadeOut
end

modApi.toasts = {
	pending = {},
	add = addToast,
	play = playToast,
	update = updateToasts
}

local function addToastLoop()
	sdlext.addFrameDrawnHook(function()
		modApi.toasts:update()
	end)
end

modApi.events.onModsInitialized:subscribe(addToastLoop)
