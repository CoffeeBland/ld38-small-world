love.graphics.setDefaultFilter("nearest", "nearest")

abs = math.abs
pi = math.pi
cos = math.cos
sin = math.sin
pow = math.pow
sqrt = math.sqrt
rand = math.random
floor = math.floor
ceil = math.ceil
min = math.min
max = math.max
function dst(x, y)
    return sqrt(pow(x, 2) + pow(y, 2))
end
function noop() end

PHYS_UNIT = 48
CAT_FRIENDLY = 0x0002
CAT_ENEMY = 0x0004

GRP_PROJ = -1

require('camera')
require('sprite')
require('projectile')
require('actor')
require('crust')
require('environment')

world = nil
environment = nil
player = nil
crustal = nil
crustcle = nil
initialLife = 100
life = 100

playerImg = love.graphics.newImage("imgs/tripod.png")
function tripodMovement(self, movX, movY, speedX, speedY, sinceShot)
    local moving = movX == 0 and movY == 0
    --if self.ty == 1 and moving then
    --    self.tx = 1
    --    self.time = 0
    --end
    self.ty = (sinceShot < 20 and 2) or (moving and 1) or 0
    self.fpt = 20 / (dst(speedX, speedY) / 600 + 1)
end

enemyBasicImg = love.graphics.newImage("imgs/enemy_basic.png")
function wallabiMovement(self, movX, movY, speedX, speedY)
    if movX ~= 0 or movY ~= 0 then
        self.baseTy = (abs(movX) >= abs(movY) and 6) or (movY < 0 and 3) or 0
        self.flipX = movX < 0
        self.ty = self.baseTy
    else
        self.ty = (self.baseTy or 0) + 1
    end
    self.fpt = 10 / (dst(speedX, speedY) / 600 + 1)
end

function crustalCircle()
    love.graphics.polygon("fill", crustcle:poly(camera))
end

actors = {}
function addActor(p)
    table.insert(actors, p)
end
function removeBody(actor)
    local bodies = world:getBodyList()
    for i = #bodies, 1, -1 do
        if bodies[i] == actor.body then
            if actor.fixture then
                actor.fixture:destroy()
            end
            actor.body:destroy()
            table.remove(bodies, i)
            break
        end
    end
end

shaderT = 0
shaderDt = 2 * math.pi / 60
shaderPts = {
    { 100, 100 },
    { 140, 100 },
    { 120, 130 },
    'banana' -- mucho importante!
}
shaderColors = {
    { 1, 0, 0, 0.25 },
    { 0, 0, 1, 0.25 },
    { 0, 1, 0, 0.25 },
    'banana'
}

function love.load()
    love.window.setMode(800, 600, { resizable = true, vsync = true })
    local w, h = love.graphics.getDimensions()

    love.physics.setMeter(PHYS_UNIT)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    camera = Camera()

    local sprite = AnimSprite(playerImg, 48, 64, 4, true, 24, 56)
    sprite.movement = tripodMovement
    player = Player(sprite, {
        up = "up",
        left = "left",
        down = "down",
        right = "right",
        k = "up",
        h = "left",
        j = "down",
        l = "right",
        space = "shoot",
    })
    addActor(player)

    environment = Environment(256)
    addActor(environment)

    crustal = Crustal(0, 0, 192)
    crustcle = Crustcle(192)
    addActor(crustal)

    shader = love.graphics.newShader[[
        uniform vec2 crustal;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            float dst = max(distance(crustal, screen_coords) - 256, 0);
            vec4 col = Texel(texture, texture_coords) * color;
            vec3 rgb = vec3(col) * max(1 - dst/512.0, 0.25);
            return vec4(rgb, col.a);
        }
    ]]
end

function zSort(a, b)
    if a.getZ == nil then
        return false
    end
    if b.getZ == nil then
        return true
    end
    return (b:getZ() - a:getZ()) > 0
end
function love.draw()
    --love.graphics.scale(2, 2)
    local x, y = love.graphics.getDimensions()

    local cx, cy = camera:pos()
    shader:send("crustal", {crustal.x - cx, crustal.y - cy})
    love.graphics.setShader(shader)

    love.graphics.setColor(100, 67, 93)
    love.graphics.rectangle("fill", 0, 0, x, y)

    love.graphics.stencil(crustalCircle, "invert", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(86, 186, 112)
    love.graphics.rectangle("fill", 0, 0, x, y)
    love.graphics.setColor(255, 255, 255)
    love.graphics.setStencilTest()

    table.sort(actors, zSort)
    for i, a in pairs(actors) do
        a:draw(camera)
    end

    -- Life bar
    love.graphics.setShader()
    love.graphics.setColor(0, 135, 105)
    love.graphics.rectangle("fill", 30, 34, initialLife*2, 16)
    love.graphics.setColor(0, 198, 154)
    love.graphics.rectangle("fill", 32, 32, life*2, 16)
    love.graphics.setColor(0, 90, 70)
    love.graphics.print(tostring(ceil(life)), 36, 34)
end
function love.update(dt)
    shaderT = shaderT + shaderDt

    if life <= 0 then
        love.window.close()
    end

    crustcle:update(dt)
    for i = #actors, 1, -1 do
        local a = actors[i]
        a:update(dt)
        if (a.shouldRemove) then
            table.remove(actors, i)
            if a.destroy ~= nil then
                a:destroy()
            end
        end
    end
    world:update(dt)

    local px, py = player:pos()
    local cx, cy = crustal:pos()
    camera.x, camera.y = (px+cx)/2, (py+cy)/2
end

function beginContact(a, b, coll)
    -- x, y = coll:getNormal()
    objA = a:getUserData()
    objB = b:getUserData()
    if objA and objA.collide ~= nil then
        objA:collide(objB)
    end
    if objB and objB.collide ~= nil then
        objB:collide(objA)
    end
end

function endContact(a, b, coll)
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end
