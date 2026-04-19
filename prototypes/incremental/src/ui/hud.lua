-- src/ui/hud.lua
local hud = {}

function hud.draw(state)
  love.graphics.setColor(1, 1, 1)
  local text = string.format(
    "Points: %d  Wood: %d  Stones: %d  SP: %d  Bombs: %d",
    math.floor(state.resources.points),
    math.floor(state.resources.wood),
    math.floor(state.resources.stones),
    state.resources.sp,
    state.resources.bombs
  )
  love.graphics.print(text, 10, 10)
end

return hud
