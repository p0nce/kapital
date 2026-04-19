-- src/state.lua
local state = {
  time = 0,
  resources = {
    points = 0,
    wood = 0,
    stones = 0,
    blocks = 0,
    tiles = 0,
    sp = 0,
    bombs = 0,
  },
  buildings = {},  -- Will be populated by world.lua
  workers = {},    -- Will be populated by workers.lua
  camera = {
    x = 0,
    y = 0,
    zoom = 2,  -- 2x zoom = 16px per 8px sprite
  },
  ui = {
    open_menu = nil,  -- Building ID of open menu, or nil
  },
}

function state.update(dt)
  state.time = state.time + dt
end

return state
