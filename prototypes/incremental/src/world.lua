-- src/world.lua
local world = {}
local building_modules = {}
local sprites = require("src/sprites")

-- All buildings use the same house sprite: 56x32 px (7x4 tiles).
-- Spaced with 8px gaps. Layout origin x values: 0, 64, 128, 192, 256, 320, 384, 448, 512, 576
local building_defs = {
  lumberyard   = { name = "Lumberyard",   x = 0,   y = 0, w = 7, h = 4, built = false },
  log_pile     = { name = "Log pile",     x = 56,  y = 0, w = 9, h = 1, built = true  },
  tree         = { name = "Tree",         x = 128, y = 0, w = 7, h = 4, built = true  },
  stone_pile   = { name = "Stone pile",   x = 184, y = 0, w = 9, h = 1, built = true  },
  rock         = { name = "Mine",         x = 256, y = 0, w = 7, h = 4, built = true  },
  dormitory    = { name = "Dormitory",    x = 320, y = 0, w = 7, h = 4, built = false },
  compactor    = { name = "Compactor",    x = 384, y = 0, w = 7, h = 4, built = false },
  assembler    = { name = "Assembler",    x = 448, y = 0, w = 7, h = 4, built = false },
  loading_dock = { name = "Loading Dock", x = 512, y = 0, w = 7, h = 4, built = false },
  play_zone    = { name = "Play Zone",    x = 576, y = 0, w = 7, h = 4, built = false },
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

local GROUND_Y = 32  -- world y where ground surface sits

function world.draw(state)
  local inv_zoom = 1 / state.camera.zoom
  local font = love.graphics.getFont()

  -- Draw ground strip
  local ground_atlas, ground_quad = sprites.get_quad("ground")
  if ground_atlas and ground_quad then
    love.graphics.setColor(1, 1, 1)
    local x = -1000
    while x < 900 do
      love.graphics.draw(ground_atlas, ground_quad, x, GROUND_Y)
      x = x + 8
    end
  end

  -- Per-building sprite overrides; falls back to house quad
  local sprite_map = {
    tree = "tree",
  }
  -- Composite sprites: list of {quad_name, x_offset}
  local composite_map = {
    rock = { {"rock_left", 0}, {"rock_right", 8} },
  }
  -- Tile strip sprites: {quad_name, count} — drawn as N horizontal repetitions
  local tile_strip_map = {
    log_pile   = { quad_name = "log_pile_tile",   count = 9, y_offset = 8 },
    stone_pile = { quad_name = "stone_pile_tile", count = 9, y_offset = 8 },
  }

  for building_id, building in pairs(state.buildings) do
    if not building.built then goto continue end

    local bw, bh, draw_y

    if tile_strip_map[building_id] then
      local strip = tile_strip_map[building_id]
      bw, bh = strip.count * 8, 8
      draw_y = GROUND_Y - bh + (strip.y_offset or 0)
      local satlas, squad = sprites.get_quad(strip.quad_name)
      if satlas then
        love.graphics.setColor(1, 1, 1)
        for i = 0, strip.count - 1 do
          love.graphics.draw(satlas, squad, building.x + i * 8, draw_y)
        end
      end
    elseif composite_map[building_id] then
      bw, bh = 24, 8
      draw_y = GROUND_Y - bh
      love.graphics.setColor(1, 1, 1)
      for _, part in ipairs(composite_map[building_id]) do
        local patlas, pquad = sprites.get_quad(part[1])
        if patlas then
          love.graphics.draw(patlas, pquad, building.x + part[2], draw_y)
        end
      end
    else
      local sprite_name = sprite_map[building_id] or "house"
      local batlas, quad = sprites.get_quad(sprite_name)
      local qx, qy
      qx, qy, bw, bh = quad:getViewport()
      draw_y = GROUND_Y - bh
      if batlas then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(batlas, quad, building.x, draw_y)
      else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", building.x, draw_y, bw, bh)
      end
    end

    -- Labels suppressed for storage piles (their role is visually obvious)
    local no_label = { log_pile = true, stone_pile = true }
    if no_label[building_id] then goto continue end

    -- Label centered above the building, constant screen size
    love.graphics.push()
    local text_w = font:getWidth(building.name)
    local text_h = font:getHeight()
    local cx = building.x + bw / 2 - (text_w * inv_zoom) / 2
    love.graphics.translate(cx, draw_y - text_h * inv_zoom - 2)
    love.graphics.scale(inv_zoom, inv_zoom)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(building.name, 1, 1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(building.name, 0, 0)
    love.graphics.pop()

    ::continue::
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
