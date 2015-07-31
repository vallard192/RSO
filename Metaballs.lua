require 'util'

--local function generate_ball()
--    local ball = {
--        x = 0,
--        y = 0,
--        scale_x = 1,
--        scale_y = 1.5,
--        radius = 10,
--        alpha = 0,
--        shape = ['ellipse'],
--        sharpness = 1,
--        neg = false,
--        donut_ratio = 0.2,
--    }
--    return ball
--end
--
--
--local function MBInfluence(pos, ball)
--    -- ball = {
--    --  radius = 0..inf
--    --  x = center coordinate
--    --  y = center coordinate
--    --  alpha = 0..2pi --rotation (counter clockwise) in radians
--    --  donut ratio = -2/3..2/3 donut_ratio. 0 -> normal, 1->donut with infinite small edge; <0 -> normal
--    --  scale_x = 0..inf scale in x direction: >1 -> bigger; <1 -> smaller
--    --              this increases the outer radius in that direction!
--    --  scale_y same as x
--    --  shape = ['square', 'donut', 'ellipse']
--    --  sharpness = 0..inf sharpness of the blop; <1 means wider; >1 means sharper
--    --  neg = true/false; if ture, output Influence will be negative
--
--    local x = (pos.x - ball.x)
--    local y = (pos.y - ball.y)
--    local x_rot = x * math.cos(ball.alpha) - y * math.sin(ball.alpha)
--    local y_rot = y * math.cos(ball.alpha) + x * math.sin(ball.alpha)
--    local x2 = x_rot/ball.scale_x
--    local y2 = y_rot/ball.scale_y
--    local r
--    if ball.shape == 'square' then
--        r = 1 - math.abs(radius.inner - math.abs(x2) - math.abs(y2))/radius.out
--    elseif ball.shape == 'ellipse' then
--        r = 1 - math.abs(radius.inner - math.sqrt(x2^2 + y2^2))/radius.out
--        --r = 1 - math.sqrt(x2 * x2 + y2 * y2)/radius.out
----    elseif ball.shape == 'donut' then
----        r = 1 - math.abs(radius.inner - math.sqrt(x2 * x2 + y2 * y2))/radius.out
--    end
--    if r<=0 then
--        return 0
--    end
--    res = r * r * r * ( r * ( r * 6.0 - 15 ) + 10 )
--    return sgn * res^ball.sharpness
--end
--
--local function MBSumInfluence(pos, balls)
--    local sum = 0;
--    for _, ball in ipairs(balls) do
--        sum = sum + MBInfluence(pos, ball);
--    end
--    return sum;
--end
--
--local function IterateMetaballs(area, balls)
--    local AREA_X = (- area.left_top.x + area.bottom_right.x)/2
--    local AREA_Y = (- area.left_top.y + area.bottom_right.y)/2
--    sum = 0;
--    total = 0
--    x = area.left_top.x;
--    y = area.left_top.y;
--
--    return function()
--        found = false;
--        while found == false do
--            x = x + 1;
--            if x >area.right_bottom.x then
--                x = area.left_top.x;
--                y = y + 1;
--                if y>area.right_bottom.y then
--                    return nil
--                end
--            end
--            sum = 1-1/MBSumInfluence({x=x, y=y}, balls)
--            total = total + sum
--            if sum => 0 and sum <= 1 then
--                return {x=x, y=y, sum=sum, total=total}
--            end
--        end
--    end
--end
--
MOD_SIZE_MIN = 0.5
MOD_SIZE_MAX = 1
MOD_DONUT_RANGE_MIN = -1
MOD_DONUT_RANGE_MAX = 1
MOD_DONUT_MAX = 2/3
MOD_SHEAR_MAX = 2

RANDOM_WALK_MIN = 10
RANDOM_WALK_MAX = 20

Metaball = {

  new = function(pos, size)
    local r_ball = math.random(MOD_SIZE_MIN * size, MOD_SIZE_MAX * size)
    local donut_ratio = math.random(MOD_DONUT_RANGE_MIN, MOD_DONUT_RANGE_MAX)
    if donut_ratio >=MOD_DONUT_MAX then
        donut_ratio = MOD_DONUT_MAX
    elseif donut_ratio <0 then
        donut_ratio = 0
    end

    local new = {
        x = pos.x,
        y = pos.y,
        radius = {
            out = r_ball * ( 1 - donut_ratio ),
            inner = r_ball * donut_ratio,
        },
        shear = math.random(1/MOD_SHEAR_MAX, MOD_SHEAR_MAX),
        alpha = math.random(0,math.pi),
        donut_ratio = donut_ratio,
        sign = 1,
        edge = math.random(0,1),
    }

    setmetatable(new, {__index = Metaball})
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

      local x_shift = (pos.x - self.x)
      local y_shift = (pos.y - self.y)
      local x_rot = x_shift * math.cos(self.alpha) - y_shift * math.sin(self.alpha)
      local y_rot = y_shift * math.cos(self.alpha) + x_shift * math.sin(self.alpha)
      local xs = x_rot/self.shear
      local ys = y_rot*self.shear
      local circle_r = math.sqrt( xs^2 + ys^2)
      local square_r = ( xs^4 + ys^4)^4
      local r = math.abs( self.radius.inner - ( 1 - self.edge ) * circle_r - self.edge * square_r ) / self.radius.out
      --    if ball.shape == 'square' then
      --        r = 1 - math.abs(radius.inner - math.abs(x2) - math.abs(y2))/radius.out
      --    elseif ball.shape == 'ellipse' then
      --        r = 1 - math.abs(radius.inner - math.sqrt(x2^2 + y2^2))/radius.out
      --r = 1 - math.sqrt(x2 * x2 + y2 * y2)/radius.out
      --    elseif ball.shape == 'donut' then
      --        r = 1 - math.abs(radius.inner - math.sqrt(x2 * x2 + y2 * y2))/radius.out
      --end
      if r>=1 or r<0 then
          return 0
      end
      res = 1 - r * r * r * ( r * ( r * 6.0 - 15 ) + 10 )
      return sign * res
  end,

  random_walk = function(self)
      alpha = math.random(0,math.pi)
      distance = math.random(RANDOM_WALK_MIN, RANDOM_WALK_MAX)
      x_shift =   distance * math.cos(alpha)
      y_shift = - distance * math.sin(alpha)
      self.x += x_shift
      self.y += y_shift
  end,

  sum = function(pos, balls)
      local sum = 0
      for _, ball in ipairs(balls) do
          sum = sum + ball.get_influence(pos);
      end
      return sum
  end,

  iterate = function(area, balls)
      local sum = 0;
      total = 0
      x = area.left_top.x;
      y = area.left_top.y;

      return function()
          found = false;
          while found == false do
              x = x + 1;
              if x >area.right_bottom.x then
                  x = area.left_top.x;
                  y = y + 1;
                  if y>area.right_bottom.y then
                      return nil
                  end
              end
              sum = Metaball.sum({x=x, y=y}, balls)
              total = total + sum
              --if sum => 0 and sum <= 1 then
              if sum => 0 then
                  return {x=x, y=y, sum=sum, total=total}
              end
          end
      end
  end,

  init = function(s)
    setmetatable(s, {__index = Metaball })
    return s
  end,


--  generate_p_ball = function()
--        local angle, x_scale, y_scale, x, y, b_radius, shape
--        angle, x_scale, y_scale = rng_restricted_angle(restrictions)
--        local dev = rgen:random(radius/8, radius/2)--math.min(CHUNK_SIZE/3, radius*1.5)
--        local dev_x, dev_y = pos.x, pos.y
--        x = rgen:random(-dev, dev)+dev_x
--        y = rgen:random(-dev, dev)+dev_y
--        if p_balls[#p_balls] and distance(p_balls[#p_balls], {x=x, y=y}) < MIN_BALL_DISTANCE then
--            local new_angle = bearing(p_balls[#p_balls], {x=x, y=y})
--            debug("Move ball old xy @ "..x..","..y)
--            x=(cos(new_angle)*MIN_BALL_DISTANCE) + x
--            y=(sin(new_angle)*MIN_BALL_DISTANCE) + y
--            debug("Move ball new xy @ "..x..","..y)
--        end
--
--        b_radius = (radius / 2 + rgen:random()* radius / 4) -- * (P_BALL_SIZE_FACTOR^#p_balls)
--
--        if #p_balls > 0 then
--            local tempRect = table.deepcopy(inside)
--            updateRect(tempRect, x, y, adjustRadius(b_radius, x_scale, y_scale))
--            local rectSize = math.max(tempRect.xmax - tempRect.xmin, tempRect.ymax - tempRect.ymin)
--            local targetSize = size
--            debug("Rect size "..rectSize.." targetSize "..targetSize)
--            if rectSize > targetSize then
--                local widthLeft = (targetSize - (inside.xmax - inside.xmin))
--                local heightLeft = (targetSize - (inside.ymax - inside.ymin))
--                local widthMod = math.min(x - inside.xmin, inside.xmax - x)
--                local heightMod = math.min(y - inside.ymin, inside.ymax - y)
--                local radiusBackup = b_radius
--                b_radius = math.min(widthLeft + widthMod, heightLeft + heightMod)
--                b_radius = adjustRadius(b_radius, x_scale, y_scale, false)
--                debug("Reduced ball radius from "..radiusBackup.." to "..b_radius.." widthLeft:"..widthLeft.." heightLeft:"..heightLeft.." widthMod:"..widthMod.." heightMod:"..heightMod)
--            end
--        end
--
--        if b_radius < 3 then
--            b_radius = 3
--        end
--
--        shape = meta_shapes[rgen:random(1,#meta_shapes)]
--        local radiusText = ""
--        if shape.type == "MetaDonut" then
--            local inRadius = b_radius / 4 + b_radius / 2 * rgen:random()
--            radiusText = " inRadius:"..inRadius
--            p_balls[#p_balls+1] = shape:new(x, y, b_radius, inRadius, angle, x_scale, y_scale, 1.1)
--        else
--            p_balls[#p_balls+1] = shape:new(x, y, b_radius, angle, x_scale, y_scale, 1.1)
--        end
--        updateRects(x, y, b_radius, x_scale, y_scale)
--
--        debug("P+Ball "..shape.type.." @ "..x..","..y.." radius: "..b_radius..radiusText.." angle: "..math.deg(angle).." scale: "..x_scale..", "..y_scale)
--    end

}
