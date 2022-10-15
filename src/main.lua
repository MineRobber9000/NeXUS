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
    vm.cart = Cart.new("nogameloaded.rom")
    vm.font = love.graphics.newFont("font.ttf",16)
    vm.canvas = love.graphics.newCanvas(320,240)
    vm:init()
    if vm:loadstring(vm.cart.code)>0 then
        error(vm:checkstring(-1))
    end
    if vm:docall(0,0)>0 then
        error(vm:checkstring(-1))
    end
    -- for some reason this line breaks font rendering, so for now we're just gonna leave it
    -- love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.origin()
    love.graphics.push()
    local sx, sy, sw, sh = nil, nil, nil, nil
    local first = true
    local showFPS = false
    local fpsFont = love.graphics.newFont("font.ttf",32)
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
                elseif name == "keypressed" and a == "r" and love.keyboard.isDown("lctrl", "rctrl") then
                    vm.canvas:renderTo(function() love.graphics.clear() end)
                    vm:init()
                    vm:loadstring(vm.cart.code)
                    if vm:docall(0,0)>0 then
                        error(vm:checkstring(-1))
                    end
                elseif name == "keypressed" and a == "f" and love.keyboard.isDown("lctrl", "rctrl") then
                    showFPS = not showFPS
                elseif name == "filedropped" then
                    a:open('r')
                    -- this is needed to smooth over some gaps in love files vs
                    -- base lua files
                    local proxy = setmetatable({},{__index=function(t,k)
                        if k=="read" then
                            return function(this,n)
                                if n=="*a" then n=nil end
                                return (a[k](a,"string",n))
                            end
                        else
                            return function(this,...)
                                return a[k](ret2,...)
                            end
                        end
                    end})
                    vm.cart = Cart.new(proxy)
                    a:close()
                    vm.canvas:renderTo(function() love.graphics.clear() end)
                    vm:init()
                    if vm:loadstring(vm.cart.code)>0 then
                        error(vm:checkstring(-1),0)
                    end
                    if vm:docall(0,0)>0 then
                        error(vm:checkstring(-1))
                    end
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
        if showFPS then love.graphics.setFont(fpsFont) love.graphics.print("FPS: "..love.timer.getFPS(),1,1) end
        love.graphics.present()

        love.timer.step()
		if love.timer then love.timer.sleep(0.001) end
	end
end
