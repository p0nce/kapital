-- main.lua
local state = require("src/state")
local world = require("src/world")
local sprites = require("src/sprites")
local camera = require("src/camera")
local workers = require("src/workers")
local input = require("src/input")
local hud = require("src/ui/hud")
local menu = require("src/ui/menu")
local tree = require("src/buildings/tree")
local rock = require("src/buildings/rock")
local log_pile = require("src/buildings/log_pile")
local stone_pile = require("src/buildings/stone_pile")
local lumberyard = require("src/buildings/lumberyard")
local dormitory = require("src/buildings/dormitory")

function love.load()
  world.init(state)
  sprites.load()
  tree.init(state)
  rock.init(state)
  log_pile.init(state)
  stone_pile.init(state)
  lumberyard.init(state)
  dormitory.init(state)
end

function love.update(dt)
  state.update(dt)
  camera.update(dt, state)
  workers.update(dt, state)
  tree.update(dt, state)
  rock.update(dt, state)
end

function love.draw()
  love.graphics.setColor(0.05, 0.05, 0.05)
  love.graphics.rectangle("fill", 0, 0, 800, 600)

  camera.attach(state)
  world.draw(state)
  workers.draw(state)
  camera.detach()

  hud.draw(state)

  if menu.get_open_building(state) == "dormitory" then
    menu.draw_header("Dormitory")
    local items = dormitory.menu_items(state)
    local y = 40
    for _, item in ipairs(items) do
      menu.draw_item(y, item.label, item.affordable)
      y = y + 25
    end
  end
end

function love.mousepressed(x, y, button)
  input.mousepressed(state, x, y, button)
end

function love.keypressed(key)
  input.keypressed(state, key)
end

function love.wheelmoved(x, y)
  input.wheelmoved(state, x, y)
end
