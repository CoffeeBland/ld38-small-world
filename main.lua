love.graphics.setDefaultFilter("nearest", "nearest")

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

playerImg = love.graphics.newImage("imgs/wallabi.png")
enemyBasicImg = love.graphics.newImage("imgs/enemy_basic.png")

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
            actor.fixture:destroy()
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

    love.physics.setMeter(48)
    world = love.physics.newWorld(0, 0, true)

    camera = Camera()

    local sprite = AnimSprite(playerImg, 48, 48, 4, true, 24, 32)
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

    crustal = Crustal()
    crustcle = Crustcle(192)
    addActor(crustal)

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

    love.graphics.clear(90, 67, 73)

    love.graphics.stencil(crustalCircle, "invert", 1)

    love.graphics.setStencilTest("greater", 0)
    --love.graphics.setShader(shader)
    love.graphics.setColor(86, 186, 112)
    love.graphics.rectangle("fill", 0, 0, x, y)
    love.graphics.setColor(255, 255, 255)
    --love.graphics.setShader()
    love.graphics.setStencilTest()

    table.sort(actors, zSort)
    for i, a in pairs(actors) do
        a:draw(camera)
    end
end
function love.update(dt)
    shaderT = shaderT + shaderDt
    -- shader:send("time", shaderT)
    shader:send("pts", unpack(shaderPts))
    shader:send("colors", unpack(shaderColors))

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
