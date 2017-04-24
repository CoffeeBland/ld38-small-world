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

CRUSTAL_TARGET_SIZE = 2500
Crustal = {}
Crustal.__index = Crustal
local function newCrustal(size, x, y)
    local img = love.graphics.newImage("imgs/crustal.png")

    local body = love.physics.newBody(world, x or 0, y or 0, "kinematic")
    local shape = love.physics.newCircleShape(12)
    local fixture = love.physics.newFixture(body, shape, 1)

    local segments = floor(size / 8)
    local pts = {}
    for i = 1, segments do
        local angle = i/segments * math.pi * 2
        pts[i] = Cruspt(size, math.random() * (size/8) + (size/48), angle, math.pi / segments)
    end

    obj = setmetatable({
        body = body,
        shape = shape,
        fixture, fixture,
        lastSparkle = 0,
        targetX = (x or 0) + ((rand() - 0.5) * CRUSTAL_TARGET_SIZE),
        targetY = (y or 0) + ((rand() - 0.5) * CRUSTAL_TARGET_SIZE),
        sprite = AnimSprite(img, 24, 32, 30, true, 12, 24),
        pts = pts,
        size = size,
        size2 = pow(size, 2),
        remaining = 1,
        remaining2 = 1,
        damaged = 0,
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
    local x, y = self:pos()
    local col = (self.damaged > 0 and magenta) or (self.damaged < 0 and teal) or white
    self.sprite:draw(x - cx, y - cy, col)
end
function Crustal:update(dt)
    if self.damaged ~= 0 then
        self.damaged = self.damaged - sign(self.damaged)
    end

    local x, y = self:pos()

    self.body:setLinearVelocity(
        ((x < self.targetX) and 60 or -60),
        ((y < self.targetY) and 60 or -60))

    if (dst2(self.targetX - x, self.targetY - y) < 400) then
        self.targetX = x + ((rand()-0.5) * CRUSTAL_TARGET_SIZE)
        self.targetY = y + ((rand()-0.5) * CRUSTAL_TARGET_SIZE)
    end

    -- Leave a trail of sparkles
    local t = love.timer.getTime()
    if t - self.lastSparkle > 0.05 then
        -- Randomise starting x,y in a 24px circle
        local r = rand() * 64
        local a = rand() * 2 * pi
        x = x + r*cos(a)
        y = y + r*sin(a)
        -- Add in current velocity
        x = x + (x < self.targetX and -12 or 12)
        y = y + (y < self.targetY and -12 or 12)
        addActor(Sparkle(x, y))
        self.lastSparkle = t
    end
    local a = rand() * 2 * pi
    local r = rand() * self.size
    addActor(MiniSpark(x + cos(a) * r, y + sin(a) * r))

    for i, pt in pairs(self.pts) do
        prevI = (#self.pts + i - 1) % #self.pts
        nextI = (i + 1) % #self.pts
        pt:update(dt, self.pts[prevI], self.pts[nextI])
    end

    self.remaining2 = 0.75 * life / initialLife + 0.25
    self.remaining = sqrt(self.remaining2)
    self.sprite:update(dt)
end
function Crustal:getZ()
    return self.body:getY()
end
function Crustal:pos()
    return self.body:getX(), self.body:getY()
end
function Crustal:poly(camera)
    local x, y = self:pos()
    local cx, cy = camera:pos()
    local poly = {}
    for i = 1, #self.pts do
        local pt = self.pts[i]
        poly[i*2-1] = (math.cos(pt.a) * pt.r) * self.remaining + x - cx
        poly[i*2] = (math.sin(pt.a) * pt.r) * self.remaining + y - cy
    end
    return poly
end
function Crustal:inside(x, y)
    local selfX, selfY = self:pos()
    return pow(x - selfX, 2) + pow(y - selfY, 2) < (self.size2 * self.remaining2)
end
