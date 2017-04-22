Cruspt = {}
Cruspt.__index = Cruspt
function Cruspt:update(dt)
    self.t = self.t + self.dt
    self.r = self.sR + math.sin(self.t) * self.rBounds
    self.a = self.sA + math.sin(self.t) * self.aBounds
end
local function newCruspt(r, rBounds, a, aBounds)
    local dt = (math.random() + 2) * 2 * math.pi / 360
    return setmetatable({
        t = math.random() * 2 * math.pi, dt = dt,
        sR = r, r = r,
        rBounds = rBounds,
        sA = a, a = a,
        aBounds = aBounds
    }, Cruspt)
end
setmetatable(Cruspt, {
    __call = function(_, ...) return newCruspt(...) end
})


Crustcle = {}
Crustcle.__index = Crustcle
function Crustcle:poly(camera)
    local cx, cy = camera:pos()
    local poly = {}
    for i = 1, #self.pts do
        local pt = self.pts[i]
        poly[i*2-1] = math.cos(pt.a) * pt.r + self.x - cx
        poly[i*2] = math.sin(pt.a) * pt.r + self.y - cy
    end
    return poly
end
function Crustcle:update(dt)
    for i, pt in pairs(self.pts) do
        prevI = (#self.pts + i - 1) % #self.pts
        nextI = (i + 1) % #self.pts
        pt:update(dt, self.pts[prevI], self.pts[nextI])
    end
    self.x = crustal.x
    self.y = crustal.y
end
local function newCrustcle(size)
    local segments = floor(size / 3)
    local pts = {}
    for i = 1, segments do
        local angle = i/segments * math.pi * 2
        pts[i] = Cruspt(size, math.random() * (size/32) + (size/48), angle, math.pi / segments)
    end
    crustcle = setmetatable({
        x = 0,
        y = 0,
        pts = pts
    }, Crustcle)
    return crustcle
end
setmetatable(Crustcle, {
    __call = function(_, ...) return newCrustcle(...) end
})


Crustal = {}
Crustal.__index = Crustal
function Crustal:draw(camera)
    local cx, cy = camera:pos()
    self.sprite:draw(self.x - cx, self.y - cy)
end
function Crustal:update(dt)
end
function Crustal:pos()
  return self.x, self.y
end
local function newCrustal(x, y)
    return setmetatable({
      x = x or 0,
      y = y or 0,
      sprite = AnimSprite("crustal.png", 24, 24)
    }, Crustal)
end
setmetatable(Crustal, {
    __call = function(_, ...) return newCrustal(...) end
})
