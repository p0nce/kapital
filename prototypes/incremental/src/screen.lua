-- src/screen.lua
local screen = {}

local CANVAS_W = 800
local CANVAS_H = 600

function screen.w()    return CANVAS_W end
function screen.h()    return CANVAS_H end
function screen.dims() return CANVAS_W, CANVAS_H end

-- Scale and offset of the canvas inside the physical window (letterboxed).
local function canvas_transform()
  local pw, ph = love.graphics.getDimensions()
  local scale  = math.min(pw / CANVAS_W, ph / CANVAS_H)
  local ox     = (pw - CANVAS_W * scale) / 2
  local oy     = (ph - CANVAS_H * scale) / 2
  return scale, ox, oy
end

-- Convert physical window coords → canvas coords.
function screen.to_canvas(px, py)
  local scale, ox, oy = canvas_transform()
  return (px - ox) / scale, (py - oy) / scale
end

-- Canvas-space mouse position.
function screen.mouse_pos()
  return screen.to_canvas(love.mouse.getPosition())
end

-- Draw a canvas to the physical window with nearest-neighbour and letterboxing.
function screen.blit(canvas)
  local pw, ph     = love.graphics.getDimensions()
  local scale, ox, oy = canvas_transform()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, pw, ph)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

return screen
