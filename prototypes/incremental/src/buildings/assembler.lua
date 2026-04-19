-- src/buildings/assembler.lua
local resources = require("src/resources")
local assembler = {}

local BUILD_COST_POINTS = 75
local BUILD_COST_WOOD = 30
local BLOCKS_PER_TILE = 4
local PROCESS_RATE = 0.25  -- tiles per second

function assembler.can_build(state)
  return resources.can_afford(state, "points", BUILD_COST_POINTS) and
         resources.can_afford(state, "wood", BUILD_COST_WOOD)
end

function assembler.build(state)
  if not assembler.can_build(state) then return false end
  resources.spend(state, "points", BUILD_COST_POINTS)
  resources.spend(state, "wood", BUILD_COST_WOOD)
  state.buildings.assembler.built = true
  return true
end

function assembler.init(state)
  local b = state.buildings.assembler
  b.level = 0
  b.workers = {}
  b.buffer = 0
  b.buffer_cap = 5
end

function assembler.update(dt, state)
  local b = state.buildings.assembler
  if not b.built then return end
  local input_avail = state.buildings.compactor.buffer
  local output_space = b.buffer_cap - b.buffer
  if input_avail >= BLOCKS_PER_TILE and output_space > 0 then
    local tile_rate = PROCESS_RATE * dt
    local max_from_input = math.floor(input_avail / BLOCKS_PER_TILE) * PROCESS_RATE * dt
    local produced = math.min(max_from_input, output_space)
    state.buildings.compactor.buffer = state.buildings.compactor.buffer - (produced * BLOCKS_PER_TILE)
    b.buffer = b.buffer + produced
  end
end

return assembler
