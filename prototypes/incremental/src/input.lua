-- src/input.lua
local camera = require("src/camera")
local tree = require("src/buildings/tree")
local rock = require("src/buildings/rock")

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
end

return input
