Projectile = {}
Projectile.__index = Projectile
local function newProjectile(sprite, x, y, shape)
    local body = love.physics.newBody(world, x, y, "kinematic")
    body:setFixedRotation(true)
    body:setLinearDamping(5)
    local fixture = love.physics.newFixture(body, shape, 1)
    return setmetatable({
        sprite = sprite,
        body = body,
        shape = shape,
        fixture = fixture,
    }, Projectile)
end
function Projectile:draw(camera)
    local cx, cy = camera:pos()
    self.sprite:draw(self.body:getX() - cx, self.body:getY() - cy)
end
function Projectile:getZ()
    return self.body:getY()
end
function Projectile:update(dt)
end
setmetatable(Projectile, {
    __call = function(_, ...) return newProjectile(...) end
})


local bulletSprite = AnimSprite("bullet.png", 8, 8)

Bullet = function(x, y, dirX, dirY, initVelX, initVelY)
    local shape = love.physics.newCircleShape(0.16666)
    p =  Projectile(bulletSprite, x, y, shape)
    p.body:setLinearVelocity((dirX * 480) + initVelX, (dirY * 480) + initVelY)
    p.fixture:setFilterData(CAT_FRIENDLY, CAT_ENEMY, GRP_PROJ)
    return p
end
