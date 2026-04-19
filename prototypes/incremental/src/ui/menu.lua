-- src/ui/menu.lua
local menu = {}

local MENU_X = 200
local MENU_Y = 100
local MENU_W = 300
local MENU_H = 300

function menu.open(state, building_id)
  state.ui.open_menu = building_id
end

function menu.close(state)
  state.ui.open_menu = nil
end

function menu.is_open(state)
  return state.ui.open_menu ~= nil
end

function menu.get_open_building(state)
  return state.ui.open_menu
end

function menu.draw_header(title)
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", MENU_X, MENU_Y, MENU_W, MENU_H)
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.rectangle("line", MENU_X, MENU_Y, MENU_W, MENU_H)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(title, MENU_X + 10, MENU_Y + 10)
  love.graphics.print("[x]", MENU_X + MENU_W - 30, MENU_Y + 10)
end

function menu.draw_item(y_offset, label, clickable)
  if clickable then
    love.graphics.setColor(1, 1, 1)
  else
    love.graphics.setColor(0.5, 0.5, 0.5)
  end
  love.graphics.print(label, MENU_X + 10, MENU_Y + y_offset)
end

-- Returns true if (sx, sy) is inside the close button
function menu.close_button_hit(sx, sy)
  return sx >= MENU_X + MENU_W - 30 and sx < MENU_X + MENU_W and
         sy >= MENU_Y + 10 and sy < MENU_Y + 25
end

return menu
