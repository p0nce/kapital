-- src/buildings/lumberyard.lua
local resources  = require("src/resources")
local lumberyard = {}

function lumberyard.init(state)
  local building = state.buildings.lumberyard
  building.level = 0
  building.cap = 0
  building.contents = 0
end

function lumberyard.build(state)
  local c = state.buildings.lumberyard.build_costs
  if not resources.can_afford(state, "points", c.points) then return false end
  resources.spend(state, "points", c.points)
  state.buildings.lumberyard.built = true
  return true
end

return lumberyard
