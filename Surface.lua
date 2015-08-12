require 'util'

--require "Region"
require "Resource"
require "Settings"

GEN_REQUESTED = 1
GEN_FINISHED = 2
GEN_TICK_WAIT = 200


RSO_Surface = {

    new = function(surface)
        local settings = {
            remove_enemies = true,
            remove_resources = true,
        }
        local new = {
            name = surface.name,
            surface = surface,
            seed = surface.map_gen_settings.seed,
            starting_area = Settings.SIZE_MOD[surface.map_gen_settings.starting_area] * 20 + 20,
            shift = surface.map_gen_settings.shift,
            settings = settings,
            regions = {},
            chunks = {},
            resources = {},
            max_allotment = 0,
            spawns = {},
        }
        setmetatable(new, {__index=RSO_Surface})
        global.surfaces[surface.index] = new
        if surface.name == 'nauvis' then
            debug("Loading default resources.")
            new:load_default_resources()
        end
        --dump(global.surfaces)
        --dump(new)
        --call_later(debug, 1800, "test")
        return new
    end,

    init_all = function()
        for _, s in pairs(global.surfaces) do
            RSO_Surface.init(s)
        end
    end,

    init = function(surface)
        setmetatable(surface, {__index = RSO_Surface })
        for _,v in pairs(surface.resources) do
            Resource.init(v)
        end
    end,

    on_chunk_generated = function(event)
        local surface = event.surface
        if event.surface.valid then
            local s = RSO_Surface.get_surface(surface.name)
            local chunk = event.area
            s:process_chunk(chunk.left_top)
        else
            error("surface is not vaild")
        end
    end,

    on_tick = function()
        for _,s in pairs(global.surfaces) do
            s:populate_chunks()
        end
    end,

    get_surface = function(arg)
        if type(arg) == 'string' then
            for _, s in pairs(global.surfaces) do
                if s.name == arg then
                    return s
                end
            end
            if game.surfaces[arg] ~= nil then
                local s = RSO_Surface.new(game.surfaces[arg])
                return s
            else
                error("Surface not found")
                return nil
            end
        elseif arg.isluaobject then
            for _, s in pairs(global.surfaces) do
                if s.name == arg.name then
                    return s
                end
            end
            if game.surfaces[arg.name] ~= nil then
                local s = RSO_Surface.new(arg)
                return s
            else
                error("Surface not found")
                return nil
            end
        else
            debug("RSO_Surface.get() called with neither string nor surface")
        end
    end,


    get_by_name = function(name)
        debug("use is deprecated, use get_surface instead")
        return RSO_Surface.get_surface(name)
        --for _, s in pairs(global.surfaces) do
        --    if s.name == name then
        --        return s
        --    end
        --end
        --if game.surfaces[name] ~= nil then
        --    local s = RSO_Surface.new(game.surfaces[name])
        --    return s
        --else
        --    error("Surface not found")
        --    return nil
        --end
    end,

    get_by_surface = function(surface)
        debug("use is deprecated, use get_surface instead")
        return RSO_Surface.get_surface(surface)
        --for _, s in pairs(global.surfaces) do
        --    if s.name == surface.name then
        --        return s
        --    end
        --end
        --if game.surfaces[surface.name] ~= nil then
        --    local s = RSO_Surface.new(surface)
        --    return s
        --else
        --    error("Surface not found")
        --    return nil
        --end
    end,

    get_region = function(self, position)
        --local size = global.settings.region_size * CHUNK_SIZE
        local size = Settings.REGION_SIZE
        local rx = math.floor(position.x/size) * size
        local ry = math.floor(position.y/size) * size
        if self.regions[tbl2str({ x = rx, y = ry })] ~= nil then
            return self.regions[tbl2str({ x = rx, y = ry })]
        else
            return self:create_region({x = rx, y = ry})
        end
    end,

    create_region = function(self, position)
        local region = {}
        region.area = {
            left_top = { x = position.x, y = position.y },
            right_bottom = { x = position.x + Settings.REGION_SIZE, y = position.y + Settings.REGION_SIZE },
        }
        --region.chunks = {}
        --region.spawns = {}
        self.regions[tbl2str(position)] = region
        self:calculate_spawns(region)
        return region
    end,

    initialize_resources = function(self)
        if self.surface.map_gen_settings and self.surface.map_gen_settings.autoplace_controls ~= nil then
            local ap = self.surface.map_gen_settings.autoplace_controls
            for _,v in pairs(ap) do
                if v.size ~= 'none' then -- Only load resource if Size > None
                    self:load_resource(v.name)
                    --load resource
                end
            end
        end
    end,

    load_resource = function(self, name)
        return {}
    end,

    add_resource = function(self, data)
        debug('adding resource')
        local r = Resource.new(self, data)
        table.insert(self.resources, r)
    end,

    load_default_resources = function(self)
        --dump(global.rso_resources)
        for _,v in pairs(global.rso_resources) do
            self:add_resource(v)
        end
    end,

    calculate_spawns = function(self, region)
        local offset = {
            x = region.area.left_top.x - self.shift.x,
            y = region.area.left_top.y - self.shift.y
        }
        region.rng = Random.init(bit32.bxor(offset.x, offset.y))
        if #self.resources == 0 then
            return
        end
        local resource = self.resources[region.rng:randint(1,#self.resources)]
        local spawn = self:find_spawn_location(region.area, region.rng)
        local str = ''
        if spawn ~= nil then
            local locations = resource:spawn(spawn, rng)
            if locations == nil then
                debug('locations == nil')
                dump(spawn)
            else
                --debug('locations != nil')
                --dump(locations)
                for chnk,loc in pairs(locations) do -- loop over chunks in locations
                    --debug('test')
                    --dump(loc)
                    if self.spawns[chnk] == nil then
                        self.spawns[chnk] = loc
                    else
                        for k,v in pairs(loc) do
                            --self.surface.create_entity(v)
                            self.spawns[chnk][#self.spawns[chnk]+1] = v
                        end
                    end
                    if self.surface.is_chunk_generated(to_chunk(loc[1].position).position) then -- TODO: is_chunk_generated takes chunk not coordinates.
                        --debug(to_chunk(loc[1].position).str.." is already generated, repopulate it")
                        self:populate_chunk(loc[1].position)
                        --dump(self.spawns[chnk])
                    end
                end
            end
        end
    end,

    find_spawn_location = function(self, area, rng) -- TODO: check for water area, take name of resource
        local spawn = {x = 0, y = 0}
        for i=1,50 do
            spawn.x = rng:randint(area.left_top.x, area.right_bottom.x)
            spawn.y = rng:randint(area.left_top.y, area.right_bottom.y)
            if self.surface.can_place_entity({position = spawn, name = 'stone'}) then
                return spawn
            end
        end
        return nil
    end,

    process_chunk = function(self, position)
        local region = self:get_region(position)
        self:clear_chunk(position)
        self.chunks[to_chunk(position).str] = GEN_FINISHED
        self:populate_chunk(position)
        --    local set = {
        --        position = { x = chunk.right_bottom.x + 2, y = chunk.left_top.y },
        --        name = 'stone-wall',
        --        force = game.forces.enemy
        --    }
        --    surface.create_entity(set)
        --    surface.create_entity(set)
    end,

    populate_chunk = function(self, position)
        local chunk = to_chunk(position)
        local region = self:get_region(position)
        local spawn = self.spawns[chunk.str]
        local ent
        if spawn ~= nil then
            if self.chunks[chunk.str] == GEN_FINISHED then
                --debug("Gen finished, populating it")
                for v, location in pairs(spawn) do
                    if self.surface.can_place_entity(location) then
                        ent = self.surface.create_entity(location)
                        if ent ~= nil then
                            spawn[v] = nil
                        end
                    else
                        --debug("Can't place entity at "..serpent.block(location))
                    end
                end
            else
                --debug("Gen not finished, waiting")
                self.surface.request_to_generate_chunks(position, 1)
                --delayed_call(RSO_Surface.populate_chunk, GEN_TICK_WAIT, self, position)
                local count = 0
                local tick = game.tick + GEN_TICK_WAIT
                local tmp = function(key)
                    --count = count + 1
                    --if count%100 == 0 then
                    --    debug(count.." position "..chunk.str.." key "..key)
                    --end
                    --debug("waiting")
                    --if game.tick > tick and self.chunks[chunk.str] == GEN_FINISHED then
                    if game.tick > tick then
                        self:populate_chunk(position)
                        --debug("Repopulated "..chunk.str)
                        global.on_tick[key] = nil
                    end
                end
                table.insert(global.on_tick, tmp)
            end
            --dump(spawn)
            if next(spawn) == nil then
                self.spawns[chunk.str] = nil
            end
        else
            --debug(chunk.str)
        end
    end,

    build_base = function(self, position, size)
        dump(position)
        dump(size)
        local region = self:get_region(position)
        local area = {
            left_top = { position.x - 10, position.y - 10 },
            right_bottom = { position.x + 10, position.y + 10 },
        }
        local pos = {
            x = region.rng:random(area.left_top.x, area.right_bottom.x),
            y = region.rng:random(area.left_top.y, area.right_bottom.y),
            }
        local counter = 0
        for i=1,size do
            counter = 0
            while not self.surface.can_place_entity({position = pos, name = 'small-biter'}) do
                counter = counter + 1
                pos.x = region.rng:random(area.left_top.x, area.right_bottom.x)
                pos.y = region.rng:random(area.left_top.y, area.right_bottom.y)
                if counter >10 then break end
            end
            self.surface.create_entity({position = pos, name = 'small-biter', force = game.forces.enemy })
        end
        self.surface.build_enemy_base(position, size)
    end,

    clear_chunk = function(self, position)
        local chunk = to_chunk(position)
        if self.settings.remove_resources then
            for _,ent in pairs(self.surface.find_entities_filtered({area=chunk, type='resource'})) do
                debug("removed "..ent.name.." from position "..tbl2str(ent.position))
                ent.destroy()
            end
        end
        if self.settings.remove_enemies then
            for _,ent in pairs(self.surface.find_entities_filtered({area=chunk, force='enemy'})) do
                ent.destroy()
            end
        end
    end,
}
