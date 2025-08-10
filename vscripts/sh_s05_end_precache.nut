global function ShPrecacheS05Ending

global asset PRECACHE_DATATABLE_SEASONQUEST_END_DIALOGUE = $"datatable/dialogue/nightrun_dialogue.rpak"

void function ShPrecacheS05Ending()
{
	PrecacheObjectiveAsset_Model( "S05_FINALE_PROP_TOP", $"mdl/props/quest_s05/object.rmdl" )
	PrecacheObjectiveAsset_Model( "S05_FINALE_PROP_BOTTOM", $"mdl/props/quest_s05/object_body.rmdl" )
}
