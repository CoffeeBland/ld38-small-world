require('actor')
require('crust')

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
    { 1, 0, 0, 0.25 },
    { 0, 0, 1, 0.25 },
    { 0, 1, 0, 0.25 },
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

function love.load()
    love.window.setMode(640, 480, { resizable = true, vsync = true })

    love.physics.setMeter(48)
    world = love.physics.newWorld(0, 0, true)

    local sprite = AnimSprite("wallabi.png", 48, 48, 10, 24, 24)
    local controls = {
        up = "up",
        left = "left",
        down = "down",
        right = "right"
    }
    local body = love.physics.newBody(world, 0, 0, 'dynamic')
    body:setFixedRotation(true)
    body:setLinearDamping(10)
    local shape = love.physics.newCircleShape(1)
    local fixture = love.physics.newFixture(body, shape, 1)

    player = Player(sprite, controls, body)
end

function love.draw()
    local x, y = love.graphics.getDimensions()
    local cx, cy = crustal:getDimensions()

    love.graphics.clear(255, 128, 128)
    love.graphics.draw(crustal, x/2 - cx/2, y/2 - cy/2)

    love.graphics.stencil(crustalCircle, "invert", 1)

    love.graphics.setStencilTest("greater", 0)
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, x, y)
    love.graphics.setShader()
    love.graphics.setStencilTest()

    player:draw()
end
function love.update(dt)
    shaderT = shaderT + shaderDt
    --shader:send("time", shaderT)
    shader:send("pts", unpack(shaderPts));
    shader:send("colors", unpack(shaderColors));

    crustcle:update(dt)
    player:update(dt)
    world:update(dt)

    crustcle.x = player.body:getX()
    crustcle.y = player.body:getY()
end