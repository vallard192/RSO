require 'util'

--require "Region"
require "Resource"
require "Settings"



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
            regions = {},
            settings = settings,
            resources = {},
            max_allotment = 0,
            spawns = {},
            shift = surface.map_gen_settings.shift,
            --settings['remove_resources'] = true,
            --settings.remove_enemies = true,
        }
        setmetatable(new, {__index=RSO_Surface})
        --table.insert(global.surfaces, new)
        global.surfaces[surface.index] = new
        if surface.name == 'nauvis' then
            debug("Loading default resources.")
            new:load_default_resources()
        end
        --dump(global.surfaces)
        --dump(new)
        return new
    end,

    init_all = function()
        for _, s in ipairs(global.surfaces) do
            RSO_Surface.init(s)
        end
    end,

    init = function(surface)
        setmetatable(surface, {__index = RSO_Surface })
    end,

    initialize_resources = function(self)
        if self.surface.map_gen_settings and self.surface.map_gen_settings.autoplace_controls ~= nil then
            local ap = self.surface.map_gen_settings.autoplace_controls
            for _,v in ipairs(ap) do
                if v.size ~= 'none' then -- Only load resource if Size > None
                    self:load_resource(v.name)
                    --load resource
                end
            end
        end
    end,

    load_resource = function(self, name)

    end,


    get_surface = function(arg)
        if type(arg) == 'string' then
            for _, s in ipairs(global.surfaces) do
                if s.name == name then
                    return s
                end
            end
            if game.surfaces[name] ~= nil then
                local s = RSO_Surface.new(game.surfaces[name])
                return s
            else
                error("Surface not found")
                return nil
            end
        elseif arg.isluaobject then
            for _, s in ipairs(global.surfaces) do
                if s.name == surface.name then
                    return s
                end
            end
            if game.surfaces[surface.name] ~= nil then
                local s = RSO_Surface.new(surface)
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
        for _, s in ipairs(global.surfaces) do
            if s.name == name then
                return s
            end
        end
        if game.surfaces[name] ~= nil then
            local s = RSO_Surface.new(game.surfaces[name])
            return s
        else
            error("Surface not found")
            return nil
        end
    end,

    get_by_surface = function(surface)
        for _, s in ipairs(global.surfaces) do
            if s.name == surface.name then
                return s
            end
        end
        if game.surfaces[surface.name] ~= nil then
            local s = RSO_Surface.new(surface)
            return s
        else
            error("Surface not found")
            return nil
        end
    end,

    wall = function(self)
        self.surface.create_entity({name='stone-wall', position = {0,0}})
    end,

    process_chunk = function(self, chunk)
        local region = self:get_region(chunk.left_top)
        self:clear_chunk(chunk)
        self:populate_chunk(chunk.left_top)
    end,

    --get_chunk = function(self, position)
    --    local size = Settings.CHUNK_SIZE
    --    local rx = math.floor(position.x/size) * size
    --    local ry = math.floor(position.y/size) * size
    --    return { left_top = {x = rx, y = ry }, right_bottom = { x = rx + size, y = ry + size }, }
    --end,

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
            local locations = {}
            locations = resource:spawn(spawn, rng)
            if locations == nil then
                debug('locations == nil')
                dump(spawn)
            else
                --debug('locations != nil')
                --dump(locations)
                for str,loc in pairs(locations) do
                    --debug('test')
                    --dump(loc)
                    if self.spawns[str] == nil then
                        self.spawns[str] = loc
                    else
                        for k,v in ipairs(loc) do
                            self.spawns[str][#self.spawns[str]+1] = v
                        end
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

    add_resource = function(self, data)
        local r = Resource.new(self, data)
        table.insert(self.resources, r)
    end,

    load_default_resources = function(self)
        for _,v in ipairs(global.vanilla) do
            self:add_resource(v)
        end
    end,

    populate_chunk = function(self, position)
        local chunk = to_chunk(position)
        local region = self:get_region(position)
        local spawn = self.spawns[tbl2str(chunk.left_top)] 
        if spawn ~= nil then
            for v, location in ipairs(spawn) do
                self.surface.create_entity(location)
                spawn[v] = nil
            end
        end
        self.spawns[tbl2str(chunk.left_top)] = nil
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

    clear_chunk = function(self, chunk)
        if self.settings.remove_resources then
            for _,ent in ipairs(self.surface.find_entities_filtered({area=chunk, type='resource'})) do
                ent.destroy()
            end
        end
        if self.settings.remove_enemies then
            for _,ent in ipairs(self.surface.find_entities_filtered({area=chunk, force='enemy'})) do
                ent.destroy()
            end
        end
    end,
}
