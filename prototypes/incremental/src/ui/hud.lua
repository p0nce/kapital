-- src/ui/hud.lua
local hud = {}

function hud.draw(state)
  love.graphics.setColor(1, 1, 1)
  local text = string.format(
    "Points: %d  Wood: %d  SP: %d  Metal: %d",
    state.resources.points,
    state.resources.wood,
    state.resources.sp,
    0
  )
  love.graphics.print(text, 10, 10)
end

return hud
