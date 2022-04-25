local title = "NeXUS"
local subtitle = "Version "..version()
local nogameloaded = "No game loaded"
local tx = math.floor((320/2)-(textwidth(title)/2))
local sx = math.floor((320/2)-(textwidth(subtitle)/2))
local nx = math.floor((320/2)-(textwidth(nogameloaded)/2))

local t=0
function doframe()
    cls(160)
    print(title,tx,(240/3)-8)
    print(subtitle,sx,(240/2)-8)
    if (math.floor(t/30)%2)==0 then print(nogameloaded,nx,(240*2/3)-8) end
    t=t+1
end
