-- src/buildings/rock.lua
local resources = require("src/resources")
local rock = {}

function rock.click(state)
  resources.add(state, "points", 1)
  resources.add(state, "stones", 1)
end

function rock.init(state)
  local building = state.buildings.rock
  building.level = 1
  building.workers = {}
end

function rock.update(dt, state)
  -- Will implement worker mining
end

return rock
