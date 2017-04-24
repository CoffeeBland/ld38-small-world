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
        damaged = 0,
        lastMovLen = 0,
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
    if self.damaged > 0 then
        self.sprite:draw(x - cx, y - cy, magenta)
    else
        self.sprite:draw(x - cx, y - cy)
    end
end
function Actor:update(dt)
    if self.damaged > 0 then
        self.damaged = self.damaged - 1
    end

    local len = dst(self.movementX, self.movementY)
    if len ~= 0 then
        self.movementX = self.movementX / len
        self.movementY = self.movementY / len
        self.body:applyLinearImpulse(self.movementX * self.speed, self.movementY * self.speed)
        if self.lastMovLen < 0.1 then
            self.sprite.tx = 0
            self.sprite.time = 0
        end
    end
    self.lastMovLen = len

    local mx, my = self.body:getLinearVelocity()
    self.sprite:movement(self, self.movementX, self.movementY, mx, my)
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
    if self.sinceShot >= 20 then
        self.sprite.tx = 0
        self.sprite.time = 0
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

    self.speed = self.sinceShot > 10 and 12 or 6
    Actor.update(self, dt)

    local x, y = self:pos()
    if not crustal:inside(x, y) then
        self.outsideCrustalFor = self.outsideCrustalFor + 1
        -- minus 3 life per s. accelerating up to 60 per s. after 10 s.
        damageTripod(self.outsideCrustalFor * (0.95 / 600) + 0.05)
    else
        self.outsideCrustalFor = 0
    end
end

Enemy = {}
Enemy.__index = Enemy
local function newEnemy(type, x, y)
    local obj = Actor(type.sprite(), type.radius, type.speed, x, y)
    obj.fixture:setCategory(CAT_ENEMY)
    obj.type = type
    setmetatable(obj, Enemy)
    ;(obj.type.init or noop)(obj, type, x, y)
    return obj
end
setmetatable(Enemy, {
    __call = function(_, ...) return newEnemy(...) end,
    __index = Actor
})
function Enemy:update(dt)
    (self.type.update or noop)(self, dt)
    Actor.update(self, dt)
end
function Enemy:collide(other)
    (self.type.collide or noop)(self, other)
end
function Enemy:hit(bullet)
    (self.type.hit or noop)(self, bullet)
end
function Enemy:destroy()
    (self.type.destroy or noop)(self)
    addActor(BloodSplatter(self:pos()))
    Actor.destroy(self)
end

basic = {
    img = love.graphics.newImage("imgs/enemy_basic.png"),
    sprite = function()
        local sprite = AnimSprite(basic.img, 48, 48, 4, true, 24, 32)
        sprite.movement = basic.spriteMovement
        return sprite
    end,
    spriteMovement = function(self, actor, movX, movY, speedX, speedY)
        if movX ~= 0 or movY ~= 0 then
            self.baseTy = (abs(movX) >= abs(movY) and 6) or (movY < 0 and 3) or 0
            self.flipX = movX < 0
        end
        local speed = dst(speedX, speedY)
        self.ty = (self.baseTy or 0) + ((speed > 0.1 and 0) or 1)
        self.fpt = 10 / (speed / 600 + 1)
    end,
    collide = function(self, other)
        if not self.shouldRemove and getmetatable(other) == Crustal then
            damageCrustal(5)
            self.shouldRemove = true
        end
    end,
    update = function(self, dt)
        local crustalX, crustalY = crustal:pos()
        local x, y = self:pos()
        self.movementX = crustalX - x
        self.movementY = crustalY - y
    end,
    hit = function(self, bullet)
        self.shouldRemove = true
        bullet.shouldRemove = true
    end,
    radius = 12,
    speed = 6,
}
EnemyBasic = function(x, y)
    return Enemy(basic, x, y)
end

blob = {
    img = love.graphics.newImage("imgs/blob.png"),
    sprite = function()
        local sprite = AnimSprite(blob.img, 64, 64, 4, true, 32, 52)
        sprite.movement = blob.spriteMovement
        return sprite
    end,
    spriteMovement = function(self, actor, movX, movY, speedX, speedY)
        if actor.attacking > 0 then
            if actor.attacking > 20 then
                self.tx = 0
            else
                self.tx = 1
            end
            self.fpt = 0
            self.ty = self.baseTy  + 2
        else
            return basic.spriteMovement(self, actor, movX, movY, speedX, speedY)
        end
    end,
    init = function(self, type, x, y)
        self.attacking = 0
        self.hitpoint = 4
    end,
    update = function(self, dt)
        local x, y = self:pos()
        local pX, pY = player:pos()
        if self.attacking <= 0 then
            local dst2P = dst(pX - x, pY - y)
            if dst2P < 196 then
                self.attacking = 60
                self.attackX = pX
                self.attackY = pY
                local ox, oy = self.type.beamOffset(self, x, y)
                self.beam = Beam(self, ox, oy, pX, pY, blob.preBeamWidth, blob.beamColor, 40)
                addActor(self.beam)
                self.movementX = 0
                self.movementY = 0
            else
                self.movementX = pX - x
                self.movementY = pY - y
            end
        else
            self.attacking = self.attacking - 1
            if self.attacking == 20 then
                local ox, oy = self.type.beamOffset(self, x, y)
                self.beam = Beam(self, ox, oy, self.attackX, self.attackY, blob.beamWidth, blob.beamColor, 20)
                self.beamExplosion = RedExplosion(self.attackX, self.attackY)
                addActor(self.beam)
                addActor(self.beamExplosion)
            end
        end
    end,
    hit = function(self, bullet)
        bullet.shouldRemove = true
        if self.shouldRemove then return end
        self.hitpoint = self.hitpoint - 1
        self.damaged = 8
        if self.hitpoint <= 0 then
            self.shouldRemove = true
        end
    end,
    destroy = function(self)
        if self.beam then
            self.beam.shouldRemove = true
        end
        if self.beamExplosion then
            self.beamExplosion.shouldRemove = true
        end
    end,
    radius = 22,
    speed = 8,
    beamOffset = function(self, x, y)
        return
            ((self.sprite.baseTy == 6 and 20) or 0) * (self.sprite.flipX and -1 or 1),
            (self.sprite.baseTy == 0 and -24) or (self.sprite.baseTy == 3 and -50) or -24
    end,
    preBeamWidth = function(a) return 1 end,
    beamWidth = function(a)
        return sin(a * pi) * (sin(a * 16 * pi) * 4 + 10)
    end,
    beamColor = function(a) return { 255, 0, 96 } end
}
EnemyBlob = function(x, y)
    return Enemy(blob, x, y)
end
