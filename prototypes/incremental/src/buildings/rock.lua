-- src/buildings/rock.lua
local resources = require("src/resources")
local rock = {}

local HARVEST_RATE = 0.5  -- resources per second per worker

function rock.click(state)
  resources.add(state, "points", 1)
  if state.buildings.stone_pile.contents < state.buildings.stone_pile.cap then
    resources.add(state, "stones", 1)
    state.buildings.stone_pile.contents = state.buildings.stone_pile.contents + 1
  end
end

function rock.init(state)
  local b = state.buildings.rock
  b.level = 1
  b.workers = {}
end

function rock.update(dt, state)
  local b = state.buildings.rock
  if #b.workers == 0 then return end
  local amount = #b.workers * HARVEST_RATE * dt
  resources.add(state, "points", amount)
  if state.buildings.stone_pile.contents < state.buildings.stone_pile.cap then
    local add = math.min(amount, state.buildings.stone_pile.cap - state.buildings.stone_pile.contents)
    resources.add(state, "stones", add)
    state.buildings.stone_pile.contents = state.buildings.stone_pile.contents + add
  end
end

return rock
