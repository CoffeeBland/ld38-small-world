love.graphics.setDefaultFilter("nearest", "nearest")
love.window.setMode(800, 600, { resizable = true, vsync = true, fullscreen = true })
love.mouse.setVisible(false)

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
function sign(x) return (x < 0 and -1) or (x > 0 and 1) or 0 end
function round(x) return -ceil(-x) end
min = math.min
max = math.max
function clamp(x, m, M) return max(min(x, M), m) end
function dst(x, y) return sqrt(dst2(x, y)) end
function dst2(x, y) return pow(x, 2) + pow(y, 2) end
function noop() end
white = {255/255, 255/255, 255/255}
magenta = {255/255, 0/255, 96/255}
blue = {23/255, 34/255, 255/255}
teal = {0/255, 255/255, 255/255}
grass = {86/255, 186/255, 112/255}
dirt = {100/255, 67/255, 93/255}

require('game')
state = 'splash'
monoFont = nil
smallFont = nil
mediumFont = nil
largeFont = nil
coffeeBlandLogoImg = love.graphics.newImage("imgs/coffeebland.png")
splashFrames = 360
splashAlphaFrames = 120
splashFrame = 0

titleText = 'CRUSTAL'
promptText = 'PRESS SPACE OR ENTER TO BEGIN'
explanationText = "The CRUSTAL! The last bastion of hope for this small world.\n" ..
    "It must be protected at all costs!\n" ..
    "Alas, hordes of musterds creep in the shadows..."
controlsText = "arrows - move | w a s d - shoot | lshift - diagonal"
gameoverText = 'FAILURE!'

function love.load()
    love.window.setTitle('Crustal')
    --love.window.setIcon(love.graphics.newImage('imgs/crustal.png'):getData())
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
        if splashFrame >= splashFrames then
            state = "title"
        end
    end

    if state == 'game' then
        game.update(dt)
    end
end
function love.keypressed(key)
    if key == 'f11' then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
    if state == 'game' then
        if key == 'escape' then
            state = 'pause'
        end
    elseif state == 'splash' then
        if key == 'space' or key == 'return' then
            state = 'title'
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
    love.graphics.setColor(blue)
    love.graphics.printf(text, x - s, y - s, w, 'center')
    love.graphics.setColor(magenta)
    love.graphics.printf(text, x + s, y + s, w, 'center')
    love.graphics.setColor(255/255, 255/255, 255/255)
    love.graphics.printf(text, x, y, w, 'center')
end
function love.draw()
    local x, y = love.graphics.getDimensions()
    if state == 'splash' then

        love.graphics.setColor(72/255, 72/255, 72/255)
        love.graphics.rectangle('fill', 0, 0, x, y)

        local logoX, logoY = coffeeBlandLogoImg:getDimensions()
        love.graphics.setColor(255/255, 255/255, 255/255)
        love.graphics.draw(coffeeBlandLogoImg, x/2 - logoX/2, y/2 - logoY/2)

        -- fade in
        local alpha = 1 - min(splashFrame - 30, splashFrames - 30 - splashFrame) / splashAlphaFrames
        love.graphics.setColor(0/255, 0/255, 0/255, alpha)
        love.graphics.setShader(shader)
        love.graphics.rectangle('fill', 0, 0, x, y)
        love.graphics.setShader()
        return
    end

    game.draw()
    if state ~= 'game' then
        love.graphics.setColor(0/255, 0/255, 0/255, 170/255)
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
            love.graphics.setFont(largeFont)
            shadowRender('PAUSED', 0, (y - largeFont:getHeight()) / 2, x)
            drawScore(x, y)
        end
        love.graphics.setFont(smallFont)
        love.graphics.printf(controlsText, 0, 16, x, 'center');
    else
        game.ui()
    end
end
bob = 1
