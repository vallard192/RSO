require 'util'

Settings = {
    CHUNK_SIZE = 32;
    REGION_SIZE = 0;

  new = function()
    local new = {
        active = false ,
        region_size = 8, -- region size, regions are x*x chunks
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
