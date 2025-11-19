global function ShInit_Skygarden
global function CodeCallback_MapInit

void function CodeCallback_MapInit()
{	
	#if SERVER
	thread MapModels()
	#endif
}

void function ShInit_Skygarden()
{
	SetVictorySequencePlatformModel( $"mdl/dev/empty_model.rmdl", < 0, 0, -10 >, < 0, 0, 0 > )
	#if CLIENT
	  SetVictorySequenceLocation(<2382.82422, -4059.49658, -3141.40796>, <0, 201.828598, 0> )
	#endif
}

#if SERVER
void function MapModels()
{

}
#endif
