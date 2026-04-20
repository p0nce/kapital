-- src/jobs.lua
local jobs = {}

local job_defs = {
  lumberjack = {
    name     = "Lumberjack",
    label    = "Lumberjacks",
    building = "tree",
    work_x   = 16,
    get_facing = function(state, w)
      local cx = state.buildings.tree.x + 4
      return cx > w.x and "chop_right" or "chop_left"
    end,
    on_cycle = function(state)
      require("src/buildings/tree").click(state)
    end,
  },
  miner = {
    name     = "Miner",
    label    = "Miners",
    building = "rock",
    work_x   = 28,
    get_facing = function(state, w)
      local cx = state.buildings.rock.x + 12
      return cx > w.x and "mine_right" or "mine_left"
    end,
    on_cycle = function(state)
      require("src/buildings/rock").click(state)
    end,
  },
  compactor_hauler = {
    name     = "Compactor Hauler",
    label    = "Haulers",
    building = "compactor",
  },
  assembler_hauler = {
    name     = "Assembler Hauler",
    label    = "Haulers",
    building = "assembler",
  },
  truck_driver = {
    name     = "Truck Driver",
    label    = "Truck Drivers",
    building = "loading_dock",
  },
  crane_operator = {
    name     = "Crane Operator",
    label    = "Crane Operators",
    building = "play_zone",
  },
}

-- Reverse lookup: building_id → job_name
local building_to_job = {}
for job_name, def in pairs(job_defs) do
  if def.building then
    building_to_job[def.building] = job_name
  end
end

function jobs.get(job_name)
  return job_defs[job_name]
end

function jobs.get_building(job_name)
  local job = job_defs[job_name]
  return job and job.building or nil
end

function jobs.get_for_building(building_id)
  local job_name = building_to_job[building_id]
  if not job_name then return nil, nil end
  return job_name, job_defs[job_name]
end

function jobs.get_work_x(job_name, building)
  local job = job_defs[job_name]
  if job and job.work_x then
    return building.x + job.work_x
  end
  return building.x + building.w * 4
end

return jobs
