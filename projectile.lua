Projectile = {}
Projectile.__index = Projectile
local function newProjectile(sprite, x, y, shape)
    local body = love.physics.newBody(world, x, y, "dynamic")
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
function Projectile:update(dt)
end
setmetatable(Projectile, {
    __call = function(_, ...) return newProjectile(...) end
})


local bulletSprite = AnimSprite("bullet.png", 8, 8)

Bullet = function(x, y, dirX, dirY)
    local shape = love.physics.newCircleShape(0.16666)
    p =  Projectile(bulletSprite, x, y, shape)
    p.body:applyLinearImpulse(dirX * 10, dirY * 10)
    return p
end
