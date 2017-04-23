Projectile = {}
Projectile.__index = Projectile
local function newProjectile(sprite, x, y, shape, ttl)
    local body = love.physics.newBody(world, x, y, "kinematic")
    body:setFixedRotation(true)
    local obj = setmetatable({
        sprite = sprite,
        body = body,
        shape = shape,
        ttl = ttl,
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
    self.sprite:draw(self.body:getX() - cx, self.body:getY() - cy)
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
function Bullet(x, y, dirX, dirY, initVelX, initVelY)
    local shape = love.physics.newCircleShape(8)
    p = Projectile(AnimSprite(bulletImg, 12, 12, 2), x, y, shape, 5 * 60)
    p.body:setLinearVelocity((dirX * 480) + initVelX, (dirY * 480) + initVelY)
    --p.fixture:setFilterData(CAT_FRIENDLY, 0, 0)
    p.fixture:setSensor(true)

    p.collide = function(self, other)
        if getmetatable(other) == Enemy then
            self.shouldRemove = true
            other.shouldRemove = true
        end
    end
    p.destroy = function(self)
        addActor(BlueBoom(self:pos()))
        removeBody(self)
    end

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

local blueBoomImg = love.graphics.newImage("imgs/blue-boom.png")
function BlueBoom(x, y)
    return Projectile(AnimSprite(blueBoomImg, 24, 24, 6), x, y, nil, 18)
end
