-- 8 bit color (3-3-2)
-- Converts 3-3-2 color to LOVE2D's preferred float colors

local eightbitcolor = {}

function eightbitcolor.to_float(n)
    local r = bit.band(n,7)
    local g = bit.band(bit.rshift(n,3),7)
    local b = bit.band(bit.rshift(n,6),3)
    return r/7, g/7, b/3
end

function eightbitcolor.to_nearest(r,g,b)
    local rb = math.floor((r*7)+0.5)
    local gb = math.floor((g*7)+0.5)
    local bb = math.floor((b*3)+0.5)
    if rb>7 then rb=7 end
    if gb>7 then gb=7 end
    if bb>3 then bb=3 end
    if rb<0 then rb=0 end
    if gb<0 then gb=0 end
    if bb<0 then bb=0 end
    return bit.lshift(bb,6) + bit.lshift(gb,3) + rb
end

function eightbitcolor.check(n)
    return n>=0 and n<=255
end

return eightbitcolor
