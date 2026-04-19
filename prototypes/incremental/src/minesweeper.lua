-- src/minesweeper.lua
local resources = require("src/resources")
local minesweeper = {}

local TILES_PER_RESOLVE = 4
local SP_PER_RESOLVE = 1
local BOMBS_PER_RESOLVE = 2
local RESOLVE_TIME = 2.0

function minesweeper.init(state)
  state.minesweeper = {
    tiles_accumulated = 0,
    resolving = false,
    resolve_timer = 0,
  }
end

function minesweeper.add_tile(state)
  state.minesweeper.tiles_accumulated = state.minesweeper.tiles_accumulated + 1
  if state.minesweeper.tiles_accumulated >= TILES_PER_RESOLVE and not state.minesweeper.resolving then
    state.minesweeper.resolving = true
    state.minesweeper.resolve_timer = RESOLVE_TIME
  end
end

function minesweeper.update(dt, state)
  if not state.minesweeper.resolving then return end
  state.minesweeper.resolve_timer = state.minesweeper.resolve_timer - dt
  if state.minesweeper.resolve_timer <= 0 then
    resources.add(state, "sp", SP_PER_RESOLVE)
    resources.add(state, "bombs", BOMBS_PER_RESOLVE)
    state.minesweeper.tiles_accumulated = 0
    state.minesweeper.resolving = false
  end
end

return minesweeper
