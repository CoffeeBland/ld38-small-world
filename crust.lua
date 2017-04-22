crustal = love.graphics.newImage("imgs/crustal.png")

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
function Crustcle:poly()
    local poly = {}
    for i = 1, #self.pts do
        local pt = self.pts[i]
        poly[i*2-1] = math.cos(pt.a) * pt.r + self.x
        poly[i*2] = math.sin(pt.a) * pt.r + self.y
    end
    return poly
end
function Crustcle:update(dt)
    for i, pt in pairs(self.pts) do
        prevI = (#self.pts + i - 1) % #self.pts
        nextI = (i + 1) % #self.pts
        pt:update(dt, self.pts[prevI], self.pts[nextI])
    end
end
local function newCrustcle(segments)
    local pts = {}
    for i = 1, segments do
        local angle = i/segments * math.pi * 2
        pts[i] = Cruspt(48, math.random() * 3 + 2, angle, math.pi / segments)
    end
    crustcle = setmetatable({
        x = 100,
        y = 100,
        pts = pts
    }, Crustcle)
    return crustcle
end
setmetatable(Crustcle, {
    __call = function(_, ...) return newCrustcle(...) end
})