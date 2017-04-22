function dst(x, y)
    return math.sqrt(math.pow(x, 2) + math.pow(y, 2))
end

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
    love.graphics.draw(self.img, self:quad(),
        x, y,
        0,
        (self.flipX and -1) or 1, (self.flipY and -1) or 1,
        self.x, self.y)
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
        x = x or tw/2, y = y or th/2,
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
