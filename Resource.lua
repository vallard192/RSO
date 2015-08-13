require 'util'

require "Metaball"
require "Settings"

-- TODO:
--
-- Available data sources:
-- - rso_data in data prototype
-- - data prototype
-- - entity prototype
--
-- For the 3 properties (size, freq, richness) there are three settings:
-- xx_base for the base amount
-- xx_mod for how much impact map_gen_settings have. in rso_data this should be function(x) return x*2; end for example
-- xx_dist for the distance modifier (again function of distance in regions)

Resource = {
    new = function(rsurface, ...)
        local new = {
            category = 'basic-solid',
            rsurface = rsurface,
            surface = rsurface.surface,
            name = 'dummy',
            size_base = 15,
            size_mod = 1,
            freq_base = 0,
            freq_mod = 0,
            richness_base = 0,
            richness_mod = 0,
            order = 0, -- Is that needed?
            start = false, -- Should be table if spawns in starting area are allowed/necessary
            min_amount = 500,
        }
        --dump(new)
        setmetatable(new, {__index=Resource})
        new:parse_input(...)
        --new:fill_default()
        --new:read_map_gen_settings()
        debug(new.richness_base)
        debug("created resource "..new.name.." type "..new.category.." on surface "..new.surface.name)
        return new
    end,

    parse_input = function(self, ...)
        debug('Resource::parse_input called')
        local arg = {...}
        local data = arg[1]
        if type(arg[1]) == 'string' then
            debug(arg[1].." is a string")
            self:parse_prototype(arg[1])
            return
        elseif self:parse_rso(...) then
            debug('rso data used')
            return
        elseif self:parse_data(...) then
            debug('data successful')
            return
        else
            dump(arg)
            error('something wrong')
            return
        end
        --if data.isluaobject and data.type == 'resource' then
        --    self:parse_prototype(data)
        --else
        --    prototype = game.entity_prototypes[data.name]
        --    if prototype == nil then
        --        dump(data)
        --        error("Resource::parse_data(): ERROR Prototype not found!")
        --    end
        --    self:parse_prototype(prototype)
        --    if data.type == 'resource' then
        --        self:parse_data(data)
        --    elseif data.type == 'rso-resource' then
        --        self:parse_rso(data)
        --    end
        --end
    end,

    -- If rso_data table is present in the data, copy it to the local table
    parse_rso = function(self, ...)
            debug('parsing rso')
        local arg = {...}
        local rdata
        for k,v in pairs(arg) do
            if v.rso_data ~= nil then
                for property, setting in pairs(v.rso_data) do
                    if self[property] ~= nil then
                        self[property] = setting
                    end
                end
                self.name = v.name
                self:parse_prototype(self.name)
                return true
            end
        end
        return false

    end,

    parse_data = function(self, ...)-- TODO: parse data from data.lua
        local arg = {...}
        if #arg==1 then
            data = arg[1]
            local ap = data.autoplace
            self.name = data.name
            self:parse_prototype(self.name)
            self.order = data.order
            self.richness_base = ap.richness_base or 0
            self.richness_multiplier = ap.richness_multiplier/10 or 1000
            self.size_control_multiplier = ap.size_control_multiplier or 0.04
            self.autoplace_control = ap.control
            self:read_map_gen_settings()
        else
            error('call to parse_data with multiple inputs is not supported yet')
            return false
        end
        return true
    end,

    parse_prototype = function(self, name)
        debug('parsing prototype')
        --dump(name)
        local prototype = game.entity_prototypes[name]
        self.type = prototype.type
        self.category = prototype.resource_category
    end,

    --fill_default = function(self)-- TODO: define default settings for ore
    --    self.min_amount = self.min_amount or global.settings.resource_defaults.min_amount
    --    self.richness = self.richness or global.settings.resource_defaults.richness
    --    self.size = self.size or global.settings.resource_defaults.size
    --    self.size_base = 1
    --end,

    read_map_gen_settings = function(self)
        local map_gen_settings = self.surface.map_gen_settings.autoplace_controls[self.autoplace_control]
        if map_gen_settings ~= nil then
            self.freq_mod = Settings.FREQUENCY_MOD[map_gen_settings.frequency]
            self.size_mod = (Settings.SIZE_MOD[map_gen_settings.size] > 0) and 2^( (Settings.SIZE_MOD[map_gen_settings.size]-3)/2) or 0
            self.richness_mod = Settings.RICHNESS_MOD[map_gen_settings.richness]
            self.size_mod = 2
        else
            self.freq_mod = 3
            self.size_mod = 1
            self.richness_mod = 1
        end
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
        --debug("NYI") Implemented now !
        local nspawns = rng:randint(self.size_base + self.size_mod, self.size_base + 2 * self.size_mod) -- WIP
        local locations = {}
        local dist_mod = self.surface.get_tileproperties(pos.x, pos.y).tier_from_start
        local radius = rng:random(Settings.CHUNK_SIZE/2, Settings.CHUNK_SIZE * 3/2)
        local angle = rng:random(0, 2 * math.pi)
        local amount_max = rng:random(nspawns * 0.75, nspawns * 1.25)
        local multiplier = self.richness_base * self.richness_mod
        local x, y, dist
        local amount_total = 0
        local str
        debug("oil spawn")
        while amount_total < amount_max do
            local amount = 0.5 + rng:random()
            if amount + amount_total > amount_max then
                amount = amount_max - amount_total
            end
            for j=1,5 do
                dist = rng:random(0.1 * radius, radius)
                angle = angle + rng:random(0, math.pi/2)
                x = math.floor(pos.x + dist * math.cos(angle))
                y = math.floor(pos.y + dist * math.sin(angle))
                settings = {
                    position = { x = x, y = y},
                    name = self.name,
                    force = game.forces.neutral,
                    amount = math.floor(self.richness_base + amount * self.richness_multiplier ),
                }
                --if true then
                if self.surface.can_place_entity(settings) then
                    amount_total = amount_total + amount
                    str = to_chunk(settings.position).str
                    if locations[str] == nil then
                        locations[str] = {}
                    end
                    locations[str][#locations[str]+1] = settings
                    --locations[tbl2str({x=x, y=y})] = settings
                    break
                    --local list = {}
                    --for chnk,chnk_data in pairs(locations) do -- Find spawns in the direct vicinity
                    --    for k,v in pairs(chnk_data) do
                    --        if locations[chnk][k].position.x > x - 2.75 and locations[chnk][k].position.x < x + 2.75 then
                    --            if locations[chnk][k].position.y > y - 2.75 and locations[chnk][k].position.y < y + 2.75 then
                    --                list[#list + 1] = {chnk,k}
                    --            end
                    --        end
                    --    end
                    --end
                    --if list and #list > 0 then -- If other locations would prevent spawning, fill them
                    --    for i=1,#list do
                    --        locations[list[i][1]][list[i][2]].amount = locations[list[i][1]][list[i][2]].amount + amount/#list
                    --        amount_total = amount_total + amount
                    --        break
                    --    end
                    --else
                    --    amount_total = amount_total + amount
                    --    str = to_chunk(settings.position).str
                    --    if locations[str] == nil then
                    --        locations[str] = {}
                    --    end
                    --    locations[str][#locations[str]+1] = settings
                    --    --locations[tbl2str({x=x, y=y})] = settings
                    --    break
                    --end
                end -- END can_place_entity
            end
        end
        --debug(serpent.block(locations))
        return locations
    end,

    generate_balls = function(self, pos, rng)
        local nballs = 3
        local center = {x = pos.x, y = pos.y}
        local balls = {}
        local size = self:distance_mod(pos) * self.size_mod * rng:random(self.size_base * 0.75, self.size_base * 1.25) -- randomisation needed here
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

    distance_mod = function(self, pos)
        local tier = self.surface.get_tileproperties(pos.x, pos.y).tier_from_start + 1
        local dist_log = math.log(tier)/Settings.DISTANCE_SCALE
        local dist_exp = math.exp(tier / ( 10 * Settings.DISTANCE_SCALE ) ) - 1
        return math.min(dist_log, dist_exp) + 1
    end,


    --spawn_solid = function(self, pos, rng, spawn)
    spawn_solid = function(self, pos, rng)
        local balls = self:generate_balls(pos,rng)
        local dist_mod = self:distance_mod(pos)
        -- Generate ore locations
        local locations = {}
        local area = Metaball.bounding_box(balls)
        --mark_area(area, self.surface)
        local settings, str
        local total = 0
        local total_influence = 0
        for location in Metaball.iterate(area, balls) do
            settings = {
                name = self.name,
                position = { x = location.x, y = location.y},
                force = game.forces.neutral,
                amount = math.floor( self.richness_base + location.sum * self.richness_multiplier * dist_mod ),
            }
            if true then
            --if self.surface.can_place_entity(settings) then
                total_influence = total_influence + location.total
                total = total + settings.amount
                str = to_chunk(settings.position).str
                if locations[str] == nil then
                    locations[str] = {}
                end
                locations[str][#locations[str]+1] = settings
            end
        end
        --debug("dist mod:"..dist_mod)
        --debug("#loc: "..#locations)
        -- Spawn ore at locations
        --local mult = math.abs((res-#locations * min_amount)/locations[#locations].total)
        --debug("mult: "..mult)
        --dump(locations[to_chunk({-30,-290}).str])
        return locations
    end,
}
