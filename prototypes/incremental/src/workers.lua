-- src/workers.lua
local workers = {}

local next_worker_id = 1

function workers.spawn(state, x, y)
  local worker = {
    id = next_worker_id,
    x = x,
    y = y,
    target_x = x,
    target_y = y,
    job = nil,
    speed = 20,
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
      return
    end
  end
end

function workers.update(dt, state)
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
    end
  end
end

function workers.draw(state)
  love.graphics.setColor(1, 0.8, 0)
  for _, w in ipairs(state.workers) do
    love.graphics.circle("fill", w.x + 4, w.y + 4, 2)
  end
end

return workers
