require 'util'
_M = {}

data = {
    extend = function(self, new_data)
        if remote.interfaces['RSO_Surface'] and remote.interfaces['RSO_Surface'].add_resource then
            for _,v in ipairs(new_data) do
                remote.call("RSO_Surface", "add_resource", game.surfaces.nauvis, v)
            end
        else
            --debug("data:extend adding to global.vanilla")
            if global.vanilla == nil then
                global.vanilla = {}
            end
            --table.insert(global.vanilla, function(name); remote.call("RSO_Surface", "add_resource", name, new_data); end)
            for _,v in ipairs(new_data) do
                table.insert(global.vanilla, v)
            end
        end
    end,
}

setmetatable(_M, {__index = data})
return _M
