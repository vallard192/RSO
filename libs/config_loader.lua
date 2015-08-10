require 'util'

RSO = { -- TODO: It should be possible to add a resource to a surface or to the general RSO configuration
    add_resource = function(name)
        local resource = global.rso_resources[name]
        if remote.interfaces['RSO_Surface'] and remote.interfaces['RSO_Surface'].add_resource then
            remote.call("RSO_Surface", "add_resource", game.surfaces.nauvis, v) 
        else
            error("RSO_Surface isn't found. Make sure you are using the right version of RSO and specifying it as dependency")
        end
    end,
}


_M = {}

data = {
    extend = function(self, new_data)
        if remote.interfaces['RSO_Surface'] and remote.interfaces['RSO_Surface'].add_resource then
            for _,v in ipairs(new_data) do
                remote.call("RSO_Surface", "add_resource", game.surfaces.nauvis, v)
            end
        else
            --debug("data:extend adding to global.vanilla")
            if global.rso_resources == nil then
                global.rso_resources = {}
            end
            --table.insert(global.vanilla, function(name); remote.call("RSO_Surface", "add_resource", name, new_data); end)
            for _,v in ipairs(new_data) do
                global.rso_resources[v.name] = v
            end
        end
    end,
}

setmetatable(_M, {__index = data})
return _M

