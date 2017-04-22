require('sprite')

Chunk = {}
Chunk.__index = Chunk
local propsImg = love.graphics.newImage("imgs/props.png")
local propsSprite = AnimSprite(propsImg, 16, 16)
local props2Img = love.graphics.newImage("imgs/props-2.png")
local props2Sprite = AnimSprite(props2Img, 32, 32)
local function newChunk(x, y, w, h)
    local props = {}
    local colors = {
        -- Grass
        { 82, 230, 118},
        { 77, 51, 71 },
        -- Rock
        { 240, 220, 230 },
        { 77, 51, 71 },
    }
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
            good = colors[ty * 2 + 1],
            evil = colors[ty * 2 + 2],
            sprite = propsSprite,
        }
    end
    return setmetatable({
      x = x,
      y = y,
      props = props
    }, Chunk)
end
setmetatable(Chunk, {
    __call = function(_, ...) return newChunk(...) end
})
function Chunk:update(dt)
end
function Chunk:pos()
    return self.x, self.y
end
function Chunk:draw(camera)
    local cx, cy = camera:pos()
    for i, p in pairs(self.props) do
        love.graphics.setColor((crustcle:inside(p.x, p.y) and p.good) or p.evil)
        p.sprite.tx = p.tx
        p.sprite.ty = p.ty
        p.sprite:draw(p.x - cx, p.y - cy)
        love.graphics.setColor(255, 255, 255)
    end
end

Environment = {}
Environment.__index = Environment
local function newEnvironment(chunkSize)
    return setmetatable({
        chunkSize = chunkSize,
        chunks = {}
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
end
function Environment:getZ()
    return 0
end