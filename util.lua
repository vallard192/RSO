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
