
RES = {
  max_allotment = 0,

  new = function(player, ent)
    local vehicle, driver = nil, false
    if ent then
      vehicle = ent
    else
      vehicle = player.vehicle
      driver = player
    end
    local new = {
      type='resource-ore',
      allotment = 50,
      name = 'stone',
      spawns_per_region = { min=1, max=2 },
      richness=11000,
      size={min=12, max=18},
      min_amount=250,

      starting={richness=6000, size=14, probability=1},

      multi_resource_chance=0.50,
      multi_resource_generic = true,
      multi_resource = nil,

      surface = nil
    }
    RES.max_allotment += new.allotment

    new.settings = Settings.loadByPlayer(player)
    setmetatable(new, {__index=FARL})
    return new
  end,
  spawn_ore = function spawn(self, pos, surface, startingArea, restrictions)
    -- blob generator, centered at pos, size controls blob diameter
    rname = self.name
    size = self.size
    richness = self.richness
    surface = surface or self.surface
    restrictions = restrictions or ''
    debug("Entering spawn_resource_ore "..rname.." at:"..pos.x..","..pos.y.." size:"..size.." richness:"..richness.." isStart:"..tostring(startingArea).." restrictions:"..restrictions)

    size = modify_resource_size(rname, size, startingArea)
    local radius = size/2 -- to radius

    local p_balls={}
    local n_balls={}
    local MIN_BALL_DISTANCE = math.min(MIN_BALL_DISTANCE, radius/2)

    local outside = { xmin = 1e10, xmax = -1e10, ymin = 1e10, ymax = -1e10 }
    local inside = { xmin = 1e10, xmax = -1e10, ymin = 1e10, ymax = -1e10 }

    local function adjustRadius(radius, scaleX, scaleY, up)
      if scaleX < 1 then
        scaleX = 1
      end
      if scaleY < 1 then
        scaleY = 1
      end

      if up then
        return radius * math.max(scaleX, scaleY)
      else
        return radius / math.max(scaleX, scaleY)
      end
    end

    local function updateRect(rect, x, y, radius)
      rect.xmin = math.min(rect.xmin, x - radius)
      rect.xmax = math.max(rect.xmax, x + radius)
      rect.ymin = math.min(rect.ymin, y - radius)
      rect.ymax = math.max(rect.ymax, y + radius)
    end

    local function updateRects(x, y, radius, scaleX, scaleY)
      local adjustedRadius = adjustRadius(radius, scaleX, scaleY, true)
      local radiusMax = adjustedRadius * 3 -- arbitrary multiplier - needs to be big enough to not cut any metaballs
      updateRect(outside, x, y, radiusMax)
      updateRect(inside, x, y, adjustedRadius)
    end

    local function generate_p_ball()
      local angle, x_scale, y_scale, x, y, b_radius, shape
      angle, x_scale, y_scale=rng_restricted_angle(restrictions)
      local dev = rgen:random(radius/8, radius/2)--math.min(CHUNK_SIZE/3, radius*1.5)
      local dev_x, dev_y = pos.x, pos.y
      x = rgen:random(-dev, dev)+dev_x
      y = rgen:random(-dev, dev)+dev_y
      if p_balls[#p_balls] and distance(p_balls[#p_balls], {x=x, y=y}) < MIN_BALL_DISTANCE then
        local new_angle = bearing(p_balls[#p_balls], {x=x, y=y})
        debug("Move ball old xy @ "..x..","..y)
        x=(cos(new_angle)*MIN_BALL_DISTANCE) + x
        y=(sin(new_angle)*MIN_BALL_DISTANCE) + y
        debug("Move ball new xy @ "..x..","..y)
      end

      b_radius = (radius / 2 + rgen:random()* radius / 4) -- * (P_BALL_SIZE_FACTOR^#p_balls)

      if #p_balls > 0 then
        local tempRect = table.deepcopy(inside)
        updateRect(tempRect, x, y, adjustRadius(b_radius, x_scale, y_scale))
        local rectSize = math.max(tempRect.xmax - tempRect.xmin, tempRect.ymax - tempRect.ymin)
        local targetSize = size
        debug("Rect size "..rectSize.." targetSize "..targetSize)
        if rectSize > targetSize then
          local widthLeft = (targetSize - (inside.xmax - inside.xmin))
          local heightLeft = (targetSize - (inside.ymax - inside.ymin))
          local widthMod = math.min(x - inside.xmin, inside.xmax - x)
          local heightMod = math.min(y - inside.ymin, inside.ymax - y)
          local radiusBackup = b_radius
          b_radius = math.min(widthLeft + widthMod, heightLeft + heightMod)
          b_radius = adjustRadius(b_radius, x_scale, y_scale, false)
          debug("Reduced ball radius from "..radiusBackup.." to "..b_radius.." widthLeft:"..widthLeft.." heightLeft:"..heightLeft.." widthMod:"..widthMod.." heightMod:"..heightMod)
        end
      end

      if b_radius > 2 then
        shape = meta_shapes[rgen:random(1,#meta_shapes)]
        local radiusText = ""
        if shape.type == "MetaDonut" then
          local inRadius = b_radius / 4 + b_radius / 2 * rgen:random()
          radiusText = " inRadius:"..inRadius
          p_balls[#p_balls+1] = shape:new(x, y, b_radius, inRadius, angle, x_scale, y_scale, 1.1)
        else
          p_balls[#p_balls+1] = shape:new(x, y, b_radius, angle, x_scale, y_scale, 1.1)
        end
        updateRects(x, y, b_radius, x_scale, y_scale)

        debug("P+Ball "..shape.type.." @ "..x..","..y.." radius: "..b_radius..radiusText.." angle: "..math.deg(angle).." scale: "..x_scale..", "..y_scale)
      else
        debug("Resource size "..b_radius.." to low - spawn skipped")
      end
    end

    local function generate_n_ball(i)
      local angle, x_scale, y_scale, x, y, b_radius, shape
      angle, x_scale, y_scale=rng_restricted_angle('xy')
      if p_balls[i] then
        local new_angle = p_balls[i].angle + pi*rgen:random(0,1) + (rgen:random()-0.5)*pi/2
        local dist = p_balls[i].radius
        x=(cos(new_angle)*dist) + p_balls[i].x
        y=(sin(new_angle)*dist) + p_balls[i].y
        angle = p_balls[i].angle + pi/2 + (rgen:random()-0.5)*pi*2/3
      else
        x = rgen:random(-radius, radius)+pos.x
        y = rgen:random(-radius, radius)+pos.y
      end
      b_radius = (radius / 4 + rgen:random() * radius / 4) -- * (N_BALL_SIZE_FACTOR^#n_balls)

      shape = meta_shapes[rgen:random(1,#meta_shapes)]
      local radiusText = ""
      if shape.type == "MetaDonut" then
        local inRadius = b_radius / 4 + b_radius / 2 * rgen:random()
        radiusText = " inRadius:"..inRadius
        n_balls[#n_balls+1] = shape:new(x, y, b_radius, inRadius, angle, x_scale, y_scale, 1.2)
      else
        n_balls[#n_balls+1] = shape:new(x, y, b_radius, angle, x_scale, y_scale, 1.2)
      end
      -- updateRects(x, y, b_radius, x_scale, y_scale) -- should not be needed here - only positive ball can generate ore
      debug("N-Ball "..shape.type.." @ "..x..","..y.." radius: "..b_radius..radiusText.." angle: "..math.deg(angle).." scale: "..x_scale..", "..y_scale)
    end

    local function calculate_force(x,y)
      local p_force = 0
      local n_force = 0
      for _,ball in ipairs(p_balls) do
        p_force = p_force + ball:force(x,y)
      end
      for _,ball in ipairs(n_balls) do
        n_force = n_force + ball:force(x,y)
      end
      local totalForce = 0
      if p_force > n_force then
        totalForce = 1 - 1/(p_force - n_force)
      end
      --debug("Force at "..x..","..y.." p:"..p_force.." n:"..n_force.." result:"..totalForce)
      --return (1 - 1/p_force) - n_force
      return totalForce
    end

    local max_p_balls = 2
    local min_amount = config[rname].min_amount or min_amount
    if restrictions == 'xy' then
      -- we have full 4 chunks
      radius = math.min(radius*1.5, CHUNK_SIZE/2)
      richness = richness*2/3
      min_amount = min_amount / 3
      max_p_balls = 3
    end

    local force
    -- generate blobs
    for i=1,max_p_balls do
      generate_p_ball()
    end

    for i=1,rgen:random(1, #p_balls) do
      generate_n_ball(i)
    end

    local _a = {}
    local _total = 0
    local oreLocations = {}
    local forceTotal = 0

    -- fill the map
    --  for y=pos.y-CHUNK_SIZE*2, pos.y+CHUNK_SIZE*2-1 do
    for y=outside.ymin, outside.ymax do
      local _b = {}
      _a[#_a+1] = _b
      --    for x=pos.x-CHUNK_SIZE*2, pos.x+CHUNK_SIZE*2-1 do
      for x=outside.xmin, outside.xmax do
        if surface.get_tile(x,y).valid then
          force = calculate_force(x, y)
          if force > 0 then
            --debug("@ "..x..","..y.." force: "..force.." amount: "..amount)
            if not surface.get_tile(x,y).collides_with("water-tile") and surface.can_place_entity{name = rname, position = {x,y}} then
              _b[#_b+1] = '#'
              oreLocations[#oreLocations + 1] = {x = x, y = y, force = force}
              forceTotal = forceTotal + force
              --          elseif not startingArea then -- we don't want to make ultra rich nodes in starting area - failing to make them will add second spawn in different location
              --            entities = game.find_entities_filtered{area = {{x-2.75, y-2.75}, {x+2.75, y+2.75}}, name=rname}
              --            if entities and #entities > 0 then
              --              _b[#_b+1] = 'O'
              --              _total = _total + amount
              --              for k, ent in pairs(entities) do
              --                ent.amount = ent.amount + floor(amount/#entities)
              --              end
              --            else
              --              _b[#_b+1] = '.'
              --            end
            else
              _b[#_b+1] = 'c'
            end
          else
            _b[#_b+1] = '<'
          end
        else
          _b[#_b+1] = 'x'
        end
      end
    end

    if #oreLocations > 0 then

      local minSize = richness * 10
      local maxSize = richness * 20
      local approxDepositSize = rgen:random(minSize, maxSize)

      local forceFactor = approxDepositSize / forceTotal

      -- don't create very dense resources in starting area - another field will be generated
      if startingArea and forceFactor > 4000 then
        forceFactor = rgen:random(3000, 4000)
      elseif forceFactor > 25000 then -- limit size of one resource pile
        forceFactor = rgen:random(20000, 25000)
      end

      debug( "Force total:"..forceTotal.." sizeMin:"..minSize.." sizeMax:"..maxSize.." factor:"..forceFactor.." location#:"..#oreLocations)

      for _,location in ipairs(oreLocations) do
        --    local amount=floor((richness*location.force*(0.8^#p_balls)) + min_amount)
        local amount=floor(forceFactor*location.force + min_amount)
        _total = _total + amount
        surface.create_entity{
          name = rname,
          position = {location.x,location.y},
          force = game.forces.neutral,
          amount = floor(amount*global_richness_mult)
        }
      end
    end

    if debug_enabled then
      debug("Total amount: ".._total)
      for _,v in pairs(_a) do
        --output a nice ASCII map
        --debug(table.concat(v))
      end
      debug("Leaving spawn_resource_ore")
    end
    return _total
  end, -- end spawn_ore

  spawn_liquid = function(surface, pos, startingArea, restrictions)
    rname = self.name
    size = self.size
    richness = self.richness
	restrictions = restrictions or ''
	debug("Entering spawn_resource_liquid "..rname.." "..pos.x..","..pos.y.." "..size.." "..richness.." "..tostring(startingArea).." "..restrictions)
	local _total = 0
	local max_radius = rgen:random()*CHUNK_SIZE/2 + CHUNK_SIZE
	--[[
		if restrictions == 'xy' then
		-- we have full 4 chunks
		max_radius = floor(max_radius*1.5)
		size = floor(size*1.2)
		end
	]]--
	-- don't reduce amount of liquids - they are already infinite
	--  size = modify_resource_size(size)
	
	richness = richness * size
	
	local total_share = 0
	local avg_share = 1/size
	local angle = rgen:random()*pi*2
	local saved = 0
	while total_share < 1 do
		local new_share = vary_by_percentage(avg_share, 0.25)
		if new_share + total_share > 1 then
			new_share = 1 - total_share
		end
		total_share = new_share + total_share
		if new_share < avg_share/10 then
			-- too small
			break 
		end
		local amount = floor(richness*new_share) + saved
		--if amount >= game.entity_prototypes[rname].minimum then 
		if amount >= config[rname].minimum_amount then 
			saved = 0
			for try=1,5 do
				local dist = rgen:random()*(max_radius - max_radius*0.1)
				angle = angle + pi/4 + rgen:random()*pi/2
				local x, y = pos.x + cos(angle)*dist, pos.y + sin(angle)*dist
				if surface.can_place_entity{name = rname, position = {x,y}} then
					debug("@ "..x..","..y.." amount: "..amount.." new_share: "..new_share.." try: "..try)
					_total = _total + amount
					surface.create_entity{name = rname,
						position = {x,y},
						force = game.forces.neutral,
						amount = floor(amount*global_richness_mult),
					direction = rgen:random(4)}
					break
				elseif not startingArea then -- we don't want to make ultra rich nodes in starting area - failing to make them will add second spawn in different location
					entities = surface.find_entities_filtered{area = {{x-2.75, y-2.75}, {x+2.75, y+2.75}}, name=rname}
					if entities and #entities > 0 then
						_total = _total + amount
						for k, ent in pairs(entities) do
							ent.amount = ent.amount + floor(amount/#entities)
						end
						break
					end
				end
			end
		else
			saved = amount
		end
	end
	debug("Total amount: ".._total)
	debug("Leaving spawn_resource_liquid")
	return _total
end
}
