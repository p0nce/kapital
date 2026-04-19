-- src/world.lua
local world = {}

local building_defs = {
  lumberyard = {
    name = "Lumberyard",
    x = 0, y = 0, w = 3, h = 3,
    built = false,
  },
  log_pile = {
    name = "Log pile",
    x = 24, y = 0, w = 2, h = 2,
    built = true,
  },
  tree = {
    name = "Tree",
    x = 40, y = 0, w = 2, h = 2,
    built = true,
  },
  stone_pile = {
    name = "Stone pile",
    x = 56, y = 0, w = 2, h = 2,
    built = true,
  },
  rock = {
    name = "Rock",
    x = 72, y = 0, w = 2, h = 2,
    built = true,
  },
  dormitory = {
    name = "Dormitory",
    x = 88, y = 0, w = 2, h = 3,
    built = false,
  },
  compactor = {
    name = "Compactor",
    x = 104, y = 0, w = 2, h = 2,
    built = false,
  },
  assembler = {
    name = "Assembler",
    x = 120, y = 0, w = 2, h = 2,
    built = false,
  },
  loading_dock = {
    name = "Loading Dock",
    x = 136, y = 0, w = 2, h = 2,
    built = false,
  },
  play_zone = {
    name = "Play Zone",
    x = 152, y = 0, w = 3, h = 3,
    built = false,
  },
}

function world.init(state)
  for building_id, def in pairs(building_defs) do
    state.buildings[building_id] = {
      name = def.name,
      x = def.x,
      y = def.y,
      w = def.w,
      h = def.h,
      built = def.built,
    }
  end
end

function world.get_building(state, building_id)
  return state.buildings[building_id]
end

function world.build(state, building_id)
  if state.buildings[building_id] then
    state.buildings[building_id].built = true
  end
end

function world.draw(state)
  for building_id, building in pairs(state.buildings) do
    if building.built then
      love.graphics.setColor(0.3, 0.3, 0.3)
    else
      love.graphics.setColor(0.1, 0.1, 0.1)
    end
    love.graphics.rectangle("fill", building.x, building.y, building.w * 8, building.h * 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(building.name, building.x + 2, building.y + 2)
  end
end

return world
