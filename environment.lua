require('sprite')

local treeImg = love.graphics.newImage("imgs/tree.png")
local treeSprite = AnimSprite(treeImg, 64, 128, 0, false, 32, 122)
local treeColor = {
    -- trunk
    { 77, 51, 71 },
    { 120, 80, 60 },
    -- leaves
    { 150, 210, 110, 0 }
}
Tree = {}
Tree.__index = Tree
local function newTree(x, y)
    local body = love.physics.newBody(world, x, y, "static")
    local shape = love.physics.newCircleShape(8)
    local fixture = love.physics.newFixture(body, shape, 1)
    local obj = setmetatable({
        x = 0,
        y = 0,
        body = body,
        shape = shape,
        fixture = fixture,
        color = treeColor[1],
        leavesAlpha = 0,
    }, Tree)
    local inside = crustal:inside(obj:pos())
    obj.leavesAlpha = inside and 255 or 0
    obj.color = inside and treeColor[2] or treeColor[1]
    return obj
end
setmetatable(Tree, {
    __call = function(_, ...) return newTree(...) end
})
function Tree:pos()
    return self.body:getX(), self.body:getY()
end
function Tree:getZ()
    return self.body:getY()
end
function Tree:update(dt)
    local inside = crustal:inside(self:pos())
    self.leavesAlpha = clamp(self.leavesAlpha + (inside and 5 or -10), 0, 255)
    self.color = inside and treeColor[2] or treeColor[1]
end
function Tree:draw(camera)
    local cx, cy = camera:pos()
    local x, y = self:pos()
    love.graphics.setColor(self.color)
    treeSprite:drawSpecific(x - cx, y - cy, 0, 0)
    if self.leavesAlpha > 0 then
        treeColor[3][4] = self.leavesAlpha
        love.graphics.setColor(treeColor[3])
        treeSprite:drawSpecific(x - cx, y - cy, 1, 0)
    end
end
function Tree:destroy()
    removeBody(self)
end

Chunk = {}
Chunk.__index = Chunk
local propsImg = love.graphics.newImage("imgs/props.png")
local propsSprite = AnimSprite(propsImg, 16, 16)
local propsColors = {
    -- Grass
    { 82, 230, 118},
    { 77, 51, 71 },
    -- Rock
    { 240, 220, 230 },
    { 77, 51, 71 },
}
local function newChunk(x, y, w, h)
    local props = {}
    for i = 0, rand(20) do
        local ty
        if rand() < 0.75 then
            ty = 0
        else
            ty = 1
        end
        props[i] = {
            x = x + rand() * w,
            y = y + rand() * h,
            tx = rand(3) - 1,
            ty = ty,
            good = propsColors[ty * 2 + 1],
            evil = propsColors[ty * 2 + 2],
            sprite = propsSprite,
        }
    end
    addActor(Tree(x + rand() * w, y + rand() * h))
    return setmetatable({
      x = x,
      y = y,
      props = props
    }, Chunk)
end
setmetatable(Chunk, {
    __call = function(_, ...) return newChunk(...) end
})
function Chunk:update(dt) end
function Chunk:pos()
    return self.x, self.y
end
function Chunk:draw(camera)
    local cx, cy = camera:pos()
    for i, p in pairs(self.props) do
        love.graphics.setColor((crustal:inside(p.x, p.y) and p.good) or p.evil)
        p.sprite:drawSpecific(p.x - cx, p.y - cy, p.tx, p.ty)
    end
end

Environment = {}
Environment.__index = Environment
local function newEnvironment(chunkSize)
    return setmetatable({
        chunkSize = chunkSize,
        chunks = {},

        ttSpawnBasic = 1,
        spawnRateBasic = 1/3,
        ttSpawnHealth = 60*10,
        spawnRateHealth = 1/10,
        ttSpawnSpecialWave = 60*24,
        spawnRateSpecialWave = 1/18,
    }, Environment)
end
setmetatable(Environment, {
    __call = function(_, ...) return newEnvironment(...) end
})
function Environment:draw(camera)
    local mw, Mw, mh, Mh = camera:bounds()
    local cs = self.chunkSize
    mpX = floor(mw / cs)
    mpY = floor(mh / cs)
    MpX = ceil(Mw / cs)
    MpY = ceil(Mh / cs)
    for i = mpX, MpX do
        if not self.chunks[i] then
            self.chunks[i] = {}
        end
        for j = mpY, MpY do
            local chunk = self.chunks[i][j]
            if not chunk then
                chunk = Chunk(i * cs, j * cs, cs, cs)
                self.chunks[i][j] = chunk
            end
            chunk:draw(camera)
        end
    end
end
function Environment:update(dt)
    self.ttSpawnBasic = self.ttSpawnBasic - 1
    self.ttSpawnHealth = self.ttSpawnHealth - 1
    self.ttSpawnSpecialWave = self.ttSpawnSpecialWave - 1

    if self.ttSpawnBasic <= 0 then
        local r = rand(100) + 600
        local a = rand() * 2 * pi
        addActor(EnemyBasic(camera.x + r*cos(a), camera.y + r*sin(a)))
        self.ttSpawnBasic = 60/self.spawnRateBasic
    end

    if self.ttSpawnHealth <= 0 then
        local r = rand(100) + 75
        local a = rand() * 2 * pi
        addActor(ItemHealth(camera.x + r*cos(a), camera.y + r*sin(a)))
        self.ttSpawnHealth = 60/self.spawnRateHealth
    end

    if self.ttSpawnSpecialWave <= 0 then
        local r = rand(100) + 100
        local a = rand() * 2 * pi
        addActor(ItemSpecialWave(camera.x + r*cos(a), camera.y + r*sin(a)))
        self.ttSpawnSpecialWave = 60/self.spawnRateSpecialWave
    end

    self.spawnRateBasic = min(self.spawnRateBasic + 0.0004, 3) -- Max 3 basic per second
    self.spawnRateHealth = min(self.spawnRateBasic + 0.0002, 1/5) -- Max 1 health per 5 sec
    self.spawnRateSpecialWave = min(self.spawnRateSpecialWave + 0.0002, 1/5) -- Max 1 special wave per 5 sec
end
