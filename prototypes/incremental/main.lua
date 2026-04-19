-- main.lua
local state = require("src/state")

function love.load()
  -- State is initialized
end

function love.update(dt)
  state.update(dt)
end

function love.draw()
  -- Will dispatch to subsystems
end

function love.mousepressed(x, y, button)
  -- Will route to input system
end

function love.keypressed(key)
  -- Will route to input system
end
