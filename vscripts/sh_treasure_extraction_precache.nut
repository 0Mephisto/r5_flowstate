global function ShPrecacheTreasureExtractionAssets

void function ShPrecacheTreasureExtractionAssets()
{
	PrecacheObjectiveAsset_Model( "TREASUREEXTRACT_MODEL_USABLE_BUTTON", $"mdl/props/treasure_hunt_drill/treasure_hunt_drill.rmdl" )
	PrecacheObjectiveAsset_FX( "TREASUREEXTRACT_FX_EXTRACTION_COMPLETE", $"veh_jetwash_dirt" )	//$"env_thumper_hit_LG_full" //can also try env_thumper_hit_LG_full or veh_jetwash_dirt
	PrecacheObjectiveAsset_Model( "TREASUREEXTRACT_MODEL_DRILL_BASE", $"mdl/props/treasure_hunt_drill/treasure_hunt_drill.rmdl" )
	PrecacheObjectiveAsset_Model( "TREASUREEXTRACT_MODEL_TREASURE_CASE", $"mdl/props/treasure_hunt_drill_box/treasure_hunt_drill_box.rmdl" )
	PrecacheObjectiveAsset_FX( "HARVESTER_FX_EXTRACTION_BEAM", $"P_drone_frag_warn_beams" )
	PrecacheObjectiveAsset_FX( "HARVESTER_FX_PLANT", $"veh_jetwash_dirt" )	// $"env_thumper_hit_LG_full" // veh_jetwash_dirt
}