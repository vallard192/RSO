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
            shift = surface.map_gen_settings.shift,
            --settings['remove_resources'] = true,
            --settings.remove_enemies = true,
        }
        setmetatable(new, {__index=RSO_Surface})
        table.insert(global.surfaces, new)
        if surface.name == 'nauvis' then
            debug("Loading default resources.")
            new:load_default_resources()
        end
        --dump(global.surfaces)
        --    dump(new)
        return new
    end,

    add_resource = function(self, data)
        debug(data.name)
        local r = Resource.new(data, self)
        table.insert(self.resources, r)
    end,

    load_default_resources = function(self)
        --dump(global.vanilla)
        for _,v in ipairs(global.vanilla) do
            self:add_resource(v)
        end
        --for _,v in pairs(game.entity_prototypes) do
        --    if v.type == 'resource' then
        --        table.insert(self.resources, Resource.new(v, self))
        --        --debug(v.name)
        --        -- add Resource for it
        --    end
        --end
    end,

    init_all = function()
        for _, s in ipairs(global.surfaces) do
            RSO_Surface.init(s)
        end
    end,

    init = function(surface)
        setmetatable(surface, {__index = RSO_Surface })
        --for _,r in ipairs(surface.regions) do
        --    Region.init(r)
        --end
        --return surface
    end,

    load = function(self)
        --for _, region in ipairs(self.regions) do
        --  Region.init(region)
        --  Region.load(region)
        --end
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
        local x = chunk.left_top.x
        local y = chunk.left_top.y
        --local region = Region.get_by_chunk(self, chunk)
        local region = self:get_region(chunk.left_top)
        self:remove_resources(chunk)
        self:remove_enemies(chunk)
    end,

    get_region = function(self, position)
        --local size = global.settings.region_size * CHUNK_SIZE
        local size = Settings.REGION_SIZE
        --debug(size)
        local rx = math.floor(position.x/size) * size
        local ry = math.floor(position.y/size) * size

        for _,r in ipairs(self.regions) do
            if r.area.left_top.x == rx and r.area.left_top.y == ry then
                table.insert(r.chunks,chunk)
                if #r.chunks == global.settings.region_size * global.settings.region_size - 1 then
                    --debug("region full")
                end
                return r
            end
        end
        --debug("new region \nsize: "..size.." x: "..x.." rx: "..rx.." y: "..y.." ry: "..ry)
        --r = Region.new(RSO_Surface, area)
        --dump(r)
        local r = self:create_region({x = rx, y = ry})
        return r
    end,

    create_region = function(self, position)
        local region = {}
        region.area = {
            left_top = { x = position.x, y = position.y },
            right_bottom = { x = position.x + Settings.REGION_SIZE, y = position.y + Settings.REGION_SIZE },
        }
        region.chunks = {}
        table.insert(self.regions, region)
        --dump(region)
        return region
    end,

    calculate_spawns = function(self, region)
        local offset = {
            x = region.left_top.x - self.shift.x,
            y = region.left_top.y - self.shift.y
        }

        region.rng = Random.init(bit32.bxor(offset.x, offset.y))
    end,

    remove_resources = function(self, chunk)
        if self.settings.remove_resources then
            for _,ent in ipairs(self.surface.find_entities_filtered({area=chunk, type='resource'})) do
                ent.destroy()
            end
        end
    end,

    remove_enemies = function(self, chunk)
        if self.settings.remove_enemies then
            for _,ent in ipairs(self.surface.find_entities_filtered({area=chunk, force='enemy'})) do
                ent.destroy()
            end
        end
    end,

    call = function(self, name, ...)
        self.surface[name](...);
    end,
}
