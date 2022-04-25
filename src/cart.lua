local riff = require"riff"
local eightbitcolor = require"eightbitcolor"

local Cart = {}
Cart.__index = Cart

function Cart.handle_chunks(this,chunks)
    this.code = ""
    this.images = {}
    for i=1,#chunks do
        if chunks[i].id=="CODE" then
            this.code = this.code..chunks[i].raw
        elseif chunks[i].id=="GRPH" then
            local id = chunks[i].content:uint32()
            local width = chunks[i].content:uint32()
            local height = chunks[i].content:uint32()
            local imgdata = love.image.newImageData(width,height)
            for y=0,height-1 do
                for x=0,width-1 do
                    local r,g,b = eightbitcolor.to_float(chunks[i].content:uint8())
                    imgdata:setPixel(x,y,r,g,b,1)
                end
            end
            this.images[id]=imgdata
        end
    end
end

function Cart.new(file)
    local ret = setmetatable({},Cart)
    local ok, chunk = pcall(riff.parse_riff_file,file,"NXSR")
    if not ok then error("Malformed ROM! Details: "..chunk,2) end
    ret:handle_chunks(chunk.nested)
    return ret
end

return Cart
