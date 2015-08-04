require 'util'

MOD_SIZE_MIN = 0.5
MOD_SIZE_MAX = 1
MOD_DONUT_RANGE_MIN = -1
MOD_DONUT_RANGE_MAX = 1
MOD_DONUT_MAX = 2/3
MOD_SHEAR_MAX = 2

RANDOM_WALK_MIN = 10
RANDOM_WALK_MAX = 20

SUM_CUTOFF = 0.01

once = false
counter = 0

Metaball = {

  new = function(pos, size, rng)
    local r_ball = rng:random(MOD_SIZE_MIN * size, MOD_SIZE_MAX * size)
    local donut_ratio = rng:random(MOD_DONUT_RANGE_MIN, MOD_DONUT_RANGE_MAX)
    if donut_ratio >=MOD_DONUT_MAX then
        donut_ratio = MOD_DONUT_MAX
    elseif donut_ratio <0 then
        donut_ratio = 0
    end
    --debug(donut_ratio)

    local new = {
        rng = rng,
        center = {
            x = pos.x,
            y = pos.y,
        },
        --x = 0, --pos.x,
        --y = 0, --pos.y,
        radius = {
            out = r_ball * ( 1 - donut_ratio ),
            inner = r_ball * donut_ratio,
            total = r_ball,
        },
        shear = rng:random(1/MOD_SHEAR_MAX, MOD_SHEAR_MAX),
        alpha = rng:random(0,math.pi),
        --donut_ratio = donut_ratio,
        sign = 1,
        edge = rng:random(),
    }
    setmetatable(new, {__index = Metaball})
    new:calculate_area()
    --dump(new)
    --debug(serpent.block(new))
    return new
  end,

  get_influence = function(self, pos)
      -- ball = {
      --  radius = 0..inf
      --  x = center coordinate
      --  y = center coordinate
      --  alpha = 0..2pi --rotation (counter clockwise) in radians
      --  donut ratio = -2/3..2/3 donut_ratio. 0 -> normal, 1->donut with infinite small edge; <0 -> normal
      --  scale_x = 0..inf scale in x direction: >1 -> bigger; <1 -> smaller
      --              this increases the outer radius in that direction!
      --  scale_y same as x
      --  shape = ['square', 'donut', 'ellipse']
      --  sharpness = 0..inf sharpness of the blop; <1 means wider; >1 means sharper
      --  neg = true/false; if ture, output Influence will be negative

--      if x>4*self.radius.out or y>4*self.radius.out then
--          --return 0;
--      end
      if self:outside(pos) then
          return 0
      end

      --local x_shift = (pos.x - self.x)
      --local y_shift = (pos.y - self.y)
      --local x_rot = x_shift * math.cos(self.alpha) - y_shift * math.sin(self.alpha)
      --local y_rot = y_shift * math.cos(self.alpha) + x_shift * math.sin(self.alpha)
      local rot = rotate(pos, self.center, self.alpha)
      local xs = rot.x/self.shear
      local ys = rot.y*self.shear
--      if not once and counter==2 then
--          debug(serpent.dump(self))
--          debug(serpent.block(pos)..serpent.block(self.center))
--          --debug("xs: "..x_rot.." ys: "..y_rot.." xrot: "..rot.x.." yrot: "..rot.y)
--          debug("xs: "..x_shift.." ys: "..y_shift.." xrot: "..rot.xs.." yrot: "..rot.ys)
--          once = true
--      else
--          counter = counter + 1
--      end
--      local xs = pos.x/self.shear
--      local ys = pos.y*self.shear
--      if xs>2*self.radius.out or ys>2*self.radius.out then
--          --return 0;
--      end
      local circle_r = math.sqrt( xs^2 + ys^2)
      local square_r = ( xs^4 + ys^4)^(1/4)
      local r = math.abs( self.radius.inner - ( 1 - self.edge ) * circle_r - self.edge * square_r ) / self.radius.out
      --debug("r: "..r.." circle_r: "..circle_r.." square_r: "..square_r.." x: "..self.x.."pos_x: "..pos.x)
      if r>=1 then
          return 0
      end
      local res = 1 - r * r * r * ( r * ( r * 6.0 - 15 ) + 10 )
      --debug("r: "..r.." res: "..res.." circle_r: "..circle_r.." square_r: "..square_r.." x: "..self.x.."pos_x: "..pos.x)
      --debug("x_rot: "..x_rot.." xs: "..xs.." shear: "..self.shear)
      return self.sign * res
  end,

  random_walk = function(self)
      alpha = self.rng:random(0,math.pi)
      distance = self.rng:random(RANDOM_WALK_MIN, RANDOM_WALK_MAX)
      x_shift =   distance * math.cos(alpha)
      y_shift = - distance * math.sin(alpha)
      self.center.x = self.center.x + x_shift
      self.center.y = self.center.y + y_shift
      --self.center.x = self.x
      --self.center.y = self.y
      self:calculate_area()
  end,

  sum = function(pos, balls)
      local sum = 0
      --debug("entering sum")
      for _, ball in ipairs(balls) do
          --debug(sum)
          sum = sum + ball:get_influence(pos);
      end
      --debug(sum)
      return sum
  end,

  iterate = function(area, balls)
      debug("enter iterate")
      local sum = 0;
      total = 0
      x = area.left_top.x;
      y = area.left_top.y;

      return function()
          --debug("iterating")
          --debug(x,y)
          found = false;
          while found == false do
              x = x + 1;
              if x >area.right_bottom.x then
                  x = area.left_top.x;
                  y = y + 1;
                  if y>area.right_bottom.y then
                      debug("total: "..total)
                      return nil
                  end
              end
              sum = Metaball.sum({x=x, y=y}, balls)
              --if sum => 0 and sum <= 1 then
              if sum > SUM_CUTOFF then
                  total = total + sum
                  --debug("x: "..x.." y: "..y.." sum: "..sum)
                  return {x=x, y=y, sum=sum, total=total}
              end
          end
      end
  end,

  init = function(s)
    setmetatable(s, {__index = Metaball })
    return s
  end,

  calculate_area = function(self)
    local width = (math.abs(math.cos(self.alpha) * self.radius.total * self.shear) + math.abs(math.sin(self.alpha) * self.radius.total/self.shear))
    local height = (math.abs(math.cos(self.alpha) * self.radius.total / self.shear) + math.abs(math.sin(self.alpha) * self.radius.total * self.shear))
    --debug("w: "..width.." h: "..height)
    self.area = {
          left_top = {
              x = math.floor(self.center.x - width),
              y = math.floor(self.center.y - height),
          },
          right_bottom = {
              x = math.ceil(self.center.x + width),
              y = math.ceil(self.center.y + height)+0,
          },
      }
  end,

  outside = function(self, pos)
      if pos.x > self.area.right_bottom.x or pos.x < self.area.left_top.x or
          pos.y > self.area.right_bottom.y or pos.y < self.area.left_top.y then
          return True
      else
          return False
      end
  end,

  bounding_box = function(balls)
      local area = {
          left_top = {
              x = 0,
              y = 0,
          },
          right_bottom = {
              x = 0,
              y = 0,
          },
      }
      for _,ball in ipairs(balls) do
          area.left_top.x = math.min(area.left_top.x, ball.area.left_top.x)
          area.left_top.y = math.min(area.left_top.y, ball.area.left_top.y)
          area.right_bottom.x = math.max(area.right_bottom.x, ball.area.right_bottom.x)
          area.right_bottom.y = math.max(area.right_bottom.y, ball.area.right_bottom.y)
      end
      return area
  end,
}
