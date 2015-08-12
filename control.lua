require "defines"
require "Surface"
require "Settings"
require "Interface"

require "util"
require "prototypes"

VERSION = 0.1


local function init()
    always_day()
    --dump(game.surfaces)
    if global.version == nil then
        global.version = VERSION
        global.settings = Settings.new()
        if global.surfaces == nil then
            global.surfaces = {}
            if global.rso_resources == nil then
                global.rso_resources = {}
            end
            global.on_tick = {}
            global.tick = 60
            --Surface.table = global.surface
        end
    end
end

local function on_load()
    RSO_Surface.init_all()
    if global.version == nil then
        global.version = VERSION
        global.settings=Settings.new()
    elseif global.version == VERSION then
        Settings.init(global.settings)
    end
    --global.tick = game.tick + 60
    --Surface.table = global.surface
end

local function on_chunk_generated(event)
    RSO_Surface.on_chunk_generated(event)
    --local surface = event.surface
    --if event.surface.valid then
    --    local chunk = event.area
    --    s = RSO_Surface.get_surface(surface.name)
    --    s:process_chunk(chunk)
    --end

end

local function on_tick(event)
    for k,v in pairs(global.on_tick) do
        v(k)
    end
    --if game.tick == global.tick then
    --end
end


game.on_init(init)
game.on_load(on_load)

game.on_event(defines.events.on_chunk_generated, on_chunk_generated)
game.on_event(defines.events.on_tick, on_tick)

remote.add_interface("RSO", Interface)
remote.add_interface("RSO_Surface", Surface_Interface)
