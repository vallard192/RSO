debug = true

function message(msg)
    for _,p in ipairs(game.players) do
        p.print(msg)
    end
end



function dump(obj)
    msg = serpent.dump(obj)
    if debug then
        for _,p in ipairs(game.players) do
            p.print(msg)
        end
    end
end



function debug(msg)
    if debug then
        for _,p in ipairs(game.players) do
            p.print(msg)
        end
    end
end



function rotate(pos, origin, angle)
    local x_shift = pos.x - origin.x
    local y_shift = pos.y - origin.y
    local x_rot = x_shift * math.cos(angle) - y_shift * math.sin(angle)
    local y_rot = y_shift * math.cos(angle) + x_shift * math.sin(angle)
    return {
        x = x_rot,
        y = y_rot,
        xs = x_shift,
        ys = y_shift,
    }
end
