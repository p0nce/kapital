-- main.lua
local state = require("src/state")
local world = require("src/world")
local sprites = require("src/sprites")
local camera = require("src/camera")
local workers = require("src/workers")
local input = require("src/input")
local hud = require("src/ui/hud")
local tree = require("src/buildings/tree")
local rock = require("src/buildings/rock")
local log_pile = require("src/buildings/log_pile")
local stone_pile = require("src/buildings/stone_pile")
local lumberyard = require("src/buildings/lumberyard")

function love.load()
  world.init(state)
  sprites.load()
  tree.init(state)
  rock.init(state)
  log_pile.init(state)
  stone_pile.init(state)
  lumberyard.init(state)
end

function love.update(dt)
  state.update(dt)
  workers.update(dt, state)
end

function love.draw()
  love.graphics.setColor(0.05, 0.05, 0.05)
  love.graphics.rectangle("fill", 0, 0, 800, 600)

  camera.attach(state)
  world.draw(state)
  workers.draw(state)
  camera.detach()

  hud.draw(state)
end

function love.mousepressed(x, y, button)
  input.mousepressed(state, x, y, button)
end

function love.keypressed(key)
  -- Will route to input system
end
