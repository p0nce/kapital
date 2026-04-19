-- src/buildings/compactor.lua
local resources = require("src/resources")
local compactor = {}

local BUILD_COST_POINTS = 50
local BUILD_COST_WOOD = 20
local PROCESS_RATE = 1.0  -- stones → blocks per second

function compactor.can_build(state)
  return resources.can_afford(state, "points", BUILD_COST_POINTS) and
         resources.can_afford(state, "wood", BUILD_COST_WOOD)
end

function compactor.build(state)
  if not compactor.can_build(state) then return false end
  resources.spend(state, "points", BUILD_COST_POINTS)
  resources.spend(state, "wood", BUILD_COST_WOOD)
  state.buildings.compactor.built = true
  return true
end

function compactor.init(state)
  local b = state.buildings.compactor
  b.level = 0
  b.workers = {}
  b.buffer = 0
  b.buffer_cap = 5
end

function compactor.update(dt, state)
  local b = state.buildings.compactor
  if not b.built then return end
  local input_avail = state.buildings.stone_pile.contents
  local output_space = b.buffer_cap - b.buffer
  if input_avail > 0 and output_space > 0 then
    local amount = math.min(input_avail, output_space) * PROCESS_RATE * dt
    state.buildings.stone_pile.contents = state.buildings.stone_pile.contents - amount
    b.buffer = b.buffer + amount
  end
end

return compactor
