local utf8=require"utf8"

function love.errorhandler(msg)
	msg = tostring(msg)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
    love.graphics.setDefaultFilter("nearest")
    love.graphics.setNewFont("font.ttf",16)

	love.graphics.setColor(1, 1, 1)

	love.graphics.origin()

    -- if it doesn't already contain a traceback, traceback it
    --[[if not msg:find("\nstack traceback:\n") then
        msg=debug.traceback(msg,4)
    end]]

    local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, "*** SOFTWARE FAILURE ***")
    table.insert(err,"GURU MEDITATION:")
    table.insert(err,"")
	table.insert(err, sanitizedmsg)
	if #sanitizedmsg ~= #msg then
		table.insert(err, "* Invalid UTF-8 string in error message. *")
	end

	local p = table.concat(err, "\n")

    p = p:gsub("\t", (" "):rep(8)) -- tabs 8 spaces, fight me
    p = p:gsub("%[string \"(.-)\"%]", "%1")
    p = p:gsub("stack traceback:","\n\nTraceback:")

    love.graphics.scale(3,3)
	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 0
		love.graphics.clear(1, 0, 0)
		love.graphics.printf(p, pos+2, pos, (love.graphics.getWidth()/3) - pos)
		love.graphics.present()
	end

	local fullErrorText = p
    print(fullErrorText)
    print("---\nerror with full traceback:")
    print(debug.traceback(msg,4))
    print("If the error isn't in your code, send this to minerobber and he'll try to fix it!")
    p = p.."\n"
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\nPress Ctrl+C to copy this error or Ctrl+R to restart NeXUS"
	else
		p = p .. "\nPress Ctrl+R to restart NeXUS"
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
            elseif e == "keypressed" and a == "r" and love.keyboard.isDown("lctrl", "rctrl") then
				return "restart"
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end

end
