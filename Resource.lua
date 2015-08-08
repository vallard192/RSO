require 'util'

require "Metaball"
require "Settings"

-- TODO:
-- implement spawn_liquid

Resource = {
    new = function(rsurface, ...)
        local new = {
            rsurface = rsurface,
            surface = rsurface.surface,
        }
        setmetatable(new, {__index=Resource})
        new:parse_input(...)
        new:fill_default()
        new:read_map_gen_settings()
        debug("created resource "..new.name.." type "..new.category.." on surface "..new.surface.name)
        return new
    end,

    parse_input = function(self, ...)
        local arg = {...}
        local data = arg[1]
        local prototype
        if data.isluaobject and data.type == 'resource' then
            self:parse_prototype(data)
        else
            prototype = game.entity_prototypes[data.name]
            if prototype == nil then
                dump(data)
                error("Resource::parse_data(): ERROR Prototype not found!")
            end
            self:parse_prototype(prototype)
            if data.type == 'resource' then
                self:parse_data(data)
            elseif data.type == 'rso-resource' then
                self:parse_rso(data)
            end
        end
    end,

    fill_default = function(self)-- TODO: define default settings for ore
        self.min_amount = self.min_amount or global.settings.resource_defaults.min_amount
        self.richness = self.richness or global.settings.resource_defaults.richness
        self.size = self.size or global.settings.resource_defaults.size
        self.size_base = 1
    end,

    read_map_gen_settings = function(self)
        local map_gen_settings = self.surface.map_gen_settings.autoplace_controls[self.name]
        if map_gen_settings == nil then
            self.freq_mod = Settings.FREQUENCY_MOD[map_gen_settings.frequency]
            self.size_mod = Settings.FREQUENCY_MOD[map_gen_settings.size]
            self.richness_mod = Settings.FREQUENCY_MOD[map_gen_settings.richness]
        else
            self.freq_mod = 3
            self.size_mod = 3
            self.richness_mod = 3
        end
    end,

    parse_prototype = function(self, prototype)
        self.name = prototype.name
        self.type = prototype.type
        self.category = prototype.resource_category
    end,

    parse_rso = function(self, rso_data)
    end,

    parse_data = function(self, data)-- TODO: parse data from data.lua
        self.order = data.order
        self.richness_base = data.autoplace.richness_base
        self.richness_multiplier = data.autoplace.richness_multiplier
        self.size_control_multiplier = data.autoplace.size_control_multiplier
    end,

    init = function(resource)
        setmetatable(resource, {__index = Resource } )
    end,

    spawn = function(self, ...)
        if self.category == 'basic-solid' then
            return self:spawn_solid(...)
        elseif self.category == 'basic-fluid' then
            return self:spawn_fluid(...)
        else
            debug(serpent.block(self.category))
        end
    end,

    spawn_fluid = function(self, pos, rng)
        debug("NYI")
        local nspawns = rng:randint(self.size_base + self.size_mod, self.size_base + 2 * self.size_mod) -- WIP
        local spawns = {}
        local radius = rng:random(Settings.CHUNK_SIZE/2, Settings.CHUNK_SIZE * 3/2)
        local angle = rng:random(0, 2 * math.pi)
        local amount_max = rng:random(nspawns * 0.75, nspawns * 1.25)
        local multiplier = self.richness * self.richness_mod
        local x, y, dist
        local amount_total = 0
        local str
        while amount_total < amount_max do
            local amount = 0.5 + rng:random()
            if amount + amount_total > amount_max then
                amount = amount_max - amount_total
            end
            for j=1,5 do
                dist = rng:random(0.1 * radius, radius)
                angle = angle + rng:random(0, math.pi/2)
                x = pos.x + dist * math.cos(angle)
                y = pos.y + dist * math.sin(angle)
                settings = {
                    position = { x = x, y = y},
                    name = self.name,
                    force = game.forces.neutral,
                    amount = math.floor(amount * multiplier),
                }

                if self.surface.can_place_entity(settings) then
                    local list = {}
                    for k,_ in ipairs(spawns) do -- Find spawns in the direct vicinity
                        if spawns[i].position.x > x - 2.75 and spawns[i].position.x < x + 2.75 then
                            if spawns[i].position.y > y - 2.75 and spawns[i].position.y < y + 2.75 then
                                list[#list +1] = k
                            end
                        end
                    end
                    if list and #list > 0 then -- If other spawns would prevent spawning, fill them
                        for i=1,#list do
                            spawns[list[i]].amount =spawns[list[i]].amount + amount/#list
                            amount_total = amount_total + amount
                            break
                        end
                    else
                        amount_total = amount_total + amount
                        str = tbl2str(chunk(settings.position).left_top)
                        if spawns[str] == nil then
                            spawns[str] = {}
                        end
                        spawns[str][#spawns[str]+1] = settings
                        --spawns[tbl2str({x=x, y=y})] = settings
                        break
                    end
                end -- END can_place_entity
            end
        end
        return spawns
    end,

    generate_balls = function(self, pos, rng)
        local nballs = 2
        local center = {x = pos.x, y = pos.y}
        local balls = {}
        local size = rng:random(self.size.min, self.size.max) -- randomisation needed here
        --local ball_rng = Random.init(game.surfaces['nauvis'].map_gen_settings.seed)
        balls[#balls+1] = Metaball.new(center, size, rng)
        for i=1,nballs do
            ball = Metaball.new(center, size, rng)
            ball:random_walk()
            balls[#balls+1] = ball
        end
        for i=1,nballs do
            ball = Metaball.new(center, size, rng)
            ball.sign = -1
            ball:random_walk()
            balls[#balls+1] = ball
        end
        return balls
    end,

    --spawn_solid = function(self, pos, rng, spawn)
    spawn_solid = function(self, pos, rng)
        local balls = self:generate_balls(pos,rng)
        --local max = 200
        --local richness = 1000 -- randomization

        -- Generate ore locations
        local locations = {}
        local area = Metaball.bounding_box(balls)
        local total_influence = 0
        for location in Metaball.iterate(area, balls) do
            if self.surface.can_place_entity({
                name = self.name,
                position = { x = location.x, y = location.y } }) then
                locations[#locations+1] = location
                total_influence = total_influence + location.total
            end
        end
        --debug("#loc: "..#locations)

        -- Spawn ore at locations
        local total = 0
        local spawn = {}
        local str
        --local mult = math.abs((res-#locations * min_amount)/locations[#locations].total)
        --debug("mult: "..mult)
        for _,location in ipairs(locations) do
            local settings = {
                name = self.name,
                position = { x = location.x, y = location.y},
                force = game.forces.neutral,
                amount = math.floor( self.min_amount + location.sum * self.richness), -- TODO: refine this formula
            }
            total = total + settings.amount
            str = tbl2str(chunk(settings.position).left_top)
            if spawn[str] == nil then
                spawn[str] = {}
            end
            spawn[str][#spawn[str]+1] = settings
        end
        return spawn
    end,
}
