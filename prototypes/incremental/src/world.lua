-- src/world.lua
local world = {}
local building_modules = {}
local label_bounds    = {}  -- screen-space rects per building, refreshed each draw
local sprite_centers  = {}  -- world-space sprite centers, refreshed each draw
local sprites  = require("src/sprites")
local effects  = require("src/effects")
local screen   = require("src/screen")

-- All buildings use the same house sprite: 56x32 px (7x4 tiles).
-- Spaced with 8px gaps. Layout origin x values: 0, 64, 128, 192, 256, 320, 384, 448, 512, 576
local building_defs = {
  lumberyard   = { name = "Lumberyard",   x = 0,   y = 0, w = 7, h = 4, built = false,
                   build_costs = { points = 100 } },
  log_pile     = { name = "Log pile",     x = 56,  y = 0, w = 9, h = 1, built = true  },
  tree         = { name = "Tree",         x = 128, y = 0, w = 7, h = 4, built = true  },
  stone_pile   = { name = "Stone pile",   x = 184, y = 0, w = 9, h = 1, built = true  },
  rock         = { name = "Mine",         x = 256, y = 0, w = 7, h = 4, built = true  },
  dormitory    = { name = "Dormitory",    x = 320, y = 0, w = 7, h = 4, built = true  },
  compactor    = { name = "Compactor",    x = 384, y = 0, w = 7, h = 4, built = false,
                   build_costs = { points = 50,  wood = 20 } },
  assembler    = { name = "Assembler",    x = 448, y = 0, w = 7, h = 4, built = false,
                   build_costs = { points = 75,  wood = 30 } },
  loading_dock = { name = "Loading Dock", x = 512, y = 0, w = 7, h = 4, built = false,
                   build_costs = { points = 100, wood = 40 } },
  play_zone    = { name = "Play Zone",    x = 576, y = 0, w = 7, h = 4, built = false,
                   build_costs = { points = 150, wood = 50 } },
}

function world.init(state)
  for building_id, def in pairs(building_defs) do
    state.buildings[building_id] = {
      name        = def.name,
      x           = def.x,
      y           = def.y,
      w           = def.w,
      h           = def.h,
      built       = def.built,
      build_costs = def.build_costs,
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
  label_bounds   = {}
  sprite_centers = {}
  local inv_zoom = 1 / state.camera.zoom
  local zoom     = state.camera.zoom
  local font     = love.graphics.getFont()

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

  local sprite_map = { tree = "tree" }
  local composite_map = {
    rock = { {"rock_left", 0}, {"rock_right", 8} },
  }
  local tile_strip_map = {
    log_pile   = { quad_name = "log_pile_tile",   count = 9, y_offset = 8 },
    stone_pile = { quad_name = "stone_pile_tile", count = 9, y_offset = 8 },
  }
  local no_label = { log_pile = true, stone_pile = true }

  for building_id, building in pairs(state.buildings) do
    if not building.built then goto continue end

    local bw, bh, draw_y
    local scx, scy  -- visual center of the drawn sprite

    -- Sprite drawing with shake offset
    local ox, oy = effects.get_shake_offset(building_id)
    love.graphics.push()
    love.graphics.translate(ox, oy)

    if building_id == "dormitory" then
      local floors = building.floors or 1
      bw = 56
      bh = (3 + floors) * 8  -- chimney + roof + floors×windows + door
      draw_y = GROUND_Y - bh
      local ac, qc = sprites.get_quad("dorm_row_chimney")
      local _,  qr = sprites.get_quad("dorm_row_roof")
      local _,  qw = sprites.get_quad("dorm_row_windows")
      local _,  qf = sprites.get_quad("dorm_row_floor")
      if ac then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(ac, qc, building.x, draw_y)
        love.graphics.draw(ac, qr, building.x, draw_y + 8)
        for i = 1, floors do
          love.graphics.draw(ac, qw, building.x, draw_y + 8 + i * 8)
        end
        love.graphics.draw(ac, qf, building.x, draw_y + bh - 8)
      else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", building.x, draw_y, bw, bh)
      end
      scx = building.x + bw / 2
      scy = draw_y + bh / 2
    elseif tile_strip_map[building_id] then
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
      scx = building.x + bw / 2
      scy = draw_y + bh / 2
    elseif composite_map[building_id] then
      local parts = composite_map[building_id]
      bw, bh = 24, 8
      draw_y = GROUND_Y - bh
      love.graphics.setColor(1, 1, 1)
      for _, part in ipairs(parts) do
        local patlas, pquad = sprites.get_quad(part[1])
        if patlas then
          love.graphics.draw(patlas, pquad, building.x + part[2], draw_y)
        end
      end
      scx = building.x + #parts * 4   -- center of drawn tiles (2*8px / 2 = 8)
      scy = draw_y + bh / 2
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
      scx = building.x + bw / 2
      scy = draw_y + bh / 2
    end

    love.graphics.pop()  -- shake ends here; label below is NOT shaken
    sprite_centers[building_id] = { x = scx, y = scy }

    -- Label / title button (no shake)
    if not no_label[building_id] then
      love.graphics.push()
      local text_w  = font:getWidth(building.name)
      local text_h  = font:getHeight()
      local cx      = building.x + bw / 2 - (text_w * inv_zoom) / 2
      local label_y = GROUND_Y + 10
      local px, py  = 4, 2

      local sx = (cx - state.camera.x) * zoom + screen.w() / 2
      local sy = (label_y - state.camera.y) * zoom + screen.h() / 2
      label_bounds[building_id] = {
        x = sx - px, y = sy - py,
        w = text_w + px * 2, h = text_h + py * 2,
      }

      love.graphics.translate(cx, label_y)
      love.graphics.scale(inv_zoom, inv_zoom)

      love.graphics.setColor(0.18, 0.18, 0.18)
      love.graphics.rectangle("fill", -px, -py, text_w + px * 2, text_h + py * 2)
      love.graphics.setColor(0.5, 0.5, 0.5)
      love.graphics.rectangle("line", -px, -py, text_w + px * 2, text_h + py * 2)

      love.graphics.setColor(0, 0, 0)
      love.graphics.print(building.name, 1, 1)
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(building.name, 0, 0)
      love.graphics.pop()
    end

    ::continue::
  end

  effects.draw_particles()
end

-- Returns buildings with build_costs in world-x order, regardless of built state
local purchasable_order = { "lumberyard", "compactor", "assembler", "loading_dock", "play_zone" }
function world.get_purchasable(state)
  local list = {}
  for _, id in ipairs(purchasable_order) do
    local b = state.buildings[id]
    if b and b.build_costs then
      table.insert(list, { id = id, building = b })
    end
  end
  return list
end

function world.get_ground_y()
  return GROUND_Y
end

function world.get_label_bounds()
  return label_bounds
end

function world.get_sprite_center(building_id)
  return sprite_centers[building_id]
end

function world.init_modules()
  building_modules = {
    lumberyard   = require("src/buildings/lumberyard"),
    compactor    = require("src/buildings/compactor"),
    assembler    = require("src/buildings/assembler"),
    loading_dock = require("src/buildings/loading_dock"),
    play_zone    = require("src/buildings/play_zone"),
  }
end

function world.try_build(state, building_id)
  if building_modules[building_id] and building_modules[building_id].build then
    return building_modules[building_id].build(state)
  end
  return false
end

return world
