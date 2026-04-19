-- src/ui/arrows.lua
local arrows = {}

-- Draw ◀ N ▶ widget at (x,y). Returns clickable regions.
function arrows.draw_and_get_regions(x, y, count)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("\xe2\x97\x80 " .. tostring(count) .. " \xe2\x96\xb6", x, y)
  return {
    left = {x = x, y = y, w = 15, h = 15},
    right = {x = x + 30, y = y, w = 15, h = 15},
  }
end

return arrows
