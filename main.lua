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
state = 'title'
smallFont = nil
mediumFont = nil
largeFont = nil

titleText = 'CRUSTAL'
promptText = 'PRESS SPACE OR ENTER TO BEGIN'
explanationText = "The CRUSTAL! The last bastion of hope for this small world.\n" ..
    "It must be protected at all costs!\n" ..
    "Alas, hordes of musterds creep in the shadows..."
controlsText = "arrows - move | space - shoot"
gameoverText = 'FAILURE!'

function love.load()
    love.window.setMode(800, 600, { resizable = true, vsync = true })
    game.load()
    game.update(0)
    smallFont = love.graphics.newFont('Montserrat-Medium.ttf', 12)
    mediumFont = love.graphics.newFont('Montserrat-Medium.ttf', 24)
    largeFont = love.graphics.newFont('Montserrat-Medium.ttf', 92)
end

function love.update(dt)
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

function shadowRender(text, x, y, w)
    love.graphics.setColor(0, 0, 255)
    love.graphics.printf(text, x - 2, y - 2, w, 'center')
    love.graphics.setColor(255, 0, 200)
    love.graphics.printf(text, x + 2, y + 2, w, 'center')
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf(text, x, y, w, 'center')
end
function love.draw()
    game.draw()
    if state ~= 'game' then
        local x, y = love.graphics.getDimensions()
        love.graphics.setColor(0, 0, 0, 200)
        love.graphics.rectangle('fill', 0, 0, x, y)
        love.graphics.setColor(255, 255, 255)

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
        elseif state == 'pause' then
            love.graphics.setFont(mediumFont)
            shadowRender('PAUSED', 0, y / 2, x)
        end
        love.graphics.setFont(smallFont)
        love.graphics.printf(controlsText, 0, 16, x, 'center');
    else
        game.ui()
    end
end
