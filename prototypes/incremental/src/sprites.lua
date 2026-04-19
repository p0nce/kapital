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
  quads.ground     = { atlas = underground, q = love.graphics.newQuad(  8, 72,  8,  8, uw, uh) }
  -- Rock: two quads from Underground.png → 3x1 tiles = 24x8 px total
  quads.rock_left  = { atlas = underground, q = love.graphics.newQuad( 88, 16,  8,  8, uw, uh) }
  quads.rock_right = { atlas = underground, q = love.graphics.newQuad(104, 16, 16,  8, uw, uh) }
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
