require 'util'

Settings = {
    CHUNK_SIZE = 32;
    REGION_SIZE = 0;
    FREQUENCY_MOD = {
        ['very-low'] = 1,
        low = 2,
        normal = 3,
        high = 4,
        ['very-high'] = 5,
    };
    SIZE_MOD = {
        none = 0,
        ['very-small'] = 1,
        small = 2,
        medium = 3,
        big = 4,
        ['very-big'] = 5,
    };
    RICHNESS_MOD = {
        ['very-poor'] = 1,
        poor = 2,
        regular = 3,
        good = 4,
        ['very-good'] = 5,
    };

  new = function()
      local resource_defaults = {
          min_amount = 500,
          richness = 1000,
          size = {min = 12, max = 18 }
      }
    local new = {
        active = false ,
        region_size = 8, -- region size, regions are x*x chunks
        resource_defaults = resource_defaults,
    }
    Settings.REGION_SIZE = new.region_size * Settings.CHUNK_SIZE
    --RES.max_allotment += new.allotment

    setmetatable(new, {__index=Settings})
    return new
  end,

--  init_all = function()
--      for _, s in ipairs(global.surfaces) do
--          Surface.init(s)
--      end
--  end,

  init = function(s)
    setmetatable(s, {__index = Settings })
    return s
  end,

  load = function(self)
  end,

}
