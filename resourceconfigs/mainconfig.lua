require("resourceconfigs.vanilla")  -- vanilla ore/liquids (no enemies)
require("resourceconfigs.vanilla_enemies")
require("resourceconfigs.roadworks")
require("resourceconfigs.dytech")
require("resourceconfigs.bobores")
require("resourceconfigs.peacemod")
require("resourceconfigs.yuoki_industries")
require("resourceconfigs.mopower")
require("resourceconfigs.replicators")
require("resourceconfigs.uraniumpower")
require("resourceconfigs.groundsulfur")
require("resourceconfigs.evolution")
require("resourceconfigs.replicators")


function loadResourceConfig()
	
	config={}
	
	fillVanillaConfig()
	
	--[[ MODS SUPPORT ]]--
	if not game.entityprototypes["alien-ore"] or useEnemiesInPeaceMod then  -- if the user has peacemod installed he probably doesn't want that RSO spawns them either. remote.interfaces["peacemod"]
		fillEnemies()
	end
	
	-- Roadworks mod
	if game.entityprototypes["RW_limestone"] then
		fillRoadworksConfig()
	end
	
	-- DyTech
	-- i moved everything even the checks there, i think it's cleaner this way
	fillDytechConfig()
	
	-- BobOres
	if game.entityprototypes["rutile-ore"] then
		fillBoboresConfig()
	end
	
	-- peace mod
	if game.entityprototypes["alien-ore"] then
		fillPeaceConfig()
	end  
	
	--yuoki industries mod
	if game.entityprototypes["y-res1"] then
		fillYuokiConfig()
	end
	
	--mopower mod
	if game.entityprototypes["uranium-ore"] then
		fillMopowerConfig()
	end
	
	--replicators mod
	if game.entityprototypes["rare-earth"] then
		fillReplicatorsConfig()
	end
	
	--uranium power mod
	if game.entityprototypes["uraninite"] then
		fillUraniumpowerConfig()
	end

	-- ground sulfur
	if game.entityprototypes["sulfur"] then
		fillGroundSulfurConfig()
	end
	
	-- evolution
	if game.entityprototypes["alien-artifacts"] then
		fillEvolutionConfig()
	end
	
	-- replicators
	if game.entityprototypes["creatine"] then
		fillReplicatorsConfig()
	end

	return config
end