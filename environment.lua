require('sprite')

local treeImg = love.graphics.newImage("imgs/tree.png")
local treeSprite = AnimSprite(treeImg, 64, 128, 0, false, 32, 122)
local treeColor = {
    -- trunk
    { 77/255, 51/255, 71/255 },
    { 120/255, 80/255, 60/255 },
    -- leaves
    { 150/255, 210/255, 110/255, 0 }
}
Tree = {}
Tree.__index = Tree
local function newTree(x, y)
    local obj = setmetatable({
        x = x,
        y = y,
        flip = rand() < 0.5,
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
    return self.x, self.y
end
function Tree:getZ()
    return self.y
end
function Tree:update(dt)
    local inside = crustal:inside(self:pos())
    self.leavesAlpha = clamp(self.leavesAlpha + (inside and 5 or -10), 0, 255)
    self.color = inside and treeColor[2] or treeColor[1]
end
function Tree:draw(camera)
    local cx, cy = camera:pos()
    local x, y = self:pos()
    treeSprite:drawSpecific(x - cx, y - cy, 0, 0, self.flip, false, self.color)
    if self.leavesAlpha > 0 then
        treeColor[3][4] = self.leavesAlpha/255
        treeSprite:drawSpecific(x - cx, y - cy, 1, 0, self.flip, false, treeColor[3])
    end
end
function Tree:create()
    local body = love.physics.newBody(world, self.x, self.y, "static")
    local shape = love.physics.newCircleShape(8)
    local fixture = love.physics.newFixture(body, shape, 1)

    self.body = body
    self.shape = shape
    self.fixture = fixture
end
function Tree:destroy()
    removeBody(self)
    self.body = nil
    self.shape = nil
    self.fixture = nil
end

Chunk = {}
Chunk.__index = Chunk
local propsImg = love.graphics.newImage("imgs/props.png")
local propsSprite = AnimSprite(propsImg, 16, 16)
local propsColors = {
    -- Grass
    { 82/255, 230/255, 118/255},
    { 77/255, 51/255, 71/255 },
    -- Rock
    { 240/255, 220/255, 230/255 },
    { 77/255, 51/255, 71/255 },
}
local function newChunk(x, y, w, h)
    local props = {}
    for i = 1, rand(80) do
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
    local actors = {}
    for i = 1, pow(rand(), 2) * 20 do
        local tree = Tree(x + rand() * w, y + rand() * h)
        table.insert(actors, tree)
    end
    return setmetatable({
      x = x,
      y = y,
      props = props,
      actors = actors,
      loaded = false,
    }, Chunk)
end
setmetatable(Chunk, {
    __call = function(_, ...) return newChunk(...) end
})
function Chunk:load()
    self.loaded = true
    for _, a in pairs(self.actors) do
        a.shouldRemove = false
        if not a.body then
            a:create()
            addActor(a)
        end
    end
end
function Chunk:unload()
    self.loaded = false
    for _, a in pairs(self.actors) do
        a.shouldRemove = true
    end
end
function Chunk:update(dt) end
function Chunk:pos()
    return self.x, self.y
end
function Chunk:draw(camera)
    local cx, cy = camera:pos()
    for i, p in pairs(self.props) do
        p.sprite:drawSpecific(p.x - cx, p.y - cy, p.tx, p.ty, false, false,
            (crustal:inside(p.x, p.y) and p.good) or p.evil)
    end
end

Environment = {}
Environment.__index = Environment
local function newEnvironment(chunkSize)
    return setmetatable({
        chunkSize = chunkSize,
        chunks = {},

        ttSpawnBasic = 60,
        spawnRateBasic = 1/3,

        ttSpawnBlob = 360,
        spawnRateBlob = 1/6,

        ttSpawnHealth = 60*60,
        spawnRateHealth = 1/60,
        ttSpawnSpecialWave = 60*30,
        spawnRateSpecialWave = 1/30,
    }, Environment)
end
setmetatable(Environment, {
    __call = function(_, ...) return newEnvironment(...) end
})
function Environment:draw(camera)
    local mw, Mw, mh, Mh = camera:bounds()
    local cs = self.chunkSize
    local mpX = floor(mw / cs)
    local mpY = floor(mh / cs)
    local MpX = ceil(Mw / cs)
    local MpY = ceil(Mh / cs)
    for i = mpX - 1, MpX + 1 do
        local insideX = i >= mpX and i <= MpX
        if not self.chunks[i] then
            self.chunks[i] = {}
        end
        for j = mpY - 1, MpY + 1 do
            local insideY = j >= mpY and j <= MpY
            local chunk = self.chunks[i][j]
            if insideX and insideY then
                if not chunk then
                    chunk = Chunk(i * cs, j * cs, cs, cs)
                    self.chunks[i][j] = chunk
                end
                if not chunk.loaded then chunk:load() end
                chunk:draw(camera)
            else
                if chunk and chunk.loaded then chunk:unload() end
            end
        end
    end
end
function Environment:update(dt)
    self.ttSpawnBasic = self.ttSpawnBasic - 1
    self.ttSpawnBlob = self.ttSpawnBlob - 1
    self.ttSpawnHealth = self.ttSpawnHealth - 1
    self.ttSpawnSpecialWave = self.ttSpawnSpecialWave - 1

    if self.ttSpawnBasic <= 0 then
        local r = rand(100) + 600
        local a = rand() * 2 * pi
        addActor(EnemyBasic(camera.x + r*cos(a), camera.y + r*sin(a)))
        self.ttSpawnBasic = 60/self.spawnRateBasic
    end

    if self.ttSpawnBlob <= 0 then
        local radius = rand(100) + 600
        local angle = rand() * 2 * pi
        local x = camera.x + radius*cos(angle)
        local y = camera.y + radius*sin(angle)
        addActor(EnemyBlob(x, y))
        self.ttSpawnBlob = 60/self.spawnRateBlob
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

    self.spawnRateBasic = min(self.spawnRateBasic + 0.0004, 6) -- Max 6 basic per second
    self.spawnRateBlob = min(self.spawnRateBlob + 0.0001, 3) -- Max 3 blob per second
    self.spawnRateHealth = min(self.spawnRateHealth + 0.00005, 1/20) -- Max 1 health per 20 sec
    self.spawnRateSpecialWave = min(self.spawnRateSpecialWave + 0.0001, 1/15) -- Max 1 special wave per 15 sec
end
