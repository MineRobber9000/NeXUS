local ffi=require"ffi"
-- Load the Lua 5.4 DLL if we can find it.
-- Windows: lua54.dll is in the base directory
-- Mac/Linux: liblua54.so should be placed somewhere it'll be looked for
-- (set LD_LIBRARY_PATH to include the base directory)
local lualib = ffi.load("lua54")

-- a lua_State object (C) will be stored in the table as this.ptr
-- since I don't feel like defining the entire lua_State object, it's
-- passed around as a void pointer (they use it as a pointer in all of the
-- functions anyways)
local lua_State = {}

lua_State.__index = function(t,k)
    -- if we're here, then we're attempting to access a function on the
    -- lua_State object (Lua).
    -- step 1: is it something in this table?
    if lua_State[k] then return lua_State[k] end
    -- no? step 2: is it a defined main library function?
    if pcall(function() tmp=lualib["lua_"..k] end) then
        return function(this,...)
            return lualib["lua_"..k](this.ptr,...)
        end
    end
    -- no? step 3: is it a defined auxlib function?
    if pcall(function() tmp=lualib["luaL_"..k] end) then
        return function(this,...)
            return lualib["luaL_"..k](this.ptr,...)
        end
    end
    -- final step: is it a defined function in the lua library at all?
    if pcall(function() tmp=lualib[k] end) then
        return function(this,...)
            return lualib[k](this.ptr,...)
        end
    end
end

-- the CDEF block
-- it's all of the functions we've imported from lua
-- if you can't find it it's because it's supposed to be in here
-- sorted alphabetically
ffi.cdef[[
typedef int (*lua_CFunction)(void *L);
typedef int (*lua_KFunction)(void *state, int status, ptrdiff_t ctx);
const char *luaL_checklstring(void *L, int arg, size_t size);
int lua_getglobal(void *L, const char *name);
const char *luaL_tolstring (void *L, int idx, size_t *len);
const char *luaL_optlstring(void *L, int arg, const char *def, size_t size);
const char *lua_pushstring(void *L, const char *s);
const char *lua_typename(void *L, int tp);
double luaL_checknumber(void *L, int arg);
double luaL_optnumber(void *L, int arg, double def);
int luaL_callmeta(void *L, int obj, const char *e);
int luaL_error (void *L, const char *fmt, ...);
int lua_isfunction(void *L, int index);
int luaL_loadstring(void *L, const char *s);
int luaL_loadstring(void *L, const char *s);
int luaL_loadbufferx(void *L, const char *buff, size_t sz, const char *name, const char *mode);
int lua_gettop(void *L);
int lua_isstring(void *L, int idx);
int lua_pcallk(void *L, int nargs, int nresults, int msgh, ptrdiff_t ctx, lua_KFunction k);
int luaopen_base(void *L);
int luaopen_coroutine(void *L);
int luaopen_debug(void *L);
int luaopen_math(void *L);
int luaopen_string(void *L);
int luaopen_table(void *L);
int luaopen_utf8(void *L);
int lua_type(void *L, int index);
long long luaL_checkinteger(void *L, int arg);
long long luaL_optinteger(void *L, int arg, long long def);
void *luaL_newstate(void);
void luaL_requiref(void *L, const char *modname, lua_CFunction openf, int glb);
void luaL_traceback(void *L, void *L1, const char *msg, int level);
void lua_close (void *L);
void lua_pushboolean(void *L, int b);
void lua_pushcclosure(void *L, lua_CFunction fn, int upvalues);
void lua_pushinteger(void *L, long long val);
void lua_pushlightuserdata (void *L, void *p);
void lua_pushnil(void *L);
void lua_pushnumber(void *L, double val);
void lua_rotate(void *L, int index, int n);
void lua_setglobal(void *L, const char *name);
void lua_settop(void *L, int n);
]]

-- registers function fn with name name
-- fn should take a lua_State (Lua) as its only argument and return an integer
-- describing how many return values the function pushed onto the stack
-- this function will convert it to a function that C will accept
function lua_State.register(this,fn,name)
    jit.off(fn) -- ensure fn doesn't get JIT compiled, as that might end poorly
    if not this.wrappers[fn] then
        this.wrappers[fn]=function(L)
            -- takes lua_State (C) as argument, but ignores it
            -- since this wrapper being used means it's this one
            return fn(this)
        end
        jit.off(this.wrappers[fn]) -- same deal
    end
    -- set it in the global table
    this:pushcclosure(this.wrappers[fn],0)
    this:setglobal(name)
