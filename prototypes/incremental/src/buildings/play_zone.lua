-- src/buildings/play_zone.lua
local resources = require("src/resources")
local play_zone = {}

local BUILD_COST_POINTS = 150
local BUILD_COST_WOOD = 50

function play_zone.can_build(state)
  return resources.can_afford(state, "points", BUILD_COST_POINTS) and
         resources.can_afford(state, "wood", BUILD_COST_WOOD)
end

function play_zone.build(state)
  if not play_zone.can_build(state) then return false end
  resources.spend(state, "points", BUILD_COST_POINTS)
  resources.spend(state, "wood", BUILD_COST_WOOD)
  state.buildings.play_zone.built = true
  return true
end

function play_zone.init(state)
  local b = state.buildings.play_zone
  b.level = 0
  b.workers = {}
  b.tiles_in_queue = 0
end

function play_zone.receive_tile(state)
  local minesweeper = require("src/minesweeper")
  state.buildings.play_zone.tiles_in_queue = state.buildings.play_zone.tiles_in_queue + 1
  minesweeper.add_tile(state)
end

return play_zone
