global function ShInit_ArenaComposite
#if SERVER
global function CodeCallback_MapInit

void function CodeCallback_MapInit()
{
	ConveyorInit($"mdl/levels_terrain/mp_rr_arena_composite/composite_cargo_128_blue_01.rmdl", "", 10, 80)
}
#endif

void function ShInit_ArenaComposite()
{
	SetVictorySequencePlatformModel( $"mdl/dev/empty_model.rmdl", < 0, 0, -10 >, < 0, 0, 0 > )
	#if CLIENT
		SetVictorySequenceLocation(<1374, -4060, 418>, <0, 201.828598, 0> )
	#endif
}