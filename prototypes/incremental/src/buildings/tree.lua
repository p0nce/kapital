-- src/buildings/tree.lua
local resources = require("src/resources")
local effects   = require("src/effects")
local sounds    = require("src/sounds")
local tree = {}

local HARVEST_RATE = 0.5  -- resources per second per worker

function tree.click(state)
  resources.add(state, "points", 1)
  if state.buildings.log_pile.contents < state.buildings.log_pile.cap then
    resources.add(state, "wood", 1)
    state.buildings.log_pile.contents = state.buildings.log_pile.contents + 1
  end
  sounds.play("axe")
  effects.shake("tree")
  local world = require("src/world")
  local c = world.get_sprite_center("tree")
  if c then effects.spawn_particles(c.x, c.y, 6, 0.2, 0.75, 0.15) end
end

function tree.init(state)
  local b = state.buildings.tree
  b.level = 1
  b.workers = {}
end

function tree.update(dt, state)
  -- harvesting is animation-driven: workers.update calls tree.click on each chop cycle
end

return tree
