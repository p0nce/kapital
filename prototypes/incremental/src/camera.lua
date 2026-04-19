-- src/camera.lua
local camera = {}

local EDGE_MARGIN = 50
local EDGE_SCROLL_SPEED = 150

function camera.update(dt, state)
  local mx, my = love.mouse.getPosition()
  local sw, sh = love.graphics.getDimensions()
  if mx < EDGE_MARGIN then
    state.camera.x = state.camera.x - EDGE_SCROLL_SPEED * dt
  elseif mx > sw - EDGE_MARGIN then
    state.camera.x = state.camera.x + EDGE_SCROLL_SPEED * dt
  end
  if love.keyboard.isDown("left") then
    state.camera.x = state.camera.x - EDGE_SCROLL_SPEED * dt
  elseif love.keyboard.isDown("right") then
    state.camera.x = state.camera.x + EDGE_SCROLL_SPEED * dt
  end
  if love.keyboard.isDown("up") then
    state.camera.y = state.camera.y - EDGE_SCROLL_SPEED * dt
  elseif love.keyboard.isDown("down") then
    state.camera.y = state.camera.y + EDGE_SCROLL_SPEED * dt
  end
  if state.camera.x < -200 then state.camera.x = -200 end
  if state.camera.x > 750  then state.camera.x = 750  end
  if state.camera.y < -100 then state.camera.y = -100 end
  if state.camera.y > 100  then state.camera.y = 100  end
end

function camera.attach(state)
  local zoom = state.camera.zoom
  local sw, sh = love.graphics.getDimensions()
  love.graphics.push()
  love.graphics.translate(sw / 2, sh / 2)
  love.graphics.scale(zoom, zoom)
  love.graphics.translate(-state.camera.x, -state.camera.y)
end

function camera.detach()
  love.graphics.pop()
end

function camera.screen_to_world(state, screen_x, screen_y)
  local zoom = state.camera.zoom
  local sw, sh = love.graphics.getDimensions()
  local world_x = (screen_x - sw / 2) / zoom + state.camera.x
  local world_y = (screen_y - sh / 2) / zoom + state.camera.y
  return world_x, world_y
end

function camera.set_zoom(state, level)
  state.camera.zoom = level
end

return camera
