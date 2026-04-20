-- src/ui/menu.lua
local menu = {}

local MENU_SW = 180
local ITEM_SH = 20
local HEAD_SH = 4
local PAD_S   = 6

function menu.open(state, building_id)
  state.ui.open_menu = building_id
end

function menu.close(state)
  state.ui.open_menu = nil
end

function menu.is_open(state)
  return state.ui.open_menu ~= nil
end

function menu.get_open_building(state)
  return state.ui.open_menu
end

local function menu_world_pos(building, inv_zoom)
  local world  = require("src/world")
  local font   = love.graphics.getFont()
  local text_h = font:getHeight()
  local mx = building.x + building.w * 4 - MENU_SW / 2 * inv_zoom
  local my = world.get_ground_y() + (text_h + 6) * inv_zoom + 16
  return mx, my
end

local function menu_row_count(open, building)
  local jobs = require("src/jobs")
  if open == "dormitory" then return 2 end
  local rows = 0
  if not building.built and building.build_costs then rows = rows + 1 end
  local job_name = jobs.get_for_building(open)
  if building.built and job_name then rows = rows + 1 end
  return rows
end

local function building_has_menu(state, building_id)
  if building_id == "dormitory" then return true end
  local jobs = require("src/jobs")
  local job_name = jobs.get_for_building(building_id)
  if job_name then return true end
  local b = state.buildings[building_id]
  return b and b.build_costs ~= nil
end

function menu.draw(state)
  local jobs     = require("src/jobs")
  local dorm_mod = require("src/buildings/dormitory")
  local res_mod  = require("src/resources")

  local open = menu.get_open_building(state)
  if not open then return end
  local building = state.buildings[open]
  if not building then return end

  local inv_zoom = 1 / state.camera.zoom
  local rows     = menu_row_count(open, building)
  local panel_sh = HEAD_SH + rows * ITEM_SH + PAD_S
  local mx, my   = menu_world_pos(building, inv_zoom)

  love.graphics.push()
  love.graphics.translate(mx, my)
  love.graphics.scale(inv_zoom, inv_zoom)

  love.graphics.setColor(0.15, 0.15, 0.15)
  love.graphics.rectangle("fill", 0, 0, MENU_SW, panel_sh)
  love.graphics.setColor(0.55, 0.55, 0.55)
  love.graphics.rectangle("line", 0, 0, MENU_SW, panel_sh)
  love.graphics.setColor(0.35, 0.35, 0.35)
  love.graphics.line(0, HEAD_SH, MENU_SW, HEAD_SH)

  local row = 0
  if open == "dormitory" then
    local cost = dorm_mod.floor_cost(state.buildings.dormitory.floors)
    local ok   = res_mod.can_afford(state, "points", cost)
    love.graphics.setColor(ok and 1 or 0.4, ok and 1 or 0.4, ok and 1 or 0.4)
    love.graphics.print(string.format("Buy floor (+2): %d pts", cost), PAD_S, HEAD_SH + row * ITEM_SH + 3)
    row = row + 1
    love.graphics.setColor(0.55, 0.55, 0.55)
    love.graphics.print(string.format("Idle workers: %d", #state.buildings.dormitory.workers_idle), PAD_S, HEAD_SH + row * ITEM_SH + 3)
  else
    if not building.built and building.build_costs then
      local c  = building.build_costs
      local ok = res_mod.can_afford(state, "points", c.points) and res_mod.can_afford(state, "wood", c.wood)
      love.graphics.setColor(ok and 1 or 0.4, ok and 1 or 0.4, ok and 1 or 0.4)
      love.graphics.print(string.format("Build: %d pts, %d wood", c.points, c.wood), PAD_S, HEAD_SH + row * ITEM_SH + 3)
      row = row + 1
    end
    local job_name, job_def = jobs.get_for_building(open)
    if building.built and job_name then
      local count = building.workers and #building.workers or 0
      local idle  = #state.buildings.dormitory.workers_idle
      local iy    = HEAD_SH + row * ITEM_SH + 3
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(job_def.label .. ":", PAD_S, iy)
      love.graphics.setColor(count > 0 and 1 or 0.4, count > 0 and 1 or 0.4, count > 0 and 1 or 0.4)
      love.graphics.print("<", 112, iy)
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(tostring(count), 126, iy)
      love.graphics.setColor(idle > 0 and 1 or 0.4, idle > 0 and 1 or 0.4, idle > 0 and 1 or 0.4)
      love.graphics.print(">", 148, iy)
    end
  end

  love.graphics.pop()
end

function menu.mousepressed(state, world_x, world_y, screen_x, screen_y)
  local world    = require("src/world")
  local jobs     = require("src/jobs")
  local dorm_mod = require("src/buildings/dormitory")

  if menu.is_open(state) then
    local open     = menu.get_open_building(state)
    local building = state.buildings[open]
    local zoom     = state.camera.zoom
    local inv_zoom = 1 / zoom
    local mx, my   = menu_world_pos(building, inv_zoom)
    local rel_sx   = (world_x - mx) * zoom
    local rel_sy   = (world_y - my) * zoom
    local rows     = menu_row_count(open, building)
    local panel_sh = HEAD_SH + rows * ITEM_SH + PAD_S

    if rel_sx >= 0 and rel_sx < MENU_SW and rel_sy >= 0 and rel_sy < panel_sh then
      local row = 0
      if open == "dormitory" then
        if rel_sy >= HEAD_SH and rel_sy < HEAD_SH + ITEM_SH then
          dorm_mod.buy_floor(state)
        end
      else
        if not building.built and building.build_costs then
          if rel_sy >= HEAD_SH + row * ITEM_SH and rel_sy < HEAD_SH + (row + 1) * ITEM_SH then
            world.try_build(state, open)
          end
          row = row + 1
        end
        local job_name = jobs.get_for_building(open)
        if building.built and job_name then
          local iy0 = HEAD_SH + row * ITEM_SH
          if rel_sy >= iy0 and rel_sy < iy0 + ITEM_SH then
            if rel_sx >= 112 and rel_sx < 128 then
              if building.workers and #building.workers > 0 then
                dorm_mod.unassign_worker(state, open, building.workers[#building.workers])
              end
            elseif rel_sx >= 148 and rel_sx < 164 then
              dorm_mod.hire_worker_for_job(state, job_name)
            end
          end
        end
      end
      return
    end

    -- Click outside panel: title buttons toggle or switch menus
    local label_bounds = world.get_label_bounds()
    for building_id, bounds in pairs(label_bounds) do
      if building_has_menu(state, building_id) and
         screen_x >= bounds.x and screen_x < bounds.x + bounds.w and
         screen_y >= bounds.y and screen_y < bounds.y + bounds.h then
        if menu.get_open_building(state) == building_id then
          menu.close(state)
        else
          menu.open(state, building_id)
        end
        return
      end
    end
    return
  end

  -- No menu open: title button clicks open building menus
  local label_bounds = world.get_label_bounds()
  for building_id, bounds in pairs(label_bounds) do
    if building_has_menu(state, building_id) and
       screen_x >= bounds.x and screen_x < bounds.x + bounds.w and
       screen_y >= bounds.y and screen_y < bounds.y + bounds.h then
      menu.open(state, building_id)
      return
    end
  end
end

return menu