end

-- Pops n elements from the stack.
function lua_State.pop(this,n)
    this:settop(-(n)-1)
end

-- Checks whether the function argument arg is a string and returns this string.
function lua_State.checkstring(this,arg)
    local ret = this:checklstring(arg,0)
    if ret then return ffi.string(ret) end --better safe than sorry
end

function lua_State.optstring(this,arg,def)
    local ret = this:optlstring(arg,def,0)
    if ret then return ffi.string(ret) end --better safe than sorry
end

function lua_State.insert(this,idx)
    this:rotate(idx,1)
end

function lua_State.remove(this,idx)
    this:rotate(idx,-1)
    this:pop(1)
end

-- type variables
lua_State.LUA_TNIL=0
lua_State.LUA_TBOOLEAN=1
lua_State.LUA_TLIGHTUSERDATA=2
lua_State.LUA_TNUMBER=3
lua_State.LUA_TSTRING=4
lua_State.LUA_TTABLE=5
lua_State.LUA_TFUNCTION=6
lua_State.LUA_TUSERDATA=7
lua_State.LUA_TTHREAD=8

function lua_State.isnoneornil(this,index)
    return this:type(index)<=this.LUA_TNIL
end

function lua_State.isboolean(this,index)
    return this:type(index)==this.LUA_TBOOLEAN
end

function lua_State.islightuserdata(this,index)
    return this:type(index)==this.LUA_TLIGHTUSERDATA
end

function lua_State.isnumber(this,index)
    return this:type(index)==this.LUA_TNUMBER
end

function lua_State.isstring(this,index)
    return this:lua_isstring(index)==1
end

function lua_State.istable(this,index)
    return this:type(index)==this.LUA_TTABLE
end

function lua_State.isfunction(this,index)
    return this:type(index)==this.LUA_FUNCTION
end

function lua_State.isuserdata(this,index)
    return this:type(index)==this.LUA_TUSERDATA
end

function lua_State.isthread(this,index)
    return this:type(index)==this.LUA_TTHREAD
end

function lua_State.tostring(this,index)
    return this:tolstring(index,0)
end

-- Calls a function or callable object in protected mode.
function lua_State.pcall(this,nargs,nresults,msgh)
    return this:pcallk(nargs,nresults,msgh,0,nil)
end

-- Loads a string as Lua 5.4 code
function lua_State.loadstring(this,str,name)
    name = name or "[loaded code]"
    this.state:loadbufferx(str,#str,name,"t")
end

-- adds a stack trace to Lua 5.4 errors
-- effectively a port to LuaJIT of the stock Lua interpreter's error handler
local function messagehandler(L)
    local this = lua_State.c_to_lua(L)
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

-- calls the function on top of the stack with nargs arguments, returning nres
-- results
function lua_State.docall(this,nargs,nres)
    base = this:gettop()-nargs
    this:pushcclosure(mh,0)
    this:insert(base)
    local res = this:pcall(nargs,nres,base)
    this:remove(base)
    return res
end

function lua_State.nullify(this,name)
    this:pushnil()
    this:setglobal(name)
end

-- initialize new lua_State (Lua) object
-- initializes a lua_State (C) object, and installs every library but io/os
local libs = {
    {"_G",lualib.luaopen_base},
    {"coroutine",lualib.luaopen_coroutine},
    {"table",lualib.luaopen_table},
    {"string",lualib.luaopen_string},
    {"math",lualib.luaopen_math},
    {"utf8",lualib.luaopen_utf8},
    {"debug",lualib.luaopen_debug}
}
function lua_State.new()
    local ret = setmetatable({["ptr"]=lualib.luaL_newstate(),["wrappers"]={}},lua_State)
    ret.ptr=ffi.gc(ret.ptr,lualib.lua_close)
    for i=1,#libs do
        ret:requiref(libs[i][1],libs[i][2],1)
        ret:pop(1) -- remove lib from stack
    end
    ret:nullify("dofile")
    ret:nullify("loadfile")
    return ret
end

function lua_State.c_to_lua(ptr)
    return setmetatable({["ptr"]=ptr,["wrappers"]={}},lua_State)
end

return lua_State
