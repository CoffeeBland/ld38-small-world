Player = {}
Player.__index = Player
local function newPlayer(sprite, controls)
    local body = love.physics.newBody(world, 0, 0, "dynamic")
    body:setFixedRotation(true)
    body:setLinearDamping(10)
    local shape = love.physics.newCircleShape(1)
    local fixture = love.physics.newFixture(body, shape, 1)

    return setmetatable({
        sprite = sprite,
        controls = controls,
        body = body,
        shape = shape,
        fixture = fixture,
        speed = 0.1,
        ty = 0,
        movementX = 0,
        movementY = 0,
        lastMovementX = 1,
        lastMovementY = 0,
    }, Player)
end
function Player:up(dt)
    self.movementY = self.movementY - 1
end
function Player:down(dt)
    self.movementY = self.movementY + 1
end
function Player:left(dt)
    self.movementX = self.movementX - 1
end
function Player:right(dt)
    self.movementX = self.movementX + 1
end
function Player:shoot(dt)
    addProjectile(Bullet(self.x, self.y, self.lastMovementX, self.lastMovementY))
end
function Player:update(dt)
    self.lastMovementX = self.movementX > 0 and self.movementX or self.lastMovementX
    self.lastMovementY = self.movementY > 0 and self.movementY or self.lastMovementY
    self.movementX = 0
    self.movementY = 0
    for k, c in pairs(self.controls) do
        if love.keyboard.isDown(k) then
            self[c](self, dt)
        end
    end
    local len = dst(self.movementX, self.movementY)
    if (len ~= 0) then
        self.movementX = self.movementX / len
        self.movementY = self.movementY / len
        self.body:applyLinearImpulse(self.movementX * self.speed, self.movementY * self.speed)

        self.ty = (self.movementX ~= 0 and 3) or 0
        self.sprite.flipX = self.movementX < 0
        self.sprite.flipY = self.movementX == 0 and self.movementY < 0
        self.sprite.ty = self.ty
    else
        self.sprite.ty = self.ty + 1
    end
    self.sprite.fpt = 10 / (dst(self.body:getLinearVelocity())/600 + 1)
    self.sprite:update(dt)
end
function Player:pos()
    return self.body:getX(), self.body:getY()
end
function Player:draw(camera)
    local cx, cy = camera:pos()
    local x, y = self:pos()
    self.sprite:draw(x - cx, y - cy)
end
setmetatable(Player, {
    __call = function(_, ...) return newPlayer(...) end
})
