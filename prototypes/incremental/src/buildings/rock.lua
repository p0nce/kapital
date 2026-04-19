-- src/buildings/rock.lua
local resources = require("src/resources")
local rock = {}

function rock.click(state)
  resources.add(state, "points", 1)
  if state.buildings.stone_pile.contents < state.buildings.stone_pile.cap then
    resources.add(state, "stones", 1)
    state.buildings.stone_pile.contents = state.buildings.stone_pile.contents + 1
  end
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
