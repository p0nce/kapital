-- src/workers.lua
local sprites  = require("src/sprites")
local workers  = {}

local next_worker_id = 1

-- Seconds per frame for each facing state
local anim_spf = {
  idle       = 1 / 4,
  right      = 1 / 6,
  left       = 1 / 6,
  chop_right = 0.5,
  chop_left  = 0.5,
  mine_right = 0.5,
  mine_left  = 0.5,
}

function workers.spawn(state, x, y)
  local worker = {
    id = next_worker_id,
    x = x,
    y = y,
    target_x = x,
    target_y = y,
    job = nil,
    speed = 20,
    anim_timer = 0,
    anim_frame = 0,
    facing = "idle",
    at_work = false,
  }
  next_worker_id = next_worker_id + 1
  table.insert(state.workers, worker)
  return worker
end

function workers.assign(state, worker_id, job_name, target_x, target_y)
  for _, w in ipairs(state.workers) do
    if w.id == worker_id then
      w.job = job_name
      w.target_x = target_x
      w.target_y = target_y
      w.at_work = false
      return
    end
  end
end

function workers.unassign(state, worker_id, dormitory_x, dormitory_y)
  for _, w in ipairs(state.workers) do
    if w.id == worker_id then
      w.job = nil
      w.target_x = dormitory_x
      w.target_y = dormitory_y
      w.facing = "idle"
      w.at_work = false
      return
    end
  end
end

function workers.update(dt, state)
  local jobs = require("src/jobs")

  for _, w in ipairs(state.workers) do
    local dx = w.target_x - w.x
    local dy = w.target_y - w.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0.5 then
      local move_dist = w.speed * dt
      if move_dist >= dist then
        w.x = w.target_x
        w.y = w.target_y
      else
        w.x = w.x + (dx / dist) * move_dist
        w.y = w.y + (dy / dist) * move_dist
      end
      w.facing = dx >= 0 and "right" or "left"
      w.at_work = false
    else
      local job_def = w.job and jobs.get(w.job)
      if job_def and job_def.get_facing then
        w.facing = job_def.get_facing(state, w)
        w.at_work = true
      else
        w.facing = "idle"
        w.at_work = false
      end
    end

    local prev_frame = w.anim_frame
    w.anim_timer = w.anim_timer + dt
    local spf = anim_spf[w.facing] or (1 / 6)
    if w.anim_timer >= spf then
      w.anim_timer = w.anim_timer - spf
      w.anim_frame = 1 - w.anim_frame
    end

    if w.at_work and prev_frame == 0 and w.anim_frame == 1 then
      local job_def = jobs.get(w.job)
      if job_def and job_def.on_cycle then
        job_def.on_cycle(state)
      end
    end
  end
end

local anim_quads = {
  idle       = { "gubo_idle_0",       "gubo_idle_1"       },
  right      = { "gubo_right_0",      "gubo_right_1"      },
  left       = { "gubo_left_0",       "gubo_left_1"       },
  chop_right = { "gubo_chop_right_0", "gubo_chop_right_1" },
  chop_left  = { "gubo_chop_left_0",  "gubo_chop_left_1"  },
  mine_right = { "gubo_mine_right_0", "gubo_mine_right_1" },
  mine_left  = { "gubo_mine_left_0",  "gubo_mine_left_1"  },
}

function workers.draw(state)
  love.graphics.setColor(1, 1, 1)
  for _, w in ipairs(state.workers) do
    if w.job ~= nil then
      local quad_name = anim_quads[w.facing][w.anim_frame + 1]
      local atlas, quad = sprites.get_quad(quad_name)
      if atlas then
        love.graphics.draw(atlas, quad, w.x - 8, w.y - 12)
      end
    end
  end
end

return workers
