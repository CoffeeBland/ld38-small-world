Snd = {}
Snd.__index = Snd
local function newSnd()
    return setmetatable({
      x = 0,
      y = 0,
    }, Snd)
end
setmetatable(Snd, {
    __call = function(_, ...) return newSnd(...) end
})
function Snd:play(x, y)
end

local files = {
    prebeam = 'prebeam.wav',
    beam = 'beam.wav',
    shoot = 'shoot.wav',
    health = 'health.wav',
    death = 'death.wav',
}
snds = {}
