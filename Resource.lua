require 'util'

require "Metaball"

Resource = {
  max_allotment = 0,

  new = function(resource, rsurface)
    local new = {
      type='resource-ore',
      name = 'iron-ore',
      allotment = 50,
      spawns_per_region = { min=1, max=2 },
      richness=1100,
      size={min=12, max=18},
      min_amount=250,
      --surface = rsurface.surface,
      surface = game.surfaces.nauvis

      --starting={richness=6000, size=14, probability=1},

     -- multi_resource_chance=0.50,
     -- multi_resource_generic = true,
     -- multi_resource = nil,

     -- surface = nil
    }
    debug("created resource "..resource.name.." on surface "..new.surface.name)
    --Resource.max_allotment += new.allotment

    setmetatable(new, {__index=Resource})
    return new
  end,

  spawn_ore = function(self, pos, rng)
        local nballs = 1
        local center = {x = pos.x, y = pos.y}
        local balls = {}
        local size = rng:random(self.size.min, self.size.max) -- randomisation needed here
        --local ball_rng = Random.init(game.surfaces['nauvis'].map_gen_settings.seed)
        balls[#balls+1] = Metaball.new(center, size, rng)
        for i=1,nballs do
            ball = Metaball.new(center, size, rng)
            ball:random_walk()
            balls[#balls+1] = ball
        end
        for i=1,nballs do
            ball = Metaball.new(center, size, rng)
            ball.sign = -1
            ball:random_walk()
            balls[#balls+1] = ball
        end
        dump(balls[1].center)
        --game.player.print(#balls)

        --local max = 200
        --local richness = 1000 -- randomization

        -- Generate ore locations
        local ore_locations = {}
        local area = Metaball.bounding_box(balls)
        local total_influence = 0
        for location in Metaball.iterate(area, balls) do
            if self.surface.can_place_entity({
                name = self.name,
                position = { x = location.x, y = location.y }
            }) then
                ore_locations[#ore_locations+1] = location
                total_influence = total_influence + location.total
            end
        end
        debug("#loc: "..#ore_locations)

        -- Spawn ore at locations
        local total = 0
        --local mult = math.abs((res-#ore_locations * min_amount)/ore_locations[#ore_locations].total)
        --debug("mult: "..mult)
        for _,location in ipairs(ore_locations) do
            local settings = {
                name = 'iron-ore',
                position = {location.x, location.y},
                force = game.forces.neutral,
                amount = math.floor( self.min_amount + location.sum * self.richness),
            }
            total = total + settings.amount
            self.surface.create_entity(settings)
        end
        debug("total: "..total)
    end,

--  spawn_liquid = function(surface, pos, startingArea, restrictions)
--    rname = self.name
--    size = self.size
--    richness = self.richness
--	restrictions = restrictions or ''
--	debug("Entering spawn_resource_liquid "..rname.." "..pos.x..","..pos.y.." "..size.." "..richness.." "..tostring(startingArea).." "..restrictions)
--	local _total = 0
--	local max_radius = rgen:random()*CHUNK_SIZE/2 + CHUNK_SIZE
--	--[[
--		if restrictions == 'xy' then
--		-- we have full 4 chunks
--		max_radius = floor(max_radius*1.5)
--		size = floor(size*1.2)
--		end
--	]]--
--	-- don't reduce amount of liquids - they are already infinite
--	--  size = modify_resource_size(size)
--	
--	richness = richness * size
--	
--	local total_share = 0
--	local avg_share = 1/size
--	local angle = rgen:random()*pi*2
--	local saved = 0
--	while total_share < 1 do
--		local new_share = vary_by_percentage(avg_share, 0.25)
--		if new_share + total_share > 1 then
--			new_share = 1 - total_share
--		end
--		total_share = new_share + total_share
--		if new_share < avg_share/10 then
--			-- too small
--			break 
--		end
--		local amount = floor(richness*new_share) + saved
--		--if amount >= game.entity_prototypes[rname].minimum then 
--		if amount >= config[rname].minimum_amount then 
--			saved = 0
--			for try=1,5 do
--				local dist = rgen:random()*(max_radius - max_radius*0.1)
--				angle = angle + pi/4 + rgen:random()*pi/2
--				local x, y = pos.x + cos(angle)*dist, pos.y + sin(angle)*dist
--				if surface.can_place_entity{name = rname, position = {x,y}} then
--					debug("@ "..x..","..y.." amount: "..amount.." new_share: "..new_share.." try: "..try)
--					_total = _total + amount
--					surface.create_entity{name = rname,
--						position = {x,y},
--						force = game.forces.neutral,
--						amount = floor(amount*global_richness_mult),
--					direction = rgen:random(4)}
--					break
--				elseif not startingArea then -- we don't want to make ultra rich nodes in starting area - failing to make them will add second spawn in different location
--					entities = surface.find_entities_filtered{area = {{x-2.75, y-2.75}, {x+2.75, y+2.75}}, name=rname}
--					if entities and #entities > 0 then
--						_total = _total + amount
--						for k, ent in pairs(entities) do
--							ent.amount = ent.amount + floor(amount/#entities)
--						end
--						break
--					end
--				end
--			end
--		else
--			saved = amount
--		end
--	end
--	debug("Total amount: ".._total)
--	debug("Leaving spawn_resource_liquid")
--	return _total
--end
}
