Cruspt = {}
Cruspt.__index = Cruspt
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
function Cruspt:update(dt)
    self.t = self.t + self.dt
    self.r = self.sR + math.sin(self.t) * self.rBounds
    self.a = self.sA + math.sin(self.t) * self.aBounds
end


Crustcle = {}
Crustcle.__index = Crustcle
local function newCrustcle(size)
    local segments = floor(size / 8)
    local pts = {}
    for i = 1, segments do
        local angle = i/segments * math.pi * 2
        pts[i] = Cruspt(size, math.random() * (size/8) + (size/48), angle, math.pi / segments)
    end
    crustcle = setmetatable({
        x = 0,
        y = 0,
        pts = pts,
        size = size,
        size2 = pow(size, 2)
    }, Crustcle)
    return crustcle
end
setmetatable(Crustcle, {
    __call = function(_, ...) return newCrustcle(...) end
})
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
function Crustcle:inside(x, y)
    return pow(x - self.x, 2) + pow(y - self.y, 2) < self.size2
end


CRUSTAL_TARGET_SIZE = 2500
Crustal = {}
Crustal.__index = Crustal
local function newCrustal(x, y, size)
    local img = love.graphics.newImage("imgs/crustal.png")
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(12)
    local fixture = love.physics.newFixture(body, shape, 1)
    obj = setmetatable({
        body = body,
        shape = shape,
        fixture, fixture,
        x = x or 0,
        y = y or 0,
        lastSparkle = 0,
        targetX = (x or 0) + ((rand()-0.5) * CRUSTAL_TARGET_SIZE),
        targetY = (y or 0) + ((rand()-0.5) * CRUSTAL_TARGET_SIZE),
        sprite = AnimSprite(img, 24, 32, 30, true, 12, 24),
        size = size,
    }, Crustal)
    fixture:setCategory(CAT_FRIENDLY)
    fixture:setUserData(obj)
    return obj
end
setmetatable(Crustal, {
    __call = function(_, ...) return newCrustal(...) end
})
function Crustal:draw(camera)
    local cx, cy = camera:pos()
    self.sprite:draw(self.x - cx, self.y - cy)
end
function Crustal:update(dt)
    self.x = self.x + ((self.x < self.targetX) and 0.5 or -0.5)
    self.y = self.y + ((self.y < self.targetY) and 0.5 or -0.5)

    if (self.targetX - self.x) < 20 and self.targetY - self.y < 20 then
        self.targetX = self.x + ((rand()-0.5) * CRUSTAL_TARGET_SIZE)
        self.targetY = self.y + ((rand()-0.5) * CRUSTAL_TARGET_SIZE)
    end

    -- Leave a trail of sparkles
    local t = love.timer.getTime()
    if t - self.lastSparkle > 0.05 then
        local x, y = self.x, self.y
        -- Randomise starting x,y in a 24px circle
        local r = rand() * 64
        local a = rand() * 2 * pi
        x = x + r*cos(a)
        y = y + r*sin(a)
        -- Add in current velocity
        x = x + ((self.x < self.targetX) and -12 or 12)
        y = y + ((self.y < self.targetY) and -12 or 12)
        addActor(Sparkle(x, y))
        self.lastSparkle = t
    end
    --if rand() < 0.05 then
        local a = rand() * 2 * pi
        local r = rand() * self.size
        addActor(MiniSpark(self.x + cos(a) * r, self.y + sin(a) * r))
    --end
end
function Crustal:getZ()
    return self.y
end
function Crustal:pos()
    return self.x, self.y
end
