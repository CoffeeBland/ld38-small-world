require('sprite')

Chunk = {}
Chunk.__index = Chunk
local propsImg = love.graphics.newImage("imgs/props.png")
local propsSprite = AnimSprite(propsImg, 16, 16)
local function newChunk(x, y, w, h)
    local props = {}
    for i = 0, rand(20) do
        props[i] = {
            x = rand() * w,
            y = rand() * h,
            tx = rand(3) - 1,
            ty = rand(2) - 1
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
    local x, y = self:pos()
    for i, p in pairs(self.props) do
        propsSprite.tx = p.tx
        propsSprite.ty = p.ty
        propsSprite:draw(x + p.x - cx, y + p.y - cy)
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