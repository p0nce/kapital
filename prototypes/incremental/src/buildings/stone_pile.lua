-- src/buildings/stone_pile.lua
local stone_pile = {}

function stone_pile.init(state)
  local building = state.buildings.stone_pile
  building.contents = 0
  building.cap = 10
end

return stone_pile
