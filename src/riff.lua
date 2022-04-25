-- Library for loading and saving RIFF files
-- "Created" for use in the MCA library and now being used in NeXUS
-- Really I just adapted an example given in the project's README
-- for the loading
-- But I added some features to it so I guess that counts
-- The saving was all me though
-- Licensed under CC0 if I can get away with it, Unlicense if not
-- copyleft Robert "khuxkm/minerobber" Miles

-- parse_chunk and parse_riff take Blob objects (Blobjects?)
-- parse_riff_file takes either a file handle or a string
-- if you pass it a string it opens the file handle itself
-- and closes it when it's done

local Blob = require"Blob"

Blob.types.fourcc = "c4"

-- localize the Lua API functions we use for... reasons
local tableinsert = table.insert
local stringsub = string.sub
local assert = assert
-- the original was written for normal Lua, sub in the LOVE mechanics
local ioopen = function(fn,mode)
    local ret2 = love.filesystem.newFile(fn)
    -- the base Lua API requires "rb" and "wb" but we'll just give "r" and "w"
    assert(ret2:open(mode:sub(1,1)))
    -- smooth over some wrinkles in the API
    local ret = setmetatable({},{__index=function(t,k)
        if k=="read" then
            return function(this,n)
                if n=="*a" then n=nil end
                return (ret2[k](ret2,"string",n))
            end
        else
            return function(this,...)
                return ret2[k](ret2,...)
            end
        end
    end})
    return ret
end

local function parse_chunk(blob)
    local chunk = {}
    chunk.id = blob:fourcc()
    chunk.size = blob:uint32()
    -- Both RIFF and LIST chunks contain a four character type
    if chunk.id == "RIFF" or chunk.id == "LIST" then
        chunk.form_type = blob:fourcc()
        chunk.nested = {}
        local begin = blob.pos - 4
        while blob.pos < (begin + chunk.size) do
          tableinsert(chunk.nested, parse_chunk(blob))
        end
    else
        chunk.content = blob:split(chunk.size) -- split off a blob of `size` bytes
        -- I needed this for MCA loading so here it is
        chunk.raw = stringsub(chunk.content.buffer,chunk.content.offset+chunk.content.pos,chunk.content.offset+chunk.content.pos+chunk.size-1)
        blob:pad("word") -- Skip padding to the next word boundary
    end
    return chunk
end

local function parse_riff(blob)
    local riff = parse_chunk(blob)
    assert(riff.id == "RIFF","RIFF file must contain RIFF chunk at root!")
    return riff
end

local function parse_riff_file(f,form_type,form_error)
    form_error = form_error or (form_type and "expected RIFF file of form '"..form_type.."' but got '%s' instead" or "this'll never show up")
    local fh, close_fh = f, false
    if type(f)=="string" then
        fh = assert(ioopen(f,"rb"))
        close_fh=true
    end
    local blob = Blob.new(fh:read("*a"))
    local riff = parse_riff(blob)
    if form_type then assert(riff.form_type==form_type,string.format(form_error,riff.form_type)) end
    if close_fh then fh:close() end
    return riff
end

-- encode_chunk takes a fourcc and some string data
-- you're on your own for ensuring the data is in the right format
-- before it gets there
-- encode_riff_or_list ensures padding for whichever of the two
-- are being saved (all chunks must begin on word boundaries)
-- and it takes the fourcc "RIFF" or "LIST", the fourcc of
-- the RIFF/LIST form, and a list of encoded chunks
-- encode_riff_file is like parse_riff_file but in reverse
-- it takes the file(name), the fourcc form code and a list of
-- encoded chunks and returns nothing

local function encode_chunk(fourcc,rawdata)
    return love.data.pack("string","c4I4",fourcc,#rawdata)..rawdata
end

local function encode_riff_or_list(ckID,fourcc,chunks)
    local buffer = ""
    for i=1,#chunks do
        buffer = buffer..chunks[i]
        if (#buffer%2)==1 then buffer=buffer..string.char(0) end
    end
    return encode_chunk(ckID,fourcc..buffer)
end

local function encode_riff_file(f,form_type,chunks)
    local fh, close_fh = f, false
    if type(f)=="string" then
        fh = assert(ioopen(f,"wb"))
        close_fh=true
    end
    local data = encode_riff_or_list("RIFF",form_type,chunks)
    f:write(data)
    if close_fh then fh:close() end
end

return {
    parse_chunk = parse_chunk,
    parse_riff = parse_riff,
    parse_riff_file = parse_riff_file,

    encode_chunk = encode_chunk,
    encode_riff_or_list = encode_riff_or_list,
    encode_riff_file = encode_riff_file
}
