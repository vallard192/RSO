debug = true
CHUNK_SIZE = 32
MARK = false

function delayed_call(func, ticks, ...)
    local tick = game.tick + ticks
    --local tmp = function(key)
    --    if game.tick >= tick then
    --        func(...)
    --        global.on_tick[key] = nil
    --    end
    --end
    table.insert(global.on_tick, { func = func, tick = tick, args = ...})
end

function to_chunk(...)
    local arg = {...}
    local x, y, cx, cy
    if #arg == 1 then
        if type(arg[1]) == 'table' then
            x = arg[1].x or arg[1][1]
            y = arg[1].y or arg[1][2]
        else
            error('wrong type of argument #1 to chunk()')
        end
    else
        x = arg[1]
        y = arg[2]
    end
    cx = math.floor(x/CHUNK_SIZE)
    cy = math.floor(y/CHUNK_SIZE)
    return {
        left_top = { x = cx * CHUNK_SIZE, y = cy * CHUNK_SIZE, },
        right_bottom = { x = ( cx + 1 ) * CHUNK_SIZE, y = ( cy + 1 ) * CHUNK_SIZE },
        position = { x = cx/CHUNK_SIZE, y = cy/CHUNK_SIZE },
        str = tbl2str({ x = cx, y = cy })
    }
end

function mark_area(area, surface)
    if not MARK then
        debug("abort mark area")
        return
    end
    for x=area.left_top.x,area.right_bottom.x do
        for _,y in pairs({area.left_top.y, area.right_bottom.y}) do
            surface.create_entity({name='stone-wall', position={x,y}, force = game.forces.neutral})
        end
    end
    for y=area.left_top.y,area.right_bottom.y do
        for _,x in pairs({area.left_top.x, area.right_bottom.x}) do
            surface.create_entity({name='stone-wall', position={x,y}, force = game.forces.neutral})
        end
    end
end

function str2tbl(str)
    local tbl = {}
    if #str == 3 then
        tbl.x = str[1]
        tbl.y = str[3]
    elseif #str == 7 then
        tbl.left_top = { x = str[1], y = str[3] }
        tbl.right_bottom = { x = str[5], y = str[7] }
    end
    return tbl
end



function tbl2str(tbl)
    if tbl.left_top ~= nil then
        return tbl.left_top.x..','..tbl.left_top.y..'-'..tbl.right_bottom.x..'.'..tbl.right_bottom.y
    elseif tbl.x ~= nil then
        return tbl.x..','..tbl.y
    end
end



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


function always_day()
    if debug then
        game.always_day = true
    end
end
