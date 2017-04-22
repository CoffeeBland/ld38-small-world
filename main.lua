crustal = love.graphics.newImage("imgs/crustal.png")

Cruspt = {}
Cruspt.__index = Cruspt
function Cruspt:update(dt)
    self.t = self.t + self.dt
    self.r = self.sR + math.sin(self.t) * self.rBounds
    self.a = self.sA + math.sin(self.t) * self.aBounds
end
local function newCruspt(r, rBounds, a, aBounds)
    local dt = (math.random() + 2) * 2 * math.pi / 360
    return setmetatable({
        t = math.random() * 2 * math.pi, dt = dt,
        sR = r, r = r,
        rBounds = rBounds,
        sA = a, a = a,
        aBounds = aBounds
    }, Cruspt)
end
setmetatable(Cruspt, {
    __call = function(_, ...) return newCruspt(...) end
})

Crustcle = {}
Crustcle.__index = Crustcle
function Crustcle:poly()
    local poly = {}
    for i = 1, #self.pts do
        local pt = self.pts[i]
        poly[i*2-1] = math.cos(pt.a) * pt.r  + self.x
        poly[i*2] = math.sin(pt.a) * pt.r + self.y
    end
    return poly
end
function Crustcle:update(dt)
    for i, pt in pairs(self.pts) do
        prevI = (#self.pts + i - 1) % #self.pts
        nextI = (i + 1) % #self.pts
        pt:update(dt, self.pts[prevI], self.pts[nextI])
    end
end
local function newCrustcle(segments)
    local pts = {}
    for i = 1, segments do
        local angle = i/segments * math.pi * 2
        pts[i] = Cruspt(48, math.random() * 3 + 2, angle, math.pi / segments)
    end
    crustcle = setmetatable({
        x = 100,
        y = 100,
        pts = pts
    }, Crustcle)
    return crustcle
end
setmetatable(Crustcle, {
    __call = function(_, ...) return newCrustcle(...) end
})

crustcle = Crustcle(32)
function crustalCircle()
    love.graphics.polygon("fill", crustcle:poly())
end

shaderT = 0
shaderDt = 2 * math.pi / 60
shaderPts = {
    { 100, 100 },
    { 140, 100 },
    { 120, 130 },
    'banana'
}
shaderColors = {
    { 1, 0, 0, 1 },
    { 0, 0, 1, 1 },
    { 0, 1, 0, 1 },
    'banana'
}
shader = love.graphics.newShader[[
    uniform float time;
    uniform vec2 pts[3];
    uniform vec4 colors[3];
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {

        float totalDst = 0;
        float dsts[3];
        for (int i = 0; i < 3; i++) {
            dsts[i] = distance(screen_coords, pts[i]);
            totalDst += dsts[i];
        }

        vec4 col = vec4(0);
        for (int i = 0; i < 3; i++) {
            col += (1 - (dsts[i] / totalDst)) * colors[i];
        }

        return col;
    }
]]

function love.draw()
    x, y = love.graphics.getDimensions()
    cx, cy = crustal:getDimensions()

    love.graphics.draw(crustal, x/2 - cx/2, y/2 - cy/2)

    love.graphics.stencil(crustalCircle, "invert", 1)

    love.graphics.setStencilTest("greater", 0)
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, x, y)
    love.graphics.setShader()
    love.graphics.setStencilTest()
end
function love.update(dt)
    shaderT = shaderT + shaderDt
    --shader:send("time", shaderT)
    shader:send("pts", unpack(shaderPts));
    shader:send("colors", unpack(shaderColors));
    crustcle:update(dt)
end