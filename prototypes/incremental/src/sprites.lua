-- src/sprites.lua
local sprites = {}

local atlases = {}
local quads = {}

function sprites.load()
  local buildings = love.graphics.newImage("Tilesets/Chroma-Noir-8x8/Buildings.png")
  buildings:setFilter("nearest", "nearest")
  local bw, bh = buildings:getDimensions()
  atlases.buildings = buildings

  -- House sprite at (0, 32), 7x4 tiles = 56x32 px
  quads.house = { atlas = buildings, q = love.graphics.newQuad(0, 32, 56, 32, bw, bh) }
  -- Tree sprite at (120, 80), 1x2 tiles = 8x16 px
  quads.tree       = { atlas = buildings, q = love.graphics.newQuad(120, 80,  8, 16, bw, bh) }

  local underground = love.graphics.newImage("Tilesets/Chroma-Noir-8x8/Underground.png")
  underground:setFilter("nearest", "nearest")
  local uw, uh = underground:getDimensions()
  atlases.underground = underground

  -- Ground tile at (8, 72), 1x1 tile = 8x8 px
  quads.ground          = { atlas = underground, q = love.graphics.newQuad(  8,  72,  8,  8, uw, uh) }
  -- Log pile tile at (8, 240), 1x1 tile = 8x8 px
  quads.log_pile_tile   = { atlas = underground, q = love.graphics.newQuad(  8, 240,  8,  8, uw, uh) }
  -- Stone pile tile at (8, 0), 1x1 tile = 8x8 px
  quads.stone_pile_tile = { atlas = underground, q = love.graphics.newQuad(  8,   0,  8,  8, uw, uh) }
  -- Rock: two quads from Underground.png → 3x1 tiles = 24x8 px total
  quads.rock_left  = { atlas = underground, q = love.graphics.newQuad( 88, 16,  8,  8, uw, uh) }
  quads.rock_right = { atlas = underground, q = love.graphics.newQuad(104, 16, 16,  8, uw, uh) }

  local gubos = love.graphics.newImage("Tilesets/gubos.png")
  gubos:setFilter("nearest", "nearest")
  local gw, gh = gubos:getDimensions()
  atlases.gubos = gubos
  -- Row 0: idle (2 frames), Row 1: walk right (2 frames), Row 2: walk left (2 frames)
  -- Each tile is 16x16 px; gubo character sits in ~(4,6)-(11,11), ground floor at row 12
  quads.gubo_idle_0  = { atlas = gubos, q = love.graphics.newQuad(  0,  0, 16, 16, gw, gh) }
  quads.gubo_idle_1  = { atlas = gubos, q = love.graphics.newQuad( 16,  0, 16, 16, gw, gh) }
  quads.gubo_right_0 = { atlas = gubos, q = love.graphics.newQuad(  0, 16, 16, 16, gw, gh) }
  quads.gubo_right_1 = { atlas = gubos, q = love.graphics.newQuad( 16, 16, 16, 16, gw, gh) }
  quads.gubo_left_0  = { atlas = gubos, q = love.graphics.newQuad(  0, 32, 16, 16, gw, gh) }
  quads.gubo_left_1  = { atlas = gubos, q = love.graphics.newQuad( 16, 32, 16, 16, gw, gh) }
  -- Row 3: axe swing, tree to the right; Row 4: axe swing, tree to the left
  quads.gubo_chop_right_0 = { atlas = gubos, q = love.graphics.newQuad(  0, 48, 16, 16, gw, gh) }
  quads.gubo_chop_right_1 = { atlas = gubos, q = love.graphics.newQuad( 16, 48, 16, 16, gw, gh) }
  quads.gubo_chop_left_0  = { atlas = gubos, q = love.graphics.newQuad(  0, 64, 16, 16, gw, gh) }
  quads.gubo_chop_left_1  = { atlas = gubos, q = love.graphics.newQuad( 16, 64, 16, 16, gw, gh) }
  -- Row 5: mine swing, rock to the right; Row 6: mine swing, rock to the left
  quads.gubo_mine_right_0 = { atlas = gubos, q = love.graphics.newQuad(  0, 80, 16, 16, gw, gh) }
  quads.gubo_mine_right_1 = { atlas = gubos, q = love.graphics.newQuad( 16, 80, 16, 16, gw, gh) }
  quads.gubo_mine_left_0  = { atlas = gubos, q = love.graphics.newQuad(  0, 96, 16, 16, gw, gh) }
  quads.gubo_mine_left_1  = { atlas = gubos, q = love.graphics.newQuad( 16, 96, 16, 16, gw, gh) }
end

function sprites.get_atlas()
  return atlases.buildings
end

function sprites.get_quad(name)
  local entry = quads[name]
  if entry then return entry.atlas, entry.q end
  return nil, nil
end

return sprites
