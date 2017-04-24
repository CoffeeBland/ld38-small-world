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
alive = true
timeLeft = nil
shakes = {}
shakeX = 0
shakeY = 0
score = 0

function currentScore()
    return floor((score / 60) * 3)
end

playerImg = love.graphics.newImage("imgs/tripod.png")
function tripodMovement(self, actor, movX, movY, speedX, speedY)
    local sinceShot = actor.sinceShot
    local moving = movX == 0 and movY == 0
    self.ty = (sinceShot < 10 and (moving and 3 or 2)) or (moving and 1) or 0
    self.fpt = 20 / (dst(speedX, speedY) / 300 + 1)
end

function damage(amount)
    life = max(min(life - amount, initialLife), 0)
    shake(amount + 4, amount * 20)
end
function damageCrustal(amount)
    if crustal.shouldRemove then return end
    crustal.damaged = crustal.damaged + floor(amount)
    damage(amount)
end
function damageTripod(amount)
    if crustal.shouldRemove then return end
    player.damaged = player.damaged + floor(amount)
    damage(amount)
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

-- duraction: frames, intensity: pixel amount
function shake(duration, intensity)
    table.insert(shakes, { duration, intensity })
end

function game.load()
    score = 0
    local w, h = love.graphics.getDimensions()

    actors = {}
    life = initialLife
    alive = true

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
        uniform float lightDst;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            float dst = max(distance(crustal, screen_coords) - lightDst, 0);
            vec4 col = Texel(texture, texture_coords) * color;
            vec3 rgb = vec3(col) * max(1 - sqrt(dst/512.0), 0.1);
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

function crustalCircle()
    love.graphics.polygon("fill", crustal:poly(camera))
end
function game.draw()
    local x, y = love.graphics.getDimensions()

    local crx, cry = crustal:pos()
    local cx, cy = camera:pos()
    shader:send("crustal", { crx - cx, cry - cy })
    shader:send("lightDst", 256 * crustal.remaining + rand() * 4)
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
function drawScore(w, h)
    love.graphics.setColor(255, 255, 255)

    love.graphics.setFont(smallFont)
    love.graphics.setColor(white)
    love.graphics.print("SCORE", w - 36 - smallFont:getWidth("SCORE"), 24)

    love.graphics.setFont(monoFont)
    local scoreText = tostring(currentScore())
    love.graphics.print(scoreText, w - 36 - monoFont:getWidth(scoreText), 24 + smallFont:getHeight())
end
function game.ui()
    local w, h = love.graphics.getDimensions()

    -- Life bar
    love.graphics.setColor(0, 135, 105)
    love.graphics.rectangle("fill", 30, 34, initialLife*2, 16)
    love.graphics.setColor(0, 198, 154)
    love.graphics.rectangle("fill", 32, 32, life*2, 16)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 90, 70)
    love.graphics.print(tostring(ceil(life)),
        36, round(32 + (16 - smallFont:getHeight()) / 2))

    -- Score
    drawScore(w, h)

    -- Special wave indicator
    if player.specialWaveReady then
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(mediumFont)
        love.graphics.print("Wave Special Ready", 36, h - mediumFont:getHeight() - smallFont:getHeight() - 36)
        love.graphics.setFont(smallFont)
        love.graphics.print("(press space to use)", 36, h - smallFont:getHeight() - 30)
    end
end
function game.update(dt)
    if alive then
        if life <= 0 then
            addActor(BlueBadaboum(crustal:pos()))
            crustal.shouldRemove = true
            shake(10, 100)
            shake(20, 50)
            shake(30, 20)
            shake(60, 10)
            alive = false
            timeLeft = 60
        end
        score = score + 1
    else
        timeLeft = timeLeft - 1
        if timeLeft <= 0 then
            state = 'bananas'
        end
    end

    local shakeIntensity = 0
    for i = #shakes, 1, -1 do
        local shake = shakes[i]
        shake[1] = shake[1] - 1
        if shake[1] <= 0 then
            table.remove(shakes, i)
        else
            shakeIntensity = shakeIntensity + shake[2]
        end
    end
    shakeIntensity = sqrt(shakeIntensity)
    shakeX = (rand() - 0.5) * shakeIntensity
    shakeY = (rand() - 0.5) * shakeIntensity

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
