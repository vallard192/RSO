require 'util'

local CHUNK_SIZE = 32

local max = 0

Region = {

    new = function(RSO_Surface, area)
        if RSO_Surface == nil then
            debug(serpent.block(s))
        end
        local new = {
            surface = RSO_Surface,
            chunks = {},
            area = area,
            center = {
                (area.left_top.x + area.right_bottom.x ) / 2,
                (area.left_top.y + area.right_bottom.y ) / 2
            },
            spawns = {},
            size = global.settings.region_size

        }
        --RES.max_allotment += new.allotment

        setmetatable(new, {__index=Region})
        table.insert(RSO_Surface.regions, new)
        --RSO_Surface.surface.request_to_generate_chunks(new.center, new.size * CHUNK_SIZE /2 )
        --dump(new)
        --dump(RSO_Surface)
--        if RSO_Surface == new.surface then
--            message('they match')
--        else
--            message('they dont match')
--        end
        return new
    end,

    --  init_all = function()
    --      for _, s in ipairs(global.surfaces) do
    --          Surface.init(s)
    --      end
    --  end,

    init = function(region)
        setmetatable(region, {__index = Region })
        return region
        --return surface
    end,
    wall = function(self)
        self.surface.surface.create_entity({
            name='stone-wall',
            position = {
                (self.area.left_top.x + self.area.right_bottom.x ) / 2,
                (self.area.left_top.y + self.area.right_bottom.y ) / 2
            }
        })
    end,

    get_by_chunk = function(RSO_Surface, chunk)
        local x = chunk.left_top.x
        local y = chunk.left_top.y
        local size = global.settings.region_size * CHUNK_SIZE
        local rx = math.floor(x/size) * size
        local ry = math.floor(y/size) * size
        local area = {left_top = { x = rx, y = ry }, right_bottom = {x = rx + size, y =ry + size}}
        for _,r in ipairs(RSO_Surface.regions) do
            if r.area.left_top.x == rx and r.area.left_top.y == ry then
                table.insert(r.chunks,chunk)
                --if r.surface ~= RSO_Surface then
                --    debug("surface and RSO_Surface don't match")
                --else
                --    debug("gbc: surface and RSO_Surface match")
                --    --debug(serpent.block(s.surface))
                --end
                    --debug(#r.chunks)
                    if #r.chunks > max then
                        max = #r.chunks
                        --debug(max)
                    end
                if #r.chunks == global.settings.region_size * global.settings.region_size - 1 then
                    --debug("region full")
                end
                return r
            end
        end
        --debug("new region \nsize: "..size.." x: "..x.." rx: "..rx.." y: "..y.." ry: "..ry)
        r = Region.new(RSO_Surface, area)
        --dump(r)
        return r
    end
}
