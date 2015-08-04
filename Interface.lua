require "util"
require "Metaballs"


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

    test_spawn = function(args)
        math.randomseed(1)
        local nballs = 2
        local center = {x = 0, y = 0}
        local balls = {}
        local size = 10
        balls[#balls+1] = Metaball.new(center, size)
        for i=1,nballs do
            ball = Metaball.new(center, size)
            ball:random_walk()
            balls[#balls+1] = ball
        end
        for i=1,nballs do
            ball = Metaball.new(center, size)
            ball:random_walk()
            ball.sign = -1
            balls[#balls+1] = ball
        end
        game.player.print(#balls)

        local ore_locations = {}
        local max = 200
        local min_amount = 250
        local richness = 1000
        local area = {
            left_top = { x = -max, y = -max },
            right_bottom = { x = max, y = max }
        }
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

}
