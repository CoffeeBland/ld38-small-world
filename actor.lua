Actor = {}
Actor.__index = Actor
local function newActor(sprite, radius, speed, x, y)
    local body = love.physics.newBody(world, x or 0, y or 0, "dynamic")
    local shape = love.physics.newCircleShape(radius)
    local fixture = love.physics.newFixture(body, shape, 1)
    body:setFixedRotation(true)
    body:setLinearDamping(10)

    local obj = setmetatable({
        sprite = sprite,
        body = body,
        shape = shape,
        fixture = fixture,
        speed = speed,
        movementX = 0,
        movementY = 0,
    }, Actor)
    obj.fixture:setUserData(obj)
    return obj
end
setmetatable(Actor, {
    __call = function(_, ...) return newActor(...) end
})
function Actor:pos()
    return self.body:getX(), self.body:getY()
end
function Actor:pos()
    return self.body:getX(), self.body:getY()
end
function Actor:getZ()
    return self.body:getY()
end
function Actor:draw(camera)
    local cx, cy = camera:pos()
    local x, y = self:pos()
    self.sprite:draw(x - cx, y - cy)
end
function Actor:update(dt)
    local len = dst(self.movementX, self.movementY)
    if len ~= 0 then
        self.movementX = self.movementX / len
        self.movementY = self.movementY / len
        self.body:applyLinearImpulse(self.movementX * self.speed, self.movementY * self.speed)
    end

    local mx, my = self.body:getLinearVelocity()
    self.sprite:movement(self.movementX, self.movementY, mx, my, self.sinceShot)
    self.sprite:update(dt)
end
function Actor:destroy()
    removeBody(self)
end

Player = {}
Player.__index = Player
local function newPlayer(sprite, controls, x, y)
    local obj = Actor(sprite, 12, 10, x, y)
    obj.fixture:setCategory(CAT_FRIENDLY)

    obj.controls = controls
    obj.speed = 10
    obj.movementX = 0
    obj.movementY = 0
    obj.keys = {}
    obj.sinceShot = 0
    obj.outsideCrustalFor = 0
    obj.specialWaveReady = false
    return setmetatable(obj, Player)
end
setmetatable(Player, {
    __call = function(_, ...) return newPlayer(...) end,
    __index = Actor
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
function Player:begin_special(dt)
    if self.specialWaveReady then
        self.specialWaveReady = false
        local x, y = self:pos()
        for i = 1, 64 do
            local a = i/64 * 2 * pi
            addActor(Bullet(x, y, cos(a), sin(a)))
        end
    end
end
function Player:begin_shoot(dt, k)
    if self.sinceShot == 0 then
        return
    end
    self.sinceShot = 0

    local fx, fy = 0, 0
    if k == "w" then fy = -1 end
    if k == "a" then fx = -1 end
    if k == "s" then fy = 1 end
    if k == "d" then fx = 1 end

    addActor(Bullet(self.body:getX(), self.body:getY(), fx, fy))
end
function Player:update(dt)
    self.sinceShot = self.sinceShot + 1

    self.movementX = 0
    self.movementY = 0
    for k, c in pairs(self.controls) do
        if love.keyboard.isDown(k) then
            if not self.keys[k] then
                (self['begin_' .. c] or noop)(self, dt, k)
                self.keys[k] = true
            end
            (self['hold_' .. c] or noop)(self, dt, k)
        else
            if self.keys[k] then
                (self['end_' .. c] or noop)(self, dt, k)
                self.keys[k] = false
            end
        end
    end

    Actor.update(self, dt)

    local x, y = self:pos()
    if not crustal:inside(x, y) then
        self.outsideCrustalFor = self.outsideCrustalFor + 1
        shake(8, 8)
        -- minus 3 life per s. accelerating up to 60 per s. after 10 s.
        life = life - (self.outsideCrustalFor * (0.95 / 600) + 0.05)
    else
        self.outsideCrustalFor = 0
    end
end

Enemy = {}
Enemy.__index = Enemy
local function newEnemy(type, x, y)
    local obj = Actor(type.sprite(), type.radius, type.speed, x, y)
    obj.fixture:setCategory(CAT_ENEMY)
    obj.sprite.movement = wallabiMovement
    obj.type = type
    return setmetatable(obj, Enemy)
end
setmetatable(Enemy, {
    __call = function(_, ...) return newEnemy(...) end,
    __index = Actor
})
function Enemy:update(dt)
    -- Approach crustal
    local crustalX, crustalY = crustal:pos()
    local x, y = self:pos()
    self.movementX = crustalX - x
    self.movementY = crustalY - y
    Actor.update(self, dt)
end
function Enemy:collide(other)
    if not self.shouldRemove and getmetatable(other) == Crustal then
        life = life - 3
        self.shouldRemove = true
    end
end
function Enemy:destroy()
    shake(6, 8)
    addActor(BloodSplatter(self:pos()))
    Actor.destroy(self)
end

local basic = {
    sprite = function()
        return AnimSprite(enemyBasicImg, 48, 48, 4, true, 24, 32)
    end,
    radius = 12,
    speed = 6,
}
EnemyBasic = function(x, y)
    return Enemy(basic, x, y)
end
