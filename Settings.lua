local function print(msg)
    game.player.print(msg)
end

local function dump(obj)
    game.player.print(serpent.dump(obj))
end

Settings = {

  new = function()
    local new = {
        active = false ,
        region_size = 8, -- region size, regions are x*x chunks
    }
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
