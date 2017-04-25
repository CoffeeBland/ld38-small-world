Projectile = {}
Projectile.__index = Projectile
local function newProjectile(sprite, x, y, shape, ttl, helpText)
    local body = love.physics.newBody(world, x, y, "kinematic")
    body:setFixedRotation(true)
    local obj = setmetatable({
        sprite = sprite,
        body = body,
        shape = shape,
        ttl = ttl,
        helpText = helpText,
    }, Projectile)
    if shape then
        obj.fixture = love.physics.newFixture(body, shape, 1)
        obj.fixture:setUserData(obj)
    end
    return obj
end
setmetatable(Projectile, {
    __call = function(_, ...) return newProjectile(...) end
})
function Projectile:draw(camera)
    local cx, cy = camera:pos()
    local x, y = self:pos()
    self.sprite:draw(x - cx, y - cy)
    if self.helpText then
        local textW = smallFont:getWidth(self.helpText)
        love.graphics.setFont(smallFont)
        love.graphics.setColor(255, 255, 230, 160)
        love.graphics.print(self.helpText, x - cx - (textW / 2), y - cy - self.sprite.th)
    end
end
function Projectile:getZ()
    return self.body:getY()
end
function Projectile:pos()
    return self.body:getX(), self.body:getY()
end
function Projectile:update(dt)
    self.sprite:update(dt)
    self.ttl = self.ttl - 1
    if self.ttl <= 0 then
        self.shouldRemove = true
    end
end
function Projectile:destroy()
    removeBody(self)
end


local bulletImg = love.graphics.newImage("imgs/bullet.png")
function bulletCollide(self, other)
    if getmetatable(other) == Enemy then
        other:hit(self)
    end
end
function bulletDestroy(self)
    addActor(BlueBoom(self:pos()))
    removeBody(self)
end
function Bullet(x, y, dirX, dirY)
    local shape = love.physics.newCircleShape(8)
    p = Projectile(AnimSprite(bulletImg, 12, 24, 2, true, 6, 20), x, y, shape, 3 * 60)
    p.body:setLinearVelocity(dirX * 480, dirY * 480)
    --p.fixture:setFilterData(CAT_FRIENDLY, 0, 0)
    p.fixture:setSensor(true)
    p.collide = bulletCollide
    p.destroy = bulletDestroy
    return p
end

local redBoomImg = love.graphics.newImage("imgs/red-boom.png")
function redExplosionCollide(self, other)
    if getmetatable(other) == Player then
        damageTripod(20)
    end
end
function redExplosionDestroy(self)
    removeBody(self)
end
function RedExplosion(x, y)
    local shape = love.physics.newCircleShape(16)
    p = Projectile(AnimSprite(redBoomImg, 32, 32, 4), x, y, shape, 20)
    p.fixture:setSensor(true)
    p.collide = redExplosionCollide
    p.destroy = redExplosionDestroy
    return p
end

local itemHealthImg = love.graphics.newImage("imgs/item_health.png")
local itemHealthSprite = AnimSprite(itemHealthImg, 32, 32)
function itemHealthCollide(self, other)
    if getmetatable(other) == Player then
        self.shouldRemove = true
        damageCrustal(-20)
    end
end
function ItemHealth(x, y)
    local shape = love.physics.newCircleShape(20)
    local ttl = 8 * 60 -- Disapear after 8 sec
    p = Projectile(itemHealthSprite, x, y, shape, ttl)
    p.fixture:setSensor(true)
    p.collide = itemHealthCollide
    return p
end

local itemSpecialWaveImg = love.graphics.newImage("imgs/item_special_wave.png")
local itemSpecialWaveSprite = AnimSprite(itemSpecialWaveImg, 32, 32)
function itemSpecialWaveCollide(self, other)
    if getmetatable(other) == Player then
        self.shouldRemove = true
        player.specialWaveReady = true
    end
end
function ItemSpecialWave(x, y)
    local shape = love.physics.newCircleShape(20)
    local ttl = 4 * 60 -- Disapear after 4 sec
    p = Projectile(itemSpecialWaveSprite, x, y, shape, ttl)
    p.fixture:setSensor(true)
    p.collide = itemSpecialWaveCollide
    return p
end

local sparkleImg = love.graphics.newImage("imgs/sparkle.png")
function Sparkle(x, y)
    return Projectile(AnimSprite(sparkleImg, 16, 16, 8), x, y, nil, 32)
end

local miniSparkImg = love.graphics.newImage("imgs/mini-spark.png")
function MiniSpark(x, y)
    return Projectile(AnimSprite(miniSparkImg, 8, 8, 2), x, y, nil, 8)
end

local bloodSplatterImg = love.graphics.newImage("imgs/blood-splatter.png")
function BloodSplatter(x, y)
    return Projectile(AnimSprite(bloodSplatterImg, 48, 48, 4), x, y, nil, 16)
end

local bloodSplatterBigImg = love.graphics.newImage("imgs/blood-splatter-big.png")
function BloodSplatterBig(x, y)
    return Projectile(AnimSprite(bloodSplatterBigImg, 96, 96, 6, true, 48, 64), x, y, nil, 24)
end

local blueBoomImg = love.graphics.newImage("imgs/blue-boom.png")
function BlueBoom(x, y)
    return Projectile(AnimSprite(blueBoomImg, 24, 24, 6, false, 12, 24), x, y, nil, 18)
end

local blueBadaboum = love.graphics.newImage('imgs/blue-badaboum.png')
function BlueBadaboum(x, y)
    return Projectile(AnimSprite(blueBadaboum, 128, 128, 6, false), x, y, nil, 30)
end

Beam = {}
Beam.__index = Beam
local function newBeam(source, oX, oY, eX, eY, wFunc, cFunc, ttl)
    local x, y = source:pos()
    return setmetatable({
        source = source,
        sourceX = x,
        sourceY = y,
        oX = oX,
        oY = oY,
        eX = eX,
        eY = eY,
        wFunc = wFunc,
        cFunc = cFunc,
        ttl = ttl,
        initialTtl = ttl,
    }, Beam)
end
setmetatable(Beam, {
    __call = function(_, ...) return newBeam(...) end
})
function Beam:update(dt)
    self.ttl = self.ttl  - 1
    if self.ttl <= 0 then
        self.shouldRemove = true
    end

    if not self.source.body:isDestroyed() then
        self.sourceX, self.sourceY = self.source:pos()
    end
end
function Beam:draw()
    local portion = self.ttl / self.initialTtl
    love.graphics.setLineWidth(self.wFunc(portion))
    love.graphics.setColor(self.cFunc(portion))

    local cx, cy = camera:pos()
    love.graphics.line(
        self.sourceX + self.oX - cx,
        self.sourceY + self.oY - cy,
        self.eX - cx,
        self.eY - cy)
end
function Beam:getZ() return 100000000 end
