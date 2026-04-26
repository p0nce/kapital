-- conf.lua
function love.conf(t)
  t.window.width = 800
  t.window.height = 600
  t.window.title = "Incremental"
  t.window.vsync = 1
  t.window.resizable = true
  t.version = "11.5"
end

if love._os == "Windows" then
  local ffi = require "ffi"
  ffi.cdef[[ bool SetProcessDPIAware(); ]]
  ffi.C.SetProcessDPIAware();
end