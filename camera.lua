Camera = {}
Camera.__index = Camera
local function newCamera()
    return setmetatable({
      x = 0,
      y = 0,
    }, Camera)
end
function Camera:update(dt)
end
function Camera:pos()
  local w, h = love.graphics.getDimensions()
  return self.x - w/2, self.y - h/2
end
setmetatable(Camera, {
    __call = function(_, ...) return newCamera(...) end
})
