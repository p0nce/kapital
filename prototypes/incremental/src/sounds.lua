-- src/sounds.lua
local sounds = {}
local data = {}

function sounds.load()
  data.axe  = love.audio.newSource("sounds/axe.wav",  "static")
  data.mine = love.audio.newSource("sounds/mine.wav", "static")
end

function sounds.play(name)
  local src = data[name]
  if src then
    src:stop()
    src:play()
  end
end

return sounds
