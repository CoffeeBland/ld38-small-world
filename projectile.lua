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
        startT = love.timer.getTime(),
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
    local t = love.timer.getTime()
    if (t - self.startT - self.ttl) > 0 then
        self.shouldRemove = true
    end
end
function Projectile:destroy()
    removeBody(self)
end


local bulletImg = love.graphics.newImage("imgs/bullet.png")
local bulletSprite = AnimSprite(bulletImg, 8, 8)
Bullet = function(x, y, dirX, dirY, initVelX, initVelY)
    local shape = love.physics.newCircleShape(0.16666)
    p = Projectile(bulletSprite, x, y, shape, 5)
    p.body:setLinearVelocity((dirX * 480) + initVelX, (dirY * 480) + initVelY)
    p.fixture:setFilterData(CAT_FRIENDLY, CAT_ENEMY, GRP_PROJ)
    return p
end

local sparkleImg = love.graphics.newImage("imgs/sparkle.png")
local sparkleSprite = AnimSprite(sparkleImg, 8, 8)
Sparkle = function(x, y, ttl)
    local shape = love.physics.newCircleShape(0.16666)
    return Projectile(sparkleSprite, x, y, shape, ttl)
end