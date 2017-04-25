AnimSprite = {}
AnimSprite.__index = AnimSprite
local function newAnimSprite(img, tw, th, fpt, loop, x, y)
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
        loop = (loop == nil and true) or loop,
        fpt = fpt or 3,
        time = 0
    }, AnimSprite)
end
setmetatable(AnimSprite, {
    __call = function(_, ...) return newAnimSprite(...) end
})
function AnimSprite:update(dt)
    if not self.loop and self.tx + 1 == self.txs or self.fpt == 0 then
        return
    end
    self.time = self.time + 1;
    while (self.time > self.fpt) do
        self.time = self.time - self.fpt
        self.tx = (self.tx + 1) % self.txs
    end
end
function AnimSprite:draw(x, y, col)
    love.graphics.setColor(col or white)
    love.graphics.draw(self.img,
        self.quads[self.tx][self.ty],
        x, y,
        0,
        (self.flipX and -1) or 1, (self.flipY and -1) or 1,
        self.x, self.y)
end
function AnimSprite:drawSpecific(x, y, tx, ty, fx, fy, col)
    love.graphics.setColor(col or white)
    love.graphics.draw(self.img,
        self.quads[tx][ty],
        x, y,
        0,
        (fx and -1) or 1, (fy and -1) or 1,
        self.x, self.y)
end
