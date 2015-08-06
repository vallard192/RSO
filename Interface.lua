require "util"
require "Metaball"
require "Surface"
require "Resource"
require "libs/random"

rng = Random.init(1)


Interface = {
    clear_area = function(surface)
        area = {
            top_left = { x = -512, y = -512 },
            right_bottom = { x = 512, y = 512 }
        }
        if surface == nil then
            surface = game.surfaces['nauvis']
        end
        for _, obj in ipairs(surface.find_entities_filtered({area = area, force = 'enemy'})) do
            obj.destroy()
        end
        for _, obj in ipairs(surface.find_entities_filtered({area = area, force = 'neutral'})) do
            obj.destroy()
        end
    end,

    test_spawn = function(...)
        local res = Resource.new(game.entity_prototypes['iron-ore'],nil)
        local args = {...}
        dump(args)
        local x = args[1] or game.player.position.x or 0
        local y = args[2] or game.player.position.y or 0
        debug("x "..x.." y "..y)
        res:spawn({x = x, y = y }, rng)
    end,
    dummy = function()
        local nballs = 1
        local center = {x = 0, y = 0}
        local balls = {}
        local size = 10
        --local ball_rng = Random.init(game.surfaces['nauvis'].map_gen_settings.seed)
        balls[#balls+1] = Metaball.new(center, size, rng)
        for i=1,nballs do
            ball = Metaball.new(center, size, rng)
            ball:random_walk()
            balls[#balls+1] = ball
        end
        for i=1,nballs do
            ball = Metaball.new(center, size, rng)
            ball:random_walk()
            ball.sign = -1
            balls[#balls+1] = ball
        end
        game.player.print(#balls)

        local ore_locations = {}
        local max = 200
        local min_amount = 250
        local richness = 1000
        --local area = {
        --    left_top = { x = -max, y = -max },
        --    right_bottom = { x = max, y = max }
        --}
        local area = Metaball.bounding_box(balls)
        dump(area)
        for location in Metaball.iterate(area, balls) do
            --dump(location)
            ore_locations[#ore_locations+1] = location
        end
        debug("#loc: "..#ore_locations)
        local total = 0
        --local mult = math.abs((res-#ore_locations * min_amount)/ore_locations[#ore_locations].total)
        --debug("mult: "..mult)
        for _,location in ipairs(ore_locations) do
            local surface = game.surfaces['nauvis']
            local settings = {
                name = 'iron-ore',
                position = {location.x, location.y},
                --force = game.forces['neutral'],
                amount = math.floor( min_amount + location.sum * richness),
            }
            total = total + settings.amount
            --debug(settings.amount)
            --dump(settings)
            surface.create_entity(settings)
        end
        debug("total: "..total)
    end,

    seed = function(seed)
        debug("Setting seed to "..seed)
        rng:reseed(seed)
    end,

    randint = function(...)
        debug(rng:randint(...))
    end,

    random = function(...)
        debug(rng:random(...))
    end,
}

Surface_Interface = {
    list_resources = function(name)
        local s = RSO_Surface.get_by_name(name)
        for _,v in ipairs(s.resources) do
            debug(v.name)
        end
    end,

    add_resource = function(name, data)
        local s = RSO_Surface.get_by_name(name)
        debug(serpent.block(data))
    end,

    call = function(name, f, ...)
        local s = RSO_Surface.get_by_name(name)
        RSO_Surface[f](s, ...)
    end,

    get = function(name, property)
        local s = RSO_Surface.get_by_name(name)
        dump(s[property])
    end,

    dump = function(name)
        local s = RSO_Surface.get_by_name(name)
        dump(s)
    end,

}
