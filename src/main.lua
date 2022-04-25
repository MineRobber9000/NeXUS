require"errorhandler"
local VM = require"api"
local Cart = require"cart"

vm = VM.new(true)

-- Calls a function represented by a global variable
-- Returns true if function successfully executed
-- Returns false if the global doesn't exist/isn't a function
-- Errors if an error occurs in the VM
function callglobal(global)
    if vm:getglobal(global)==vm.LUA_TFUNCTION then
        if vm:docall(0,0)>0 then error(vm:checkstring(-1),0) end
        return true
    else
        vm:pop(1)
        return false
    end
end

function love.run()
    love.graphics.setLineStyle("rough")
    love.graphics.setDefaultFilter("nearest")
    cart = Cart.new("nogameloaded.rom")
    vm.font = love.graphics.newFont("font.ttf",16)
    vm.canvas = love.graphics.newCanvas(320,240)
    vm:init()
    vm:loadstring(cart.code)
    if vm:docall(0,0)>0 then
        error(vm:checkstring(-1))
    end
    -- for some reason this line breaks font rendering, so for now we're just gonna leave it
    -- love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.origin()
    love.graphics.push()
    local sx, sy, sw, sh = nil, nil, nil, nil
    local first = true
    love.timer.step()
	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
                elseif name == "keypressed" and a == "escape" then
    				return 0
                elseif e == "keypressed" and a == "r" and love.keyboard.isDown("lctrl", "rctrl") then
    				return "restart"
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

        love.graphics.clear()
        love.graphics.setCanvas(vm.canvas)
        love.graphics.setFont(vm.font)
        love.graphics.pop()
        love.graphics.setScissor(sx,sy,sw,sh)
        if not callglobal("doframe") then
            error("Unable to find a 'doframe()' function.",0)
        end
        sx,sy,sw,sh=love.graphics.getScissor()
        love.graphics.push()
        love.graphics.setCanvas()
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(vm.canvas,0,0,0,3,3)
        love.graphics.present()

        love.timer.step()
		if love.timer then love.timer.sleep(0.001) end
	end
end
