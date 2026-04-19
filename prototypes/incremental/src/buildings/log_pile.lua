-- src/buildings/log_pile.lua
local log_pile = {}

function log_pile.init(state)
  local building = state.buildings.log_pile
  building.contents = 0
  building.cap = 10
end

return log_pile
