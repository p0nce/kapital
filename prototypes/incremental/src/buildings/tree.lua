-- src/buildings/tree.lua
local resources = require("src/resources")
local tree = {}

function tree.click(state)
  resources.add(state, "points", 1)
  resources.add(state, "wood", 1)
end

function tree.init(state)
  local building = state.buildings.tree
  building.level = 1
  building.workers = {}
end

function tree.update(dt, state)
  -- Will implement worker harvesting
end

return tree
