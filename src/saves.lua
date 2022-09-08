if not love.filesystem.getInfo("saves","directory") then
    assert(love.filesystem.createDirectory("saves"))
end

local function check_filename(filename)
    filename:gsub("[^%a%d%-_%.]",function(c) error("invalid filename: "..filename,0) end)
end

local function check(filename)
    -- used for valid_save and save_exists
    return (pcall(check_filename,filename))
end

local function delete(filename)
    check_filename(filename)
    if not exists(filename) then return end
    assert(love.filesystem.delete("saves/"..filename..".nxsv"),"Error deleting file")
end

local function exists(filename)
    -- instead of erroring, just return false
    if not check(filename) then return false end
    -- boolean-ize the return value of love.filesystem.getInfo
    return not (not love.filesystem.getInfo("saves/"..filename..".nxsv","file"))
end

local function list(pattern)
    pattern = pattern or ".+"
    local ret = {}
    local files = love.filesystem.getDirectoryItems("saves")
    for i, filename in ipairs(files) do
        local info = love.filesystem.getInfo("saves/"..filename,"file")
        if info and filename:sub(-5)==".nxsv" then
            local fn=filename:sub(1,-6)
            if string.match(fn,pattern) then ret[#ret+1]=fn end
        end
    end
    return ret
end

local function load(filename)
    check_filename(filename) -- errors if invalid filename
    if not love.filesystem.getInfo("saves/"..filename..".nxsv","file") then
        error("no such save file \""..filename.."\"",0)
    end
    local file, err = love.filesystem.newFile("saves/"..filename..".nxsv","r")
    if not file then error(err,0) end
    local data, size = file:read()
    file:close()
    file:release()
    file=nil
    return data:sub(5), size-4
end

local function save(filename,data)
    check_filename(filename) -- errors if invalid filename
    local file, err = love.filesystem.newFile("saves/"..filename..".nxsv","w")
    if not file then error(err,0) end
    success, errstr = file:write("NXS\000"..data)
    if not success then error(errstr,0) end
    file:close()
    file:release()
    file=nil
    return
end

return {
    load=load,
    save=save,
    list=list,
    exists=exists,
    check=check,
    delete=delete
}
