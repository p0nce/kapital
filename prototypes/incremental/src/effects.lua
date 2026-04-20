-- src/effects.lua
local effects = {}

local shakes    = {}
local particles = {}

local SHAKE_DURATION  = 0.25
local SHAKE_INTENSITY = 2.5

function effects.shake(building_id)
  shakes[building_id] = SHAKE_DURATION
end

function effects.get_shake_offset(building_id)
  if not shakes[building_id] then return 0, 0 end
  local t   = shakes[building_id] / SHAKE_DURATION
  local amp = SHAKE_INTENSITY * t
  return (math.random() * 2 - 1) * amp, (math.random() * 2 - 1) * amp
end

function effects.spawn_particles(x, y, count, r, g, b)
  for _ = 1, count do
    local angle = math.random() * math.pi * 2
    local speed = math.random(15, 45)
    local life  = 0.4 + math.random() * 0.3
    table.insert(particles, {
      x = x, y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed - 40,
      life = life, max_life = life,
      r = r, g = g, b = b,
    })
  end
end

function effects.update(dt)
  for id, t in pairs(shakes) do
    shakes[id] = t - dt
    if shakes[id] <= 0 then shakes[id] = nil end
  end
  for i = #particles, 1, -1 do
    local p = particles[i]
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(particles, i)
    else
      p.x  = p.x  + p.vx * dt
      p.y  = p.y  + p.vy * dt
      p.vy = p.vy + 120 * dt
    end
  end
end

function effects.draw_particles()
  for _, p in ipairs(particles) do
    local alpha = p.life / p.max_life
    love.graphics.setColor(p.r, p.g, p.b, alpha)
    love.graphics.rectangle("fill", p.x - 1, p.y - 1, 2, 2)
  end
end

return effects
