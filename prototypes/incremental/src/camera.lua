-- src/camera.lua
local camera = {}

function camera.update(dt, state)
  -- Will be expanded for edge-scroll and manual pan
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

return camera
