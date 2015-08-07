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
        --if resource.isluaobject then
        --    debug("Interpolating from LuaEntityPrototype")
        --    new.category = resource.resource_category
        --else
        --    new.category = resource.category or game.entity_prototypes[resource.name].resource_category -- Because basic-solid is missing in demo-resources.lua
        --    new.order = resource.order
        --    new.richness_base = resource.autoplace.richness_base
        --    new.richness_multiplier = resource.autoplace.richness_multiplier
        --    new.size_control_multiplier = resource.autoplace.size_control_multiplier
        --end

        --new.allotment = 50
        --new.spawns_per_region = { min=1, max=2 }
        --new.richness=1100
        --new.size={min=12, max=18}
        --new.min_amount=250
        --if rsurface ~= nil then
        --    new.surface = rsurface.surface
        --else
        --    new.surface = game.surfaces.nauvis
        --end

        --starting={richness=6000, size=14, probability=1},

        -- multi_resource_chance=0.50,
        -- multi_resource_generic = true,
        -- multi_resource = nil,

        -- surface = nil
        --}
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
            --if spawn ~= nil then
                --spawn[tbl2str(chunk(settings.position).left_top)] = settings
            --else
                --self.surface.create_entity(settings)
            --end
        end
        return spawn
    end,

--  spawn_liquid = function(surface, pos, startingArea, restrictions)
--    rname = self.name
--    size = self.size
--    richness = self.richness
--	restrictions = restrictions or ''
--	debug("Entering spawn_resource_liquid "..rname.." "..pos.x..","..pos.y.." "..size.." "..richness.." "..tostring(startingArea).." "..restrictions)
--	local _total = 0
--	local max_radius = rgen:random()*CHUNK_SIZE/2 + CHUNK_SIZE
--	--[[
--		if restrictions == 'xy' then
--		-- we have full 4 chunks
--		max_radius = floor(max_radius*1.5)
--		size = floor(size*1.2)
--		end
--	]]--
--	-- don't reduce amount of liquids - they are already infinite
--	--  size = modify_resource_size(size)
--	
--	richness = richness * size
--	
--	local total_share = 0
--	local avg_share = 1/size
--	local angle = rgen:random()*pi*2
--	local saved = 0
--	while total_share < 1 do
--		local new_share = vary_by_percentage(avg_share, 0.25)
--		if new_share + total_share > 1 then
--			new_share = 1 - total_share
--		end
--		total_share = new_share + total_share
--		if new_share < avg_share/10 then
--			-- too small
--			break 
--		end
--		local amount = floor(richness*new_share) + saved
--		--if amount >= game.entity_prototypes[rname].minimum then 
--		if amount >= config[rname].minimum_amount then 
--			saved = 0
--			for try=1,5 do
--				local dist = rgen:random()*(max_radius - max_radius*0.1)
--				angle = angle + pi/4 + rgen:random()*pi/2
--				local x, y = pos.x + cos(angle)*dist, pos.y + sin(angle)*dist
--				if surface.can_place_entity{name = rname, position = {x,y}} then
--					debug("@ "..x..","..y.." amount: "..amount.." new_share: "..new_share.." try: "..try)
--					_total = _total + amount
--					surface.create_entity{name = rname,
--						position = {x,y},
--						force = game.forces.neutral,
--						amount = floor(amount*global_richness_mult),
--					direction = rgen:random(4)}
--					break
--				elseif not startingArea then -- we don't want to make ultra rich nodes in starting area - failing to make them will add second spawn in different location
--					entities = surface.find_entities_filtered{area = {{x-2.75, y-2.75}, {x+2.75, y+2.75}}, name=rname}
--					if entities and #entities > 0 then
--						_total = _total + amount
--						for k, ent in pairs(entities) do
--							ent.amount = ent.amount + floor(amount/#entities)
--						end
--						break
--					end
--				end
--			end
--		else
--			saved = amount
--		end
--	end
--	debug("Total amount: ".._total)
--	debug("Leaving spawn_resource_liquid")
--	return _total
--end
}
