Player = {}
Player.__index = Player
local function newPlayer(sprite, controls)
    local body = love.physics.newBody(world, 0, 0, "dynamic")
    local shape = love.physics.newCircleShape(12)
    local fixture = love.physics.newFixture(body, shape, 1)
    body:setFixedRotation(true)
    body:setLinearDamping(10)
    fixture:setCategory(CAT_FRIENDLY)

    return setmetatable({
        sprite = sprite,
        controls = controls,
        body = body,
        shape = shape,
        fixture = fixture,
        speed = 10,
        movementX = 0,
        movementY = 0,
        lastMovementX = 1,
        lastMovementY = 0,
        keys = {},
        sinceShot = 0,
    }, Player)
end
setmetatable(Player, {
    __call = function(_, ...) return newPlayer(...) end
})
function Player:hold_up(dt)
    self.movementY = self.movementY - 1
end
function Player:hold_down(dt)
    self.movementY = self.movementY + 1
end
function Player:hold_left(dt)
    self.movementX = self.movementX - 1
end
function Player:hold_right(dt)
    self.movementX = self.movementX + 1
end
function Player:begin_shoot(dt)
    if self.shooting then
        return
    end
    local velX, velY = self.body:getLinearVelocity()
    addActor(Bullet(
        self.body:getX(), self.body:getY(),
        self.lastMovementX, self.lastMovementY,
        velX, velY
    ))
    self.sinceShot = 0
end
function Player:update(dt)
    self.movementX = 0
    self.movementY = 0
    self.sinceShot = self.sinceShot + 1
    for k, c in pairs(self.controls) do
        if love.keyboard.isDown(k) then
            if not self.keys[k] then
                (self['begin_' .. c] or noop)(self, dt)
                self.keys[k] = true
            end
            (self['hold_' .. c] or noop)(self, dt)
        else
            if self.keys[k] then
                (self['end_' .. c] or noop)(self, dt)
                self.keys[k] = false
            end
        end
    end
    local len = dst(self.movementX, self.movementY)
    if (len ~= 0) then
        self.movementX = self.movementX / len
        self.movementY = self.movementY / len
        self.body:applyLinearImpulse(self.movementX * self.speed, self.movementY * self.speed)
        self.lastMovementX = self.movementX
        self.lastMovementY = self.movementY
    end
    local mx, my = self.body:getLinearVelocity()
    self.sprite:movement(self.movementX, self.movementY, mx, my, self.sinceShot)
    self.sprite:update(dt)
end
function Player:pos()
    return self.body:getX(), self.body:getY()
end
function Player:getZ()
    return self.body:getY()
end
function Player:draw(camera)
    local cx, cy = camera:pos()
    local x, y = self:pos()
    self.sprite:draw(x - cx, y - cy)
end


Enemy = {}
Enemy.__index = Enemy
local function newEnemy(type, x, y)
    local sprite = AnimSprite(enemyBasicImg, 48, 48, 4, true, 24, 32)
    sprite.movement = wallabiMovement
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(12)
    local fixture = love.physics.newFixture(body, shape, 1)
    body:setFixedRotation(true)
    body:setLinearDamping(10)
    fixture:setCategory(CAT_ENEMY)

    obj = setmetatable({
        type = type,
        sprite = sprite,
        body = body,
        shape = shape,
        fixture = fixture,
    }, Enemy)
    fixture:setUserData(obj)
    return obj
end
setmetatable(Enemy, {
    __call = function(_, ...) return newEnemy(...) end
})
function Enemy:pos()
    return self.body:getX(), self.body:getY()
end
function Enemy:draw(camera)
    local cx, cy = camera:pos()
    local x, y = self:pos()
    self.sprite:draw(x - cx, y - cy)
end
function Enemy:getZ()
    return self.body:getY()
end
function Enemy:update(dt)
    -- Approch crustal
    local crustalX, crustalY = crustal:pos()
    local x, y = self:pos()
    velX = ((abs(x - crustalX) < 16 and 0) or (x < crustalX) and 4 or -4)
    velY = ((abs(y - crustalY) < 16 and 0) or (y < crustalY) and 4 or -4)
    self.body:applyLinearImpulse(velX, velY)

    self.sprite:movement(velX, velY, self.body:getLinearVelocity())
    self.sprite:update(dt)
end


EnemyBasic = function(x, y)
    return Enemy("basic", x, y)
end
