local lua54 = require"lua54"
local eightbitcolor = require"eightbitcolor"

local api = {}

-- graphics functions here
function api.circ(vm)
    local x=tonumber(vm:checknumber(1))
    local y=tonumber(vm:checknumber(2))
    local rad=tonumber(vm:checknumber(3))
    local color = tonumber(vm:checkinteger(4))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    local r,g,b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    love.graphics.circle("fill",x,y,rad)
    return 0
end

function api.circb(vm)
    local x=tonumber(vm:checknumber(1))
    local y=tonumber(vm:checknumber(2))
    local rad=tonumber(vm:checknumber(3))
    local color = tonumber(vm:checkinteger(4))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    local r,g,b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    love.graphics.circle("line",x,y,rad)
    return 0
end

function api.clip(vm)
    if vm:isnoneornil(1) then
        love.graphics.setScissor()
    else
        local x=tonumber(vm:checkinteger(1))
        local y=tonumber(vm:checkinteger(2))
        local w=tonumber(vm:checkinteger(3))
        local h=tonumber(vm:checkinteger(4))
        love.graphics.setScissor(x,y,w,h)
    end
    return 0
end

function api.cls(vm)
    local color = tonumber(vm:optinteger(1,0))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    -- invalidate imagedata cache if we have it
    if vm.imagedata then
        vm.imagedata:release()
        vm.imagedata=nil
    end
    love.graphics.clear(eightbitcolor.to_float(color))
    return 0
end

function api.line(vm)
    local x1 = math.floor(tonumber(vm:checknumber(1)))
    local y1 = math.floor(tonumber(vm:checknumber(2)))
    local x2 = math.floor(tonumber(vm:checknumber(3)))
    local y2 = math.floor(tonumber(vm:checknumber(4)))
    local color = tonumber(vm:checkinteger(5))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    local r,g,b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    love.graphics.line(x1,y1,x2,y2)
    return 0
end

function api.rect(vm)
    local x = math.floor(tonumber(vm:checknumber(1)))
    local y = math.floor(tonumber(vm:checknumber(2)))
    local w = math.floor(tonumber(vm:checknumber(3)))
    local h = math.floor(tonumber(vm:checknumber(4)))
    local color = tonumber(vm:checkinteger(5))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    if vm.imagedata then
        vm.imagedata:release()
        vm.imagedata=nil
    end
    local r, g, b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    love.graphics.rectangle("fill",x,y,w,h)
    return 0
end

function api.rectb(vm)
    local x = math.floor(tonumber(vm:checknumber(1)))
    local y = math.floor(tonumber(vm:checknumber(2)))
    local w = math.floor(tonumber(vm:checknumber(3)))
    local h = math.floor(tonumber(vm:checknumber(4)))
    local color = tonumber(vm:checkinteger(5))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    if w<=0 or h<=0 then return 0 end
    if vm.imagedata then
        vm.imagedata:release()
        vm.imagedata=nil
    end
    local r, g, b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    if w==1 and h==1 then
        love.graphics.rectangle("fill",x,y,1,1)
    elseif w==1 then
        love.graphics.rectangle("fill",x,y,1,h)
    elseif h==1 then
        love.graphics.rectangle("fill",x,y,w,1)
    else
        love.graphics.rectangle("line",x+0.5,y+0.5,w-1,h-1)
    end
    return 0
end

