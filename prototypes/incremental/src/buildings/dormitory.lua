-- src/buildings/dormitory.lua
local resources = require("src/resources")
local workers = require("src/workers")
local jobs = require("src/jobs")
local dormitory = {}

local COST_BASE = 10
local COST_MULT = 1.5

function dormitory.floor_cost(floor_number)
  return math.floor(COST_BASE * (COST_MULT ^ floor_number))
end

function dormitory.init(state)
  local building = state.buildings.dormitory
  building.floors = 0
  building.workers_idle = {}
end

function dormitory.buy_floor(state)
  local cost = dormitory.floor_cost(state.buildings.dormitory.floors)
  if not resources.can_afford(state, "points", cost) then
    return false
  end
  resources.spend(state, "points", cost)
  state.buildings.dormitory.floors = state.buildings.dormitory.floors + 1
  state.buildings.dormitory.built = true
  local dorm = state.buildings.dormitory
  local w1 = workers.spawn(state, dorm.x + 4, dorm.y + 4)
  local w2 = workers.spawn(state, dorm.x + 4, dorm.y + 4)
  table.insert(dorm.workers_idle, w1.id)
  table.insert(dorm.workers_idle, w2.id)
  return true
end

function dormitory.hire_worker_for_job(state, job_name)
  if #state.buildings.dormitory.workers_idle == 0 then return false end
  local worker_id = table.remove(state.buildings.dormitory.workers_idle)
  local building_id = jobs.get_building(job_name)
  local dorm = state.buildings.dormitory
  local world = require("src/world")
  local ground_y = world.get_ground_y()
  local door_x = dorm.x + dorm.w * 4
  local door_y = ground_y
  for _, w in ipairs(state.workers) do
    if w.id == worker_id then
      w.x = door_x
      w.y = door_y
      break
    end
  end
  if building_id then
    local building = state.buildings[building_id]
    local slot = #building.workers  -- 0-based slot index before insert
    table.insert(building.workers, worker_id)
    local sign = (slot % 2 == 0) and 1 or -1
    local spread = sign * math.ceil(slot / 2) * 10
    workers.assign(state, worker_id, job_name, jobs.get_work_x(job_name, building) + spread, door_y)
  end
  return true
end

function dormitory.unassign_worker(state, building_id, worker_id)
  local building = state.buildings[building_id]
  for i, wid in ipairs(building.workers) do
    if wid == worker_id then
      table.remove(building.workers, i)
      table.insert(state.buildings.dormitory.workers_idle, worker_id)
      local dorm = state.buildings.dormitory
      local world = require("src/world")
      workers.unassign(state, worker_id, dorm.x + dorm.w * 4, world.get_ground_y() - 4)
      return true
    end
  end
  return false
end

function dormitory.menu_items(state)
  local cost = dormitory.floor_cost(state.buildings.dormitory.floors)
  local affordable = resources.can_afford(state, "points", cost)
  return {
    { label = string.format("Buy floor (+2 workers): %d pts", cost), affordable = affordable },
    { label = string.format("Idle workers: %d", #state.buildings.dormitory.workers_idle), affordable = true },
  }
end

return dormitory
