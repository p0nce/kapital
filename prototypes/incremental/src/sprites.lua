-- src/sprites.lua
local sprites = {}

local atlas = nil
local quads = {}

function sprites.load()
  atlas = love.graphics.newImage("Tilesets/Chroma-Noir-8x8/Buildings.png")
  atlas:setFilter("nearest", "nearest")
  local aw, ah = atlas:getDimensions()

  -- House sprite at (0, 32), 7x4 tiles = 56x32 px
  quads.house = love.graphics.newQuad(0, 32, 56, 32, aw, ah)
end

function sprites.get_atlas()
  return atlas
end

function sprites.get_quad(name)
  return quads[name]
end

return sprites
