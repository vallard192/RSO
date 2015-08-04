require "defines"
require "Surface"
require "Settings"
require "Interface"

local function message(msg)
    game.player.print(msg)
end

local function dump(obj)
    game.player.print(serpent.dump(obj))
end

local function init()
    if global.version == nil then
        global.version = 0.1
        global.settings = Settings.new()
        if global.surfaces == nil then
            global.surfaces = {}
            global.on_tick = {}
            global.tick = 60
            --Surface.table = global.surface
        end
    end
end

local function on_load()
    RSO_Surface.init_all()
    if global.version == nil then
        global.version = 0.1
        global.settings=Settings.new()
    elseif global.version == 0.1 then
        Settings.init(global.settings)
    end
    global.tick = game.tick + 60
    --Surface.table = global.surface
end

local function on_chunk_generated(event)
    local surface = event.surface
    if event.surface.valid then
        local chunk = event.area
        s = RSO_Surface.get_by_name(surface.name)
        --print(s.name)
        --dump(s)
        s:process_chunk(chunk)
    end

end

local function on_tick(event)
    for _,k in ipairs(global.on_tick) do
        k()
    end
    if game.tick == global.tick then
        dump(global.surfaces)
        --s = RSO_Surface.get_surface_by_name('nauvis')
--        for _,c in s.surface.get_chunks() do
--            message("this is i:"..i)
--            dump(c)
--            i=i+1
--        end
        --s = RSO_Surface.get_surface_by_name('nauvis')
    end
end


game.on_init(init)
game.on_load(on_load)

game.on_event(defines.events.on_chunk_generated, on_chunk_generated)
game.on_event(defines.events.on_tick, on_tick)

remote.add_interface("RSO", Interface)
