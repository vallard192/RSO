require("config")
require("prototypes.prototype_utils")

if data.raw['noise-layer']['rso'] then
    for _, resouce in pairs(data.raw.resource) do
        disable_entity(resource)
    end

    for _, ent in pairs(data.raw['unit-spawner']) do
        disable_entity(ent)
    end

    for _, ent in pairs(data.raw.turret) do
        disable_entity(ent)
    end
end
--if data.raw['noise-layer']['rso'] then
--    disable_entity('iron-ore', 'resource')
--    disable_entity('copper-ore', 'resource')
--    disable_entity('coal', 'resource')
--    disable_entity('stone', 'resource')
--    disable_entity('crude-oil', 'resource')
--    disable_entity('biter-spawner', 'unit-spawner')
--    disable_entity('spitter-spawner', 'unit-spawner')
--    disable_entity('small-worm-turret', 'turret')
--    disable_entity('medium-worm-turret', 'turret')
--    disable_entity('big-worm-turret', 'turret')
--end

data.raw["map-settings"]["map-settings"].enemy_expansion.enabled = not disableEnemyExpansion

if debug_enabled then
    data.raw["car"]["car"].max_health = 0x8000000
    data.raw["ammo"]["basic-bullet-magazine"].magazine_size = 1000
    data.raw["ammo"]["basic-bullet-magazine"].ammo_type.action[1].action_delivery[1].target_effects[2].damage.amount = 5000
end
