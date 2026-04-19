-- src/buildings/loading_dock.lua
local resources = require("src/resources")
local loading_dock = {}

local BUILD_COST_POINTS = 100
local BUILD_COST_WOOD = 40
local TRUCK_RATE = 1.0  -- tiles per second delivered

function loading_dock.can_build(state)
  return resources.can_afford(state, "points", BUILD_COST_POINTS) and
         resources.can_afford(state, "wood", BUILD_COST_WOOD)
end

function loading_dock.build(state)
  if not loading_dock.can_build(state) then return false end
  resources.spend(state, "points", BUILD_COST_POINTS)
  resources.spend(state, "wood", BUILD_COST_WOOD)
  state.buildings.loading_dock.built = true
  return true
end

function loading_dock.init(state)
  local b = state.buildings.loading_dock
  b.level = 0
  b.workers = {}
end

function loading_dock.update(dt, state)
  local b = state.buildings.loading_dock
  if not b.built then return end
  local input_avail = state.buildings.assembler.buffer
  if input_avail > 0 then
    local deliver = math.min(input_avail, TRUCK_RATE * dt)
    state.buildings.assembler.buffer = state.buildings.assembler.buffer - deliver
    local play_zone = require("src/buildings/play_zone")
    for i = 1, math.floor(deliver) do
      play_zone.receive_tile(state)
    end
  end
end

return loading_dock
