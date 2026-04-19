-- src/jobs.lua
local jobs = {}

local job_defs = {
  lumberjack = {
    name = "Lumberjack",
    building = "tree",
    action = function(state) end,
  },
  miner = {
    name = "Miner",
    building = "rock",
    action = function(state) end,
  },
  compactor_hauler = {
    name = "Compactor Hauler",
    building = "compactor",
    action = function(state) end,
  },
  assembler_hauler = {
    name = "Assembler Hauler",
    building = "assembler",
    action = function(state) end,
  },
  truck_driver = {
    name = "Truck Driver",
    building = "loading_dock",
    action = function(state) end,
  },
  crane_operator = {
    name = "Crane Operator",
    building = "play_zone",
    action = function(state) end,
  },
}

function jobs.get(job_name)
  return job_defs[job_name]
end

function jobs.get_building(job_name)
  local job = job_defs[job_name]
  return job and job.building or nil
end

return jobs
