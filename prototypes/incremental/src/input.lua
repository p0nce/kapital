-- src/input.lua
local camera = require("src/camera")
local tree = require("src/buildings/tree")
local rock = require("src/buildings/rock")
local world = require("src/world")

local input = {}

function input.mousepressed(state, x, y, button)
  if button ~= 1 then return end

  local world_x, world_y = camera.screen_to_world(state, x, y)

  local tb = state.buildings.tree
  if world_x >= tb.x and world_x < tb.x + tb.w * 8 and
     world_y >= tb.y and world_y < tb.y + tb.h * 8 then
    tree.click(state)
    return
  end

  local rb = state.buildings.rock
  if world_x >= rb.x and world_x < rb.x + rb.w * 8 and
     world_y >= rb.y and world_y < rb.y + rb.h * 8 then
    rock.click(state)
    return
  end

  world.mousepressed(state, world_x, world_y, x, y)
end

function input.keypressed(state, key)
  local menu = require("src/ui/menu")
  local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
  if key == "f11" or (key == "return" and alt) then
    love.window.setFullscreen(not love.window.isFullscreen())
  elseif key == "f5" then
    love.event.quit("restart")
  elseif key == "escape" then
    menu.close(state)
  end
end

local WHEEL_PAN_SPEED = 24
local HUD_HEIGHT = 30  -- pixels; wheel ignored when cursor is over HUD

function input.wheelmoved(state, x, y)
  local _, my = love.mouse.getPosition()
  if my <= HUD_HEIGHT then return end
  state.camera.y = state.camera.y - y * WHEEL_PAN_SPEED
  if state.camera.y < -100 then state.camera.y = -100 end
  if state.camera.y >  100 then state.camera.y =  100 end
end

return input
