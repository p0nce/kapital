-- main.lua
local state = require("src/state")
local world = require("src/world")
local sprites = require("src/sprites")
local camera = require("src/camera")

function love.load()
  world.init(state)
  sprites.load()
end

function love.update(dt)
  state.update(dt)
end

function love.draw()
  love.graphics.setColor(0.05, 0.05, 0.05)
  love.graphics.rectangle("fill", 0, 0, 800, 600)

  camera.attach(state)
  world.draw(state)
  camera.detach()
end

function love.mousepressed(x, y, button)
  -- Will route to input system
end

function love.keypressed(key)
  -- Will route to input system
end
