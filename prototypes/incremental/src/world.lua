-- src/world.lua
local world = {}
local building_modules = {}

-- Buildings are spaced with 16px (2-tile) gaps so labels don't overlap.
-- Layout (world px): lumberyard@0 log_pile@40 tree@72 stone_pile@104
--                    rock@136 dormitory@168 compactor@208 assembler@248
--                    loading_dock@288 play_zone@328
local building_defs = {
  lumberyard = {
    name = "Lumberyard",
    x = 0, y = 0, w = 3, h = 3,
    built = false,
  },
  log_pile = {
    name = "Log pile",
    x = 40, y = 0, w = 2, h = 2,
    built = true,
  },
  tree = {
    name = "Tree",
    x = 72, y = 0, w = 2, h = 2,
    built = true,
  },
  stone_pile = {
    name = "Stone pile",
    x = 104, y = 0, w = 2, h = 2,
    built = true,
  },
  rock = {
    name = "Rock",
    x = 136, y = 0, w = 2, h = 2,
    built = true,
  },
  dormitory = {
    name = "Dormitory",
    x = 168, y = 0, w = 2, h = 3,
    built = false,
  },
  compactor = {
    name = "Compactor",
    x = 208, y = 0, w = 2, h = 2,
    built = false,
  },
  assembler = {
    name = "Assembler",
    x = 248, y = 0, w = 2, h = 2,
    built = false,
  },
  loading_dock = {
    name = "Loading Dock",
    x = 288, y = 0, w = 2, h = 2,
    built = false,
  },
  play_zone = {
    name = "Play Zone",
    x = 328, y = 0, w = 3, h = 3,
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
  local inv_zoom = 1 / state.camera.zoom
  for building_id, building in pairs(state.buildings) do
    if building.built then
      love.graphics.setColor(0.3, 0.3, 0.3)
    else
      love.graphics.setColor(0.1, 0.1, 0.1)
    end
    love.graphics.rectangle("fill", building.x, building.y, building.w * 8, building.h * 8)
    -- Render label at constant screen size regardless of zoom
    love.graphics.push()
    love.graphics.translate(building.x + 2, building.y + 2)
    love.graphics.scale(inv_zoom, inv_zoom)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(building.name, 0, 0)
    love.graphics.pop()
  end
end

function world.init_modules()
  building_modules = {
    compactor = require("src/buildings/compactor"),
    assembler = require("src/buildings/assembler"),
    loading_dock = require("src/buildings/loading_dock"),
    play_zone = require("src/buildings/play_zone"),
  }
end

function world.try_build(state, building_id)
  if building_modules[building_id] and building_modules[building_id].build then
    return building_modules[building_id].build(state)
  end
  return false
end

-- Handle click on a building: open its menu or trigger buy
-- screen_x/y for menu hit detection, world_x/y for building bounds
local MENU_X = 200
local MENU_Y = 100
local MENU_W = 300

function world.mousepressed(state, world_x, world_y, screen_x, screen_y)
  local menu = require("src/ui/menu")
  local dormitory = require("src/buildings/dormitory")

  if menu.is_open(state) then
    if menu.close_button_hit(screen_x, screen_y) then
      menu.close(state)
      return
    end
    -- Dormitory menu: Buy floor button is the first item at y_offset=40
    if menu.get_open_building(state) == "dormitory" then
      local item_y = MENU_Y + 40
      if screen_x >= MENU_X + 10 and screen_x < MENU_X + MENU_W - 10 and
         screen_y >= item_y and screen_y < item_y + 20 then
        dormitory.buy_floor(state)
      end
    end
    return
  end

  local dorm = state.buildings.dormitory
  if world_x >= dorm.x and world_x < dorm.x + dorm.w * 8 and
     world_y >= dorm.y and world_y < dorm.y + dorm.h * 8 then
    menu.open(state, "dormitory")
    return
  end
end

return world
