local state = {
    money = 0,
    perClick = 1,
    perSecond = 0,
}

local font

function love.load()
    font = love.graphics.newFont(22)
    love.graphics.setFont(font)
    love.graphics.setBackgroundColor(0.08, 0.08, 0.10)
end

function love.update(dt)
    state.money = state.money + state.perSecond * dt
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Money: %.2f", state.money), 20, 20)
    love.graphics.print(string.format("Per click: %d", state.perClick), 20, 50)
    love.graphics.print(string.format("Per second: %.1f", state.perSecond), 20, 80)
    love.graphics.print("[click] earn   [u] +1/s   [r] reset   [esc] quit", 20, 140)
    love.graphics.print(string.format("FPS: %d", love.timer.getFPS()), 20, 680)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        state.money = state.money + state.perClick
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" then state.money = 0; state.perSecond = 0 end
    if key == "u" then state.perSecond = state.perSecond + 1 end
end
