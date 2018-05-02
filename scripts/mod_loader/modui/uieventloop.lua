function sdlext.uiEventLoop(init)
	local screen = sdl.screen()
	local eventloop = sdl.eventloop()
	local w = screen:w()
	local h = screen:h()
	local quit = 0
	local screenshot = sdl.screenshot()
	local bg = sdl.rgba(0,0,0,128)
	local ui = UiRoot():widthpx(w):heightpx(h)

	init(ui,function()
		quit = 1
	end)
	
	while quit == 0 do
		while eventloop:next() do
			local type = eventloop:type();
			
			ui:event(eventloop)
			
			if type == sdl.events.quit then
				quit = 1
			elseif type == sdl.events.keydown and eventloop:keycode() == 27 then
				quit = 1
			end
		end
		
		screen:begin()
		screen:blit(screenshot, nil, 0, 0)
		screen:drawrect(bg, nil)
		ui:draw(screen)
		screen:finish()
	end
end
