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

local MENU_X = 200
local MENU_Y = 100
local MENU_W = 300

-- Per-building menu configuration
local menu_configs = {
  tree         = { title = "Tree",         job_name = "lumberjack",       job_label = "Lumberjacks"    },
  rock         = { title = "Mine",         job_name = "miner",            job_label = "Miners"         },
  dormitory    = { title = "Dormitory" },
  compactor    = { title = "Compactor",    job_name = "compactor_hauler", job_label = "Haulers",
                   build_costs = { points = 50,  wood = 20 } },
  assembler    = { title = "Assembler",    job_name = "assembler_hauler", job_label = "Haulers",
                   build_costs = { points = 75,  wood = 30 } },
  loading_dock = { title = "Loading Dock", job_name = "truck_driver",     job_label = "Truck Drivers",
                   build_costs = { points = 100, wood = 40 } },
  play_zone    = { title = "Play Zone",    job_name = "crane_operator",   job_label = "Crane Operators",
                   build_costs = { points = 150, wood = 50 } },
}

function world.draw_menu(state)
  local menu        = require("src/ui/menu")
  local dorm_mod    = require("src/buildings/dormitory")
  local resources   = require("src/resources")

  local open = menu.get_open_building(state)
  if not open then return end
  local cfg = menu_configs[open]
  if not cfg then return end

  menu.draw_header(cfg.title)
  local y = 40

  if open == "dormitory" then
    local cost      = dorm_mod.floor_cost(state.buildings.dormitory.floors)
    local affordable = resources.can_afford(state, "points", cost)
    menu.draw_item(y, string.format("Buy floor (+2 workers): %d pts", cost), affordable)
    y = y + 25
    menu.draw_item(y, string.format("Idle workers: %d", #state.buildings.dormitory.workers_idle), true)
  else
    local building = state.buildings[open]

    if not building.built and cfg.build_costs then
      local costs      = cfg.build_costs
      local affordable = resources.can_afford(state, "points", costs.points) and
                         resources.can_afford(state, "wood",   costs.wood)
      menu.draw_item(y, string.format("Build: %d pts, %d wood", costs.points, costs.wood), affordable)
      y = y + 25
    end

    if building.built and cfg.job_name then
      local count = building.workers and #building.workers or 0
      local idle  = #state.buildings.dormitory.workers_idle

      love.graphics.setColor(1, 1, 1)
      love.graphics.print(cfg.job_label .. ":", MENU_X + 10, MENU_Y + y)

      if count > 0 then love.graphics.setColor(1, 1, 1) else love.graphics.setColor(0.4, 0.4, 0.4) end
      love.graphics.print("<", MENU_X + 140, MENU_Y + y)

      love.graphics.setColor(1, 1, 1)
      love.graphics.print(tostring(count), MENU_X + 155, MENU_Y + y)

      if idle > 0 then love.graphics.setColor(1, 1, 1) else love.graphics.setColor(0.4, 0.4, 0.4) end
      love.graphics.print(">", MENU_X + 175, MENU_Y + y)
    end
  end
end

function world.mousepressed(state, world_x, world_y, screen_x, screen_y)
  local menu     = require("src/ui/menu")
  local dorm_mod = require("src/buildings/dormitory")

  if menu.is_open(state) then
    if menu.close_button_hit(screen_x, screen_y) then
      menu.close(state)
      return
    end

    local open = menu.get_open_building(state)
    local cfg  = menu_configs[open]

    if open == "dormitory" then
      local item_y = MENU_Y + 40
      if screen_x >= MENU_X + 10 and screen_x < MENU_X + MENU_W - 10 and
         screen_y >= item_y and screen_y < item_y + 20 then
        dorm_mod.buy_floor(state)
      end
    elseif cfg then
      local building = state.buildings[open]

      if not building.built and cfg.build_costs then
        local item_y = MENU_Y + 40
        if screen_x >= MENU_X + 10 and screen_x < MENU_X + MENU_W - 10 and
           screen_y >= item_y and screen_y < item_y + 20 then
          if building_modules[open] and building_modules[open].build then
            building_modules[open].build(state)
          end
        end
      end

      if building.built and cfg.job_name then
        local worker_y = MENU_Y + 40
        -- Left arrow "<" unassigns a worker
        if screen_x >= MENU_X + 140 and screen_x < MENU_X + 157 and
           screen_y >= worker_y and screen_y < worker_y + 20 then
          if building.workers and #building.workers > 0 then
            local wid = building.workers[#building.workers]
            dorm_mod.unassign_worker(state, open, wid)
          end
        end
        -- Right arrow ">" hires a worker
        if screen_x >= MENU_X + 175 and screen_x < MENU_X + 192 and
           screen_y >= worker_y and screen_y < worker_y + 20 then
          dorm_mod.hire_worker_for_job(state, cfg.job_name)
        end
      end
    end
    return
  end

  -- Open menu for buildings other than tree/rock (those are handled in input.lua)
  for building_id, _ in pairs(menu_configs) do
    if building_id ~= "tree" and building_id ~= "rock" then
      local b = state.buildings[building_id]
      if b and world_x >= b.x and world_x < b.x + b.w * 8 and
               world_y >= b.y and world_y < b.y + b.h * 8 then
        menu.open(state, building_id)
        return
      end
    end
  end
end

return world
