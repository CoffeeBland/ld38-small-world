CAT_FRIENDLY = 0x0002
CAT_ENEMY = 0x0004

require('camera')
require('sprite')
require('projectile')
require('actor')
require('crust')
require('environment')

game = {}
actors = nil
world = nil
environment = nil
player = nil
crustal = nil
initialLife = 100
life = nil
shakes = {}
shakeX = 0
shakeY = 0

playerImg = love.graphics.newImage("imgs/tripod.png")
function tripodMovement(self, movX, movY, speedX, speedY, sinceShot)
    local moving = movX == 0 and movY == 0
    self.ty = (sinceShot < 20 and (moving and 3 or 2)) or (moving and 1) or 0
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

blobImg = love.graphics.newImage("imgs/blob.png")
blobMovement = wallabiMovement

function crustalCircle()
    love.graphics.polygon("fill", crustal:poly(camera))
end

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

function shakeSort(a, b)
    return b[1] - a[1] > 0
end
-- duraction: frames, intensity: pixel amount
function shake(duration, intensity)
    table.insert(shakes, { duration, intensity })
    table.sort(shakes, shakeSort)
end

function game.load()
    local w, h = love.graphics.getDimensions()

    actors = {}
    life = initialLife

    love.physics.setMeter(48)
    if world then
        world:destroy()
    end
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    camera = Camera()

    local sprite = AnimSprite(playerImg, 48, 72, 4, true, 24, 56)
    sprite.movement = tripodMovement
    player = Player(sprite, {
        up = "up",
        left = "left",
        down = "down",
        right = "right",
        space = "special",
        w = "shoot",
        a = "shoot",
        s = "shoot",
        d = "shoot",
    }, (rand() - 0.5) * 128, (rand() - 0.5) * 128)
    addActor(player)

    environment = Environment(256)
    addActor(environment)

    crustal = Crustal(192)
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
        return true
    end
    if b.getZ == nil then
        return false
    end
    return (b:getZ() - a:getZ()) > 0
end

function game.draw()
    local x, y = love.graphics.getDimensions()

    local cx, cy = camera:pos()
    shader:send("crustal", {crustal.body:getX() - cx, crustal.body:getY() - cy})
    love.graphics.setShader(shader)

    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)

    love.graphics.setColor(100, 67, 93)
    love.graphics.rectangle("fill", 0, 0, x, y)

    love.graphics.stencil(crustalCircle, "invert", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(86, 186, 112)
    love.graphics.rectangle("fill", 0, 0, x, y)
    love.graphics.setStencilTest()

    table.sort(actors, zSort)
    for i, a in pairs(actors) do
        a:draw(camera)
    end
    love.graphics.pop()
    love.graphics.setShader()
end
function game.ui()
    -- Life bar
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 135, 105)
    love.graphics.rectangle("fill", 30, 34, initialLife*2, 16)
    love.graphics.setColor(0, 198, 154)
    love.graphics.rectangle("fill", 32, 32, life*2, 16)
    love.graphics.setColor(0, 90, 70)
    love.graphics.print(tostring(ceil(life)),
        36, round(32 + (16 - smallFont:getHeight()) / 2))

    -- Special wave indicator
    if player.specialWaveReady then
        local w, h = love.graphics.getDimensions()
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(mediumFont)
        love.graphics.print("Wave Special Ready", 36, h - mediumFont:getHeight() - smallFont:getHeight() - 16)
        love.graphics.setFont(smallFont)
        love.graphics.print("(press space to use)", 36, h - smallFont:getHeight() - 8)
    end
end
function game.update(dt)
    if life <= 0 then
        state = 'bananas'
        return
    end

    for i = #shakes, 1, -1 do
        local shake = shakes[i]
        shake[1] = shake[1] - 1
        if shake[1] <= 0 then
            table.remove(shakes, i)
        end
    end
    if #shakes > 0 then
        shakeX = (rand() - 0.5) * shakes[#shakes][2]
        shakeY = (rand() - 0.5) * shakes[#shakes][2]
    else
        shakeX = 0
        shakeY = 0
    end

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
