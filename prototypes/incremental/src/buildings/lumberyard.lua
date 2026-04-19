-- src/buildings/lumberyard.lua
local lumberyard = {}

function lumberyard.init(state)
  local building = state.buildings.lumberyard
  building.level = 0
  building.cap = 0
  building.contents = 0
end

return lumberyard
