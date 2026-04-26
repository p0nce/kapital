-- src/camera.lua
local screen = require("src/screen")
local camera = {}

local EDGE_MARGIN = 50
local EDGE_SCROLL_SPEED = 150

function camera.update(dt, state)
  local mx, my = screen.mouse_pos()
  if mx < EDGE_MARGIN then
    state.camera.x = state.camera.x - EDGE_SCROLL_SPEED * dt
  elseif mx > screen.w() - EDGE_MARGIN then
    state.camera.x = state.camera.x + EDGE_SCROLL_SPEED * dt
  end
  if my < EDGE_MARGIN then
    state.camera.y = state.camera.y - EDGE_SCROLL_SPEED * dt
  elseif my > screen.h() - EDGE_MARGIN then
    state.camera.y = state.camera.y + EDGE_SCROLL_SPEED * dt
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
  love.graphics.push()
  love.graphics.translate(screen.w() / 2, screen.h() / 2)
  love.graphics.scale(zoom, zoom)
  love.graphics.translate(-state.camera.x, -state.camera.y)
end

function camera.detach()
  love.graphics.pop()
end

function camera.screen_to_world(state, screen_x, screen_y)
  local zoom = state.camera.zoom
  local world_x = (screen_x - screen.w() / 2) / zoom + state.camera.x
  local world_y = (screen_y - screen.h() / 2) / zoom + state.camera.y
  return world_x, world_y
end

function camera.set_zoom(state, level)
  state.camera.zoom = level
end

return camera
