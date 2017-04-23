love.graphics.setDefaultFilter("nearest", "nearest")

abs = math.abs
pi = math.pi
cos = math.cos
sin = math.sin
pow = math.pow
sqrt = math.sqrt
math.randomseed(love.timer.getTime())
rand = math.random
floor = math.floor
ceil = math.ceil
function round(x)
    return -ceil(-x)
end
min = math.min
max = math.max
function clamp(x, m, M)
    return max(min(x, M), m)
end
function dst(x, y)
    return sqrt(pow(x, 2) + pow(y, 2))
end
function dst2(x, y)
    return pow(x, 2) + pow(y, 2)
end
function noop() end

require('game')
state = 'splash'
monoFont = nil
smallFont = nil
mediumFont = nil
largeFont = nil
coffeeBlandLogoImg = love.graphics.newImage("imgs/coffeebland.png")
splashFrames = 480
splashFrame = 0

titleText = 'CRUSTAL'
promptText = 'PRESS SPACE OR ENTER TO BEGIN'
explanationText = "The CRUSTAL! The last bastion of hope for this small world.\n" ..
    "It must be protected at all costs!\n" ..
    "Alas, hordes of musterds creep in the shadows..."
controlsText = "arrows - move | w a s d - shoot"
gameoverText = 'FAILURE!'

function love.load()
    love.window.setMode(800, 600, { resizable = true, vsync = true })
    love.window.setTitle('Crustal')
    love.window.setIcon(love.graphics.newImage('imgs/crustal.png'):getData())
    game.load()
    game.update(0)
    monoFont = love.graphics.newFont('fonts/Go-Mono-Bold.ttf', 18)
    smallFont = love.graphics.newFont('fonts/Montserrat-Medium.ttf', 12)
    mediumFont = love.graphics.newFont('fonts/Montserrat-Medium.ttf', 24)
    largeFont = love.graphics.newFont('fonts/Montserrat-Medium.ttf', 92)
end

function love.update(dt)
    if state == "splash" then
        splashFrame = splashFrame + 1

        -- wait 6 seconds
        if splashFrame >= splashFrames then
            state = "title"
        end
    end

    if state == 'game' then
        game.update(dt)
    end
end
function love.keypressed(key)
    if state == 'game' then
        if key == 'escape' then
            state = 'pause'
        end
    elseif state == 'title' or state == 'bananas' then
        if key == 'escape' then
            love.event.quit()
        end
        if key == 'space' or key == 'return' then
            if state == 'bananas' then game.load() end
            state = 'game'
        end
    elseif state == 'pause' then
        if key == 'escape' then
            state = 'game'
        end
    end
end

function shadowRender(text, x, y, w, s)
    s = s or 2
    love.graphics.setColor(0, 0, 255)
    love.graphics.printf(text, x - s, y - s, w, 'center')
    love.graphics.setColor(255, 0, 200)
    love.graphics.printf(text, x + s, y + s, w, 'center')
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf(text, x, y, w, 'center')
end
function love.draw()
    if state == 'splash' then
        local w, h = love.graphics.getDimensions()
        love.graphics.setColor(255, 255, 255, 230)
        love.graphics.rectangle('fill', 0, 0, w, h)
        local logoX, logoY = coffeeBlandLogoImg:getDimensions()
        love.graphics.draw(coffeeBlandLogoImg, w/2 - logoX/2, h/2 - logoY/2)

        -- fade in
        local alpha = 255
        if splashFrame < 120 then
            alpha = 255 - ((splashFrame / 120) * 255)
        elseif splashFrame < (splashFrames-120) then
            alpha = 0
        else
            alpha = ((splashFrame-(splashFrames-120)) / 120) * 255
        end
        print(alpha)
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle('fill', 0, 0, w, h)
        return
    end

    game.draw()
    if state ~= 'game' then
        local x, y = love.graphics.getDimensions()
        love.graphics.setColor(0, 0, 0, 170)
        love.graphics.rectangle('fill', 0, 0, x, y)

        if state == 'title' then
            love.graphics.setFont(largeFont)
            shadowRender(titleText, 0, y / 2 - largeFont:getHeight() - 8, x)
            love.graphics.setFont(mediumFont)
            shadowRender(promptText, 0, y / 2, x)
            love.graphics.setFont(smallFont)
            love.graphics.printf(explanationText,
                0, y - smallFont:getHeight()*3 - 16,
                x, 'center')
        elseif state == 'bananas' then
            love.graphics.setFont(largeFont)
            shadowRender(gameoverText, 0, y / 2 - largeFont:getHeight() - 8, x)
            love.graphics.setFont(mediumFont)
            shadowRender(promptText, 0, y / 2, x)
            drawScore(x, y)
        elseif state == 'pause' then
            love.graphics.setFont(mediumFont)
            shadowRender('PAUSED', 0, y / 2, x)
            drawScore(x, y)
        end
        love.graphics.setFont(smallFont)
        love.graphics.printf(controlsText, 0, 16, x, 'center');
    else
        game.ui()
    end
end
