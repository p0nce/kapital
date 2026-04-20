-- src/buildings/rock.lua
local resources = require("src/resources")
local effects   = require("src/effects")
local sounds    = require("src/sounds")
local rock = {}

local HARVEST_RATE = 0.5  -- resources per second per worker

function rock.click(state)
  resources.add(state, "points", 1)
  if state.buildings.stone_pile.contents < state.buildings.stone_pile.cap then
    resources.add(state, "stones", 1)
    state.buildings.stone_pile.contents = state.buildings.stone_pile.contents + 1
  end
  sounds.play("mine")
  effects.shake("rock")
  local world = require("src/world")
  local c = world.get_sprite_center("rock")
  if c then effects.spawn_particles(c.x, c.y, 6, 0.6, 0.55, 0.5) end
end

function rock.init(state)
  local b = state.buildings.rock
  b.level = 1
  b.workers = {}
end

function rock.update(dt, state)
  -- harvesting is animation-driven: workers.update calls rock.click on each mine cycle
end

return rock
