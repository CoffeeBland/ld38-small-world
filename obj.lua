Obj = {}
Obj.__index = Obj
local function newObj()
    return setmetatable({
      x = 0,
      y = 0,
    }, Obj)
end
setmetatable(Obj, {
    __call = function(_, ...) return newObj(...) end
})
function Obj:update(dt)
end