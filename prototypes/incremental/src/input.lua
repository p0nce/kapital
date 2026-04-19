-- src/input.lua
local camera = require("src/camera")
local tree = require("src/buildings/tree")
local rock = require("src/buildings/rock")
local world = require("src/world")

local input = {}

function input.mousepressed(state, x, y, button)
  if button ~= 1 then return end

  local world_x, world_y = camera.screen_to_world(state, x, y)

  if world_x >= 40 and world_x < 56 and world_y >= 0 and world_y < 16 then
    tree.click(state)
    return
  end

  if world_x >= 72 and world_x < 88 and world_y >= 0 and world_y < 16 then
    rock.click(state)
    return
  end

  world.mousepressed(state, world_x, world_y, x, y)
end

function input.keypressed(state, key)
  local menu = require("src/ui/menu")
  if key == "escape" then
    menu.close(state)
  elseif key == "left" then
    state.camera.x = state.camera.x - 30
  elseif key == "right" then
    state.camera.x = state.camera.x + 30
  elseif key == "up" then
    state.camera.y = state.camera.y - 30
  elseif key == "down" then
    state.camera.y = state.camera.y + 30
  end
end

function input.wheelmoved(state, x, y)
  local camera = require("src/camera")
  local zooms = {1, 2, 3, 4, 6}
  if y > 0 then
    for i, z in ipairs(zooms) do
      if z == state.camera.zoom and i < #zooms then
        camera.set_zoom(state, zooms[i + 1])
        break
      end
    end
  elseif y < 0 then
    for i, z in ipairs(zooms) do
      if z == state.camera.zoom and i > 1 then
        camera.set_zoom(state, zooms[i - 1])
        break
      end
    end
  end
end

return input
