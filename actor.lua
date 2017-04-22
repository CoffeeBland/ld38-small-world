AnimSprite = {}
AnimSprite.__index = AnimSprite
function AnimSprite:update(dt)
    if (not self.loop and self.tx + 1 == self.txs) then
        return
    end
    self.time = self.time + 1;
    while (self.time > self.fpt) do
        self.time = self.time - self.fpt
        self.tx = (self.tx + 1) % self.txs
    end
end
function AnimSprite:quad()
    return self.quads[self.tx][self.ty]
end
function AnimSprite:draw(x, y)
    love.graphics.draw(self.img, self:quad(), x, y,
        0, (self.flipX and -1) or 1, (self.flipY and -1) or 1, self.x, self.y)
end
local function newAnimSprite(name, tw, th, fpt, loop, x, y)
    local img = love.graphics.newImage("imgs/" .. name)
    local w, h = img:getDimensions()
    local txs = w / tw
    local tys = h / th
    local quads = {}
    for i = 0, txs do
        quads[i] = {}
        for j = 0, tys do
            quads[i][j] = love.graphics.newQuad(i * tw, j * th, tw, th, w, h)
        end
    end
    return setmetatable({
        x = x or 0, y = y or 0,
        tx = 0, ty = 0,
        txs = txs, tys = tys,
        tw = tw, th = th,
        quads = quads,
        flipX = false, flipY = false,
        img = img,
        loop = loop or true,
        fpt = fpt or 3,
        time = 0
    }, AnimSprite)
end
setmetatable(AnimSprite, {
    __call = function(_, ...) return newAnimSprite(...) end
})

Player = {}
Player.__index = Player
local function newPlayer(sprite, controls, body)
    return setmetatable({
        sprite = sprite,
        controls = controls,
        body = body,
        speed = 0.1
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
function Player:update(dt)
    self.movementX = 0
    self.movementY = 0
    for k, c in pairs(self.controls) do
        if love.keyboard.isDown(k) then
            self[c](self, dt)
        end
    end
    local len = math.sqrt(math.pow(self.movementX, 2) + math.pow(self.movementY, 2))
    if (len ~= 0) then
        self.movementX = self.movementX / len
        self.movementY = self.movementY / len
        self.body:applyLinearImpulse(
            self.movementX * self.speed, self.movementY * self.speed)

        self.sprite.ty =
            (self.movementX ~= 0 and 2) or 0
        self.sprite.flipX = self.movementX < 0
        self.sprite.flipY = self.movementY < 0
    end
    self.sprite:update(dt)
end
function Player:draw()
    self.sprite:draw(self.body:getX(), self.body:getY())
end
setmetatable(Player, {
    __call = function(_, ...) return newPlayer(...) end
})