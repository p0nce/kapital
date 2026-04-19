-- src/camera.lua
local camera = {}

local EDGE_MARGIN = 50
local EDGE_SCROLL_SPEED = 150

function camera.update(dt, state)
  local mx, my = love.mouse.getPosition()
  if mx < EDGE_MARGIN then
    state.camera.x = state.camera.x - EDGE_SCROLL_SPEED * dt
  elseif mx > 800 - EDGE_MARGIN then
    state.camera.x = state.camera.x + EDGE_SCROLL_SPEED * dt
  end
  if state.camera.x < -50 then state.camera.x = -50 end
  if state.camera.x > 300 then state.camera.x = 300 end
end

function camera.attach(state)
  local zoom = state.camera.zoom
  love.graphics.push()
  love.graphics.translate(400, 300)  -- Center of 800x600 window
  love.graphics.scale(zoom, zoom)
  love.graphics.translate(-state.camera.x, -state.camera.y)
end

function camera.detach()
  love.graphics.pop()
end

function camera.screen_to_world(state, screen_x, screen_y)
  local zoom = state.camera.zoom
  local world_x = (screen_x - 400) / zoom + state.camera.x
  local world_y = (screen_y - 300) / zoom + state.camera.y
  return world_x, world_y
end

function camera.set_zoom(state, level)
  state.camera.zoom = level
end

return camera
