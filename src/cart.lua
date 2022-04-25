local riff = require"riff"

local Cart = {}
Cart.__index = Cart

function Cart.handle_chunks(this,chunks)
    this.code = ""
    for i=1,#chunks do
        if chunks[i].id=="CODE" then
            this.code = this.code..chunks[i].raw
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
