-- src/screen.lua
-- Convenience wrappers for current window dimensions (resize-safe).
local screen = {}

function screen.w() return love.graphics.getWidth()  end
function screen.h() return love.graphics.getHeight() end
function screen.dims() return love.graphics.getDimensions() end

return screen