function api.pix(vm)
    local x = tonumber(vm:checkinteger(1))
    local y = tonumber(vm:checkinteger(2))
    local color = tonumber(vm:optinteger(3,-1))
    -- THIS FUNCTION IS VERY HACKY
    -- it is *not* performant, it is *not* something you should be doing
    -- basically we keep an imagedata around until one of the other functions
    -- draws to the screen
    -- that way, successive reads of the screen will occur relatively quickly
    -- so if you have to do full screen per-pixel effects (most of the time you
    -- don't), read all of the pixels you need and THEN manipulate them
    -- writes are fast, reads are not (unless you do all of the reads at once)
    if color==-1 then
        -- pull down the imagedata if we don't have it
        if not vm.imagedata then
            local sx,sy,sw,sh = love.graphics.getScissor()
            love.graphics.push()
            love.graphics.setCanvas()
            vm.imagedata = vm.canvas:newImageData()
            love.graphics.setCanvas(vm.canvas)
            if not vm.font then vm.font=love.graphics.newFont("font.ttf",16) end
            love.graphics.setFont(vm.font)
            love.graphics.pop()
            love.graphics.setScissor(sx,sy,sw,sh)
        end
        -- get the color
        vm:pushinteger(eightbitcolor.to_nearest(vm.imagedata:getPixel(x,y)))
        return 1
    else
        if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
        -- get the color in RGB 0-1
        local r,g,b = eightbitcolor.to_float(color)
        if vm.imagedata then vm.imagedata:release() vm.imagedata=nil end
        -- draw the pixel
        love.graphics.setColor(r,g,b,1)
        love.graphics.rectangle("fill",x,y,1,1)
        return 0 -- no return values
    end
end

function api.print(vm)
    local str = vm:checkstring(1)
    local x = tonumber(vm:optnumber(2,0))
    local y = tonumber(vm:optnumber(3,0))
    local color = tonumber(vm:optinteger(4,255)) -- default white text
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    if vm.imagedata then
        vm.imagedata:release()
        vm.imagedata=nil
    end
    local r, g, b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    love.graphics.print(str,tonumber(x),tonumber(y))
    return 0
end

function api.textwidth(vm)
    local str = tostring(vm:checkstring(1))
    if not vm.font then vm.font=love.graphics.newFont("font.ttf",16) end
    vm:pushinteger(vm.font:getWidth(str))
    return 1
end

function api.tri(vm)
    local x1=tonumber(vm:checknumber(1))
    local y1=tonumber(vm:checknumber(2))
    local x2=tonumber(vm:checknumber(3))
    local y2=tonumber(vm:checknumber(4))
    local x3=tonumber(vm:checknumber(5))
    local y3=tonumber(vm:checknumber(6))
    local color = tonumber(vm:checkinteger(7))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    local r,g,b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    love.graphics.polygon("fill",x1,y1,x2,y2,x3,y3)
    return 0
end

function api.trib(vm)
    local x1=tonumber(vm:checknumber(1))
    local y1=tonumber(vm:checknumber(2))
    local x2=tonumber(vm:checknumber(3))
    local y2=tonumber(vm:checknumber(4))
    local x3=tonumber(vm:checknumber(5))
    local y3=tonumber(vm:checknumber(6))
    local color = tonumber(vm:checkinteger(7))
    if not eightbitcolor.check(color) then vm:error("invalid color "..tostring(color)) end
    local r,g,b = eightbitcolor.to_float(color)
    love.graphics.setColor(r,g,b,1)
    love.graphics.polygon("line",x1,y1,x2,y2,x3,y3)
    return 0
end
-- end graphics functions

-- input functions
local btnmapping = {[0]="up","down","left","right","z","x","lshift","return"}
function api.btn(vm)
    local id = tonumber(vm:checkinteger(1))
    if id<0 or id>7 then vm:error("invalid button ID "..tostring(id)) end
    vm:pushboolean(love.keyboard.isDown(btnmapping[id]))
    return 1
end
-- end input functions

-- util functions

function api.epoch(vm)
    -- eventually i'd like to give milliseconds but for now full seconds will have to do
    vm:pushnumber(os.time())
    return 1
end

function api.version(vm)
    vm:pushstring("Alpha")
    return 1
end

-- end util functions

-- the VM is a lua_State (Lua) object that has a higher awareness and can have
-- more state attached to it
local VM = {}
VM.__index=function(t,k)
    if VM[k] then return VM[k] end
    local r=t.state[k]
    if r then return r end
end

function VM.new(deferinit)
    local ret = setmetatable({},VM)
    if not deferinit then ret:init() end
    return ret
end

function VM.init(this)
    if rawget(this,"wrappers_cb") then
        for k,v in pairs(this.wrappers_cb) do
            v:free()
        end
    end
    this.state = lua54.new()
    this.wrappers = {}
    this.wrappers_cb = {}
    for k, v in pairs(api) do
        this:register(v,k)
    end
end

function VM.register(this,func,name)
    jit.off(func)
    if not this.wrappers[func] then
        this.wrappers[func]=function(L)
            -- takes a lua_State (C) object but disregards it in favor of
            -- calling the function with the VM object
            return (func(this) or error("Registered function "..name.." is missing a return statement!",2))
        end
        jit.off(this.wrappers[func])
        this.wrappers_cb[func]=require("ffi").cast("lua_CFunction",this.wrappers[func])
    end
    --this is where we would register it via lua_State.register
    --instead since we've already created a wrapper, we'll manually register it
    this:pushcclosure(this.wrappers_cb[func],0)
    this:setglobal(name)
end

function VM.loadstring(this,str,name)
    name = name or "[loaded code]"
    this.state:loadbufferx(str,#str,name,"t")
end

local function messagehandler(L)
    local this = lua54.c_to_lua(L)
    msg = this:checkstring(1)
    this:pop(1)
    if not msg then
        if (this:callmeta(1,"__tostring")>0)
        and (this:type(-1)==4) then
            -- tostring method and it returned a string
            return 1 -- that's your error message right there
        else
            msg = "(error object is a "..ffi.string(this.state:typename(1)).." value)"
        end
    end
    this:traceback(this.ptr,msg,1)
    return 1
end
jit.off(messagehandler)
local mh = require("ffi").cast("lua_CFunction",messagehandler)

function VM.docall(this,nargs,nres)
    base = this.state:gettop()-nargs
    this.state:pushcclosure(mh,0)
    this.state:insert(base)
    local res = this.state:pcall(nargs,nres,base)
    this.state:remove(base)
    return res
end

return VM
