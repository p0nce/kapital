-- src/buildings/tree.lua
local resources = require("src/resources")
local tree = {}

local HARVEST_RATE = 0.5  -- resources per second per worker

function tree.click(state)
  resources.add(state, "points", 1)
  if state.buildings.log_pile.contents < state.buildings.log_pile.cap then
    resources.add(state, "wood", 1)
    state.buildings.log_pile.contents = state.buildings.log_pile.contents + 1
  end
end

function tree.init(state)
  local b = state.buildings.tree
  b.level = 1
  b.workers = {}
end

function tree.update(dt, state)
  local b = state.buildings.tree
  if #b.workers == 0 then return end
  local amount = #b.workers * HARVEST_RATE * dt
  resources.add(state, "points", amount)
  if state.buildings.log_pile.contents < state.buildings.log_pile.cap then
    local add = math.min(amount, state.buildings.log_pile.cap - state.buildings.log_pile.contents)
    resources.add(state, "wood", add)
    state.buildings.log_pile.contents = state.buildings.log_pile.contents + add
  end
end

return tree
