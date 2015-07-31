require 'util'

require "Region"



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
      --settings['remove_resources'] = true,
      --settings.remove_enemies = true,
    }
    --RES.max_allotment += new.allotment

    setmetatable(new, {__index=RSO_Surface})
    table.insert(global.surfaces, new)
    dump(global.surfaces)
    dump(new)
    return new
  end,

  init_all = function()
      for _, s in ipairs(global.surfaces) do
          RSO_Surface.init(s)
      end
  end,

  init = function(surface)
    setmetatable(surface, {__index = RSO_Surface })
    for _,r in ipairs(surface.regions) do
        Region.init(r)
    end
    --return surface
  end,

  load = function(self)
    for _, region in ipairs(self.regions) do
      Region.init(region)
      Region.load(region)
    end
  end,

  get_surface_by_name = function(name)
    for _, s in ipairs(global.surfaces) do
      if s.name == name then
        return s
      end
    end
    local s = RSO_Surface.new(game.surfaces[name])
    return s
  end,

  wall = function(self)
      self.surface.create_entity({name='stone-wall', position = {0,0}})
  end,

  process_chunk = function(self, chunk)
      local x = chunk.left_top.x
      local y = chunk.left_top.y
      local region = Region.get_by_chunk(self, chunk)
      self:remove_resources(chunk)
      self:remove_enemies(chunk)
      region:wall()
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
}
