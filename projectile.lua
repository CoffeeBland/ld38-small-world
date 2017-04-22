Projectile = {}
Projectile.__index = Projectile
local function newProjectile(sprite, x, y, shape, ttl)
    local body = love.physics.newBody(world, x, y, "kinematic")
    body:setFixedRotation(true)
    body:setLinearDamping(5)
    local fixture = love.physics.newFixture(body, shape, 1)
    return setmetatable({
        sprite = sprite,
        body = body,
        shape = shape,
        fixture = fixture,
        ttl = ttl,
    }, Projectile)
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
local bulletSprite = AnimSprite(bulletImg, 8, 8)
function Bullet(x, y, dirX, dirY, initVelX, initVelY)
    local shape = love.physics.newCircleShape(8/PHYS_UNIT)
    p = Projectile(bulletSprite, x, y, shape, 5 * 60)
    p.body:setLinearVelocity((dirX * 480) + initVelX, (dirY * 480) + initVelY)
    p.fixture:setFilterData(CAT_FRIENDLY, CAT_ENEMY, GRP_PROJ)
    return p
end

local sparkleImg = love.graphics.newImage("imgs/sparkle.png")
function Sparkle(x, y)
    local shape = love.physics.newCircleShape(8/PHYS_UNIT)
    return Projectile(AnimSprite(sparkleImg, 16, 16, 8), x, y, shape, 32)
end

local miniSparkImg = love.graphics.newImage("imgs/mini-spark.png")
function MiniSpark(x, y)
    local shape = love.physics.newCircleShape(4/PHYS_UNIT)
    return Projectile(AnimSprite(miniSparkImg, 8, 8, 2), x, y, shape, 8)
end