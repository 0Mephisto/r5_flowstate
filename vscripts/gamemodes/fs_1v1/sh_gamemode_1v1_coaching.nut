untyped

#if SERVER
global function FS_Init_1v1_Coaching

global function FS_Coaching_StartRecording
global function FS_Coaching_StopRecording
global function FS_Coaching_GetAvailableMatchIdentifier

global function GetStartNewGameBool
global function SetStartNewGameBool

global function bIsCoachingMode
global function ReloadRecordingsList_Server

global function Recordings_SetPlaybackRate
#endif

#if CLIENT
global function CC_ReplayFight
global function CC_StartNewGame

global function Flowstate_OpenCoachingMenu
global function Flowstate_CloseCoachingMenu
global function Flowstate_AddRecordingIdentifierToClient

global function ReloadRecordingsList
#endif

struct recordingInfo_Identifier
{
	int index //yea who cares
	float duration
	float dateTime
	int winnerHandle
}

struct
{
	#if SERVER
	bool forceStartNewGame = false

	table< int, array< var > > recordingAnims
	table< int, array< recordingInfo > > recordingAnimsInfo
	
	float adminSetPlaybackRate = 1.0
	
	entity adminDummy
	entity coachedPlayerDummy
	int recordingPlaying
	#endif
	
	array< recordingInfo_Identifier > recordingsIdentifiers //len should be the same as recordingAnims and recordingAnimsInfo
} file

const int MAX_SLOT = 50

#if SERVER
void function FS_Init_1v1_Coaching()
{
	AddClientCommandCallback( "coaching_startnew", FS_1v1Coaching_StartNew ) //Start new game
	AddClientCommandCallback( "coaching_playselected", FS_1v1Coaching_PlaySelected ) //Play selected
	AddClientCommandCallback( "coaching_timescale", FS_1v1Coaching_TimeScaleTest ) //Change hosttime scale
	AddClientCommandCallback( "coaching_pause", FS_1v1Coaching_TimeScaleTestPause ) //Pause using time scale
	AddClientCommandCallback( "coaching_stop", FS_1v1Coaching_StopRecording ) //Stop the current recording playing
	AddClientCommandCallback( "coaching_startagain", FS_1v1Coaching_StartAgain ) //Start again the current recording

	for( int i = 0; i < MAX_SLOT; i++ )
	{
		file.recordingAnims[i] <- []
	}

	for( int i = 0; i < MAX_SLOT; i++ )
	{
		file.recordingAnimsInfo[i] <- []
	}
	
	AddCallback_OnWeaponAttack( FS_Coaching_RecordWeaponShot )
	//test
	SetConVarInt( "script_server_fps", 60 )
	SetConVarFloat( "base_tickinterval_mp", 0.0166667 )
}

bool function bIsCoachingMode()
{
	return Playlist() == ePlaylists.fs_1v1_coaching
}

void function FS_Coaching_RecordWeaponShot( entity player, entity weapon, string weaponName, int ammoUsed, vector attackOrigin, vector attackDir )
{
	weaponShotRecord shot
	shot.weaponName = weaponName
	shot.attackOrigin = attackOrigin
	shot.attackDir = attackDir
	shot.shotTime = Time() - player.p.recordingStartTime
	
	player.p.savedShots.append( shot )
}

//Client commands
bool function FS_1v1Coaching_StartNew(entity player, array<string> args )
{
	if( !IsValid(player) )
		return false
	
	if( !IsAdmin(player) )
	{
		Message_New(player, "ONLY FOR ADMIN")
		return false
	}
	
	if( Time() < player.p.lastRestUsedTime + 3 )
	{
		Message_New(player, "COOLDOWN")
		return false
	}

	if( GetPlayerArray_Alive().len() != 2 )
	{
		Message_New(player, "TWO PLAYERS NEEDED")
		return false
	}
	
	bool defStart = true
	foreach ( splayer in GetPlayerArray_Alive() )
	{
		if ( !IsValid( splayer ) )
		{
			defStart = false
			continue
		}
		
		if( !splayer.p.playerisready )
			defStart = false
		
		if( Gamemode1v1_GetPlayerGamestate( player ) != e1v1State.WAITING )
			defStart = false
	}
	
	if( !defStart )
	{
		Message_New(player, "A PLAYER WASN'T READY")
		return false
	}

	player.p.lastRestUsedTime = Time() //reusing this
	SetStartNewGameBool( true )
	
	foreach ( splayer in GetPlayerArray_Alive() )
	{
		if ( !IsValid( splayer ) )
			continue
		
		splayer.p.playerisready = false
	}
	return true
}

// requires sv_cheats 1
bool function FS_1v1Coaching_TimeScaleTest(entity player, array<string> args )
{
	if( !IsValid(player) )
		return false
	
	if( !IsAdmin(player) )
	{
		Message_New(player, "ONLY FOR ADMIN")
		return false
	}
	
	if( args.len() != 1 || !IsStringNumeric(args[0]) )
		return false
	
	float scale = args[0].tofloat()
	
	ServerCommand( "host_timescale " + scale )
	return true
}

bool function FS_1v1Coaching_TimeScaleTestPause(entity player, array<string> args )
{
	if( !IsValid(player) )
		return false
	
	if( !IsAdmin(player) )
	{
		Message_New(player, "ONLY FOR ADMIN")
		return false
	}
	
	ServerCommand( "host_timescale 0.01" )
	return true
}

bool function FS_1v1Coaching_StopRecording(entity player, array<string> args )
{
	if( !IsValid(player) )
		return false
	
	if( !IsAdmin(player) )
	{
		Message_New(player, "ONLY FOR ADMIN")
		return false
	}
	
	if( IsValid( file.adminDummy ) )
	{
		file.adminDummy.Destroy()
		return true
	}
	
	return false
}

bool function FS_1v1Coaching_StartAgain(entity player, array<string> args )
{
	if( !IsValid(player) )
		return false
	
	if( !IsAdmin(player) )
	{
		Message_New(player, "ONLY FOR ADMIN")
		return false
	}
	
	if( file.recordingPlaying != -1 )
	{
		if( IsValid( file.adminDummy ) )
			file.adminDummy.Destroy()
		
		FS_1v1Coaching_PlaySelected( player, [file.recordingPlaying.tostring()] )
		
		Remote_CallFunction_NonReplay(player, "Flowstate_CloseCoachingMenu")
		
		return true
	}
	
	return false
}

bool function FS_1v1Coaching_PlaySelected(entity player, array<string> args )
{
	if( !IsValid(player) )
		return false
	
	if( !IsAdmin(player) )
	{
		Message_New(player, "ONLY FOR ADMIN")
		return false
	}
	
	if( Gamemode1v1_GetPlayerGamestate( player ) != e1v1State.WAITING )
		return false
	
	if( args.len() != 1 )
		return false
	
	int matchIdentifier = int( args[0] )
	
	if( !FS_Coaching_IsValidMatchIdentifier( matchIdentifier ) )
	{
		Message_New(player, "ONLY FOR ADMIN")
		return false
	}
	
	array<recordingInfo> matchData = file.recordingAnimsInfo[ matchIdentifier ]
	
	if( matchData.len() != 2 )
	{
		Message_New(player, "ERROR ASK CAFE TO DEBUG THIS")
		return false
	}
	
	recordingInfo adminData = matchData[0]
	recordingInfo coachedPlayerData = matchData[1]
	
	//test
	entity admin = adminData.player
	entity coachedPlayer = coachedPlayerData.player
	
	if( !IsValid( coachedPlayer ) )
	{
		foreach( sPlayer in GetPlayerArray() )
		{
			if( sPlayer == admin )
				continue
			else
			{
				coachedPlayerData.player = sPlayer
				coachedPlayer = coachedPlayerData.player
			}
		}
		
		if( !IsValid( coachedPlayer ) && IsValid( admin ) )
		{
			Message_New( admin, "ERROR ASK CAFE TO DEBUG THIS 2" )
			return false
		}
	}
	
	if( !IsValid( admin ) )
	{
		adminData.player = player
		admin = adminData.player
	}
	
	if( Gamemode1v1_IsPlayerWaiting( admin ) )
	{
		Gamemode1v1_RemovePlayerFromWaitingList( admin.p.handle )
		RemovePlayerFromGroup( admin )
	}
	
	if( Gamemode1v1_IsPlayerWaiting( coachedPlayer ) )
	{
		Gamemode1v1_RemovePlayerFromWaitingList( coachedPlayer.p.handle )
		RemovePlayerFromGroup( coachedPlayer )
	}
	
	LocalMsg( admin, "#FS_NULL", "", eMsgUI.EVENT, 1 )
	LocalMsg( coachedPlayer, "#FS_NULL", "", eMsgUI.EVENT, 1 )
	
	admin.AddToAllRealms()
	coachedPlayer.AddToAllRealms()
	
	LocPair adminStartingPos = adminData.locPairData
	LocPair coachedPlayerStartingPos = coachedPlayerData.locPairData
	
	admin.SetOrigin( adminStartingPos.origin )
	admin.SetAngles( adminStartingPos.angles )
	
	coachedPlayer.SetOrigin( coachedPlayerStartingPos.origin )
	coachedPlayer.SetAngles( coachedPlayerStartingPos.angles )	
	
	Gamemode1v1_SetPlayerGamestate( admin, e1v1State.WATCHING_FIGHT_REPLAY )
	Gamemode1v1_SetPlayerGamestate( coachedPlayer, e1v1State.WATCHING_FIGHT_REPLAY )
	
	MakeInvincible( admin )
	MakeInvincible( coachedPlayer )
	
	//actually start playing the anim
	entity adminDummy = CreateDummy( 99, adminStartingPos.origin, adminStartingPos.angles )
	entity coachedPlayerDummy = CreateDummy( 99, coachedPlayerStartingPos.origin, coachedPlayerStartingPos.angles )
	SetCommonDummyLines( adminDummy, admin )
	SetCommonDummyLines( coachedPlayerDummy, coachedPlayer )
	
	file.adminDummy = adminDummy
	file.coachedPlayerDummy = coachedPlayerDummy
	
	adminDummy.PlayRecordedAnimation( file.recordingAnims[matchIdentifier][0], adminStartingPos.origin, adminStartingPos.angles )
	coachedPlayerDummy.PlayRecordedAnimation( file.recordingAnims[matchIdentifier][1], coachedPlayerStartingPos.origin, coachedPlayerStartingPos.angles )
	
	file.recordingPlaying = matchIdentifier
	
	SetGlobalNetBool( "FS_Coaching_IsPlayingRecording", true )
	
	//admin shots
	thread PlayPlayerShots( adminDummy, adminData )
	
	//coachedplayer shots
	thread PlayPlayerShots( coachedPlayerDummy, coachedPlayerData )	
	
	//watcher
	thread function () : ( admin, coachedPlayer, matchIdentifier, adminDummy, coachedPlayerDummy )
	{
		EndSignal( admin, "OnDestroy" )
		EndSignal( coachedPlayer, "OnDestroy" )
		EndSignal( adminDummy, "OnDestroy" )

		OnThreadEnd(
			function() : ( admin, coachedPlayer )
			{
				if( IsValid( file.coachedPlayerDummy ) )
					file.coachedPlayerDummy.Destroy()
				
				if( IsValid( file.adminDummy ) )
					file.adminDummy.Destroy()
				
				SetGlobalNetBool( "FS_Coaching_IsPlayingRecording", false )
				
				if( IsValid( admin ) )
				{
					ClearInvincible( admin )
					soloModePlayerToWaitingList( admin )
					
					if( !IsAlive( admin ) )
						DecideRespawnPlayer( admin, false )
					
					Gamemode1v1_TeleportPlayer( admin, getWaitingRoomLocation() )
				}
				
				if( IsValid( coachedPlayer ) )
				{
					ClearInvincible( coachedPlayer )
					soloModePlayerToWaitingList( coachedPlayer )
					
					if( !IsAlive( coachedPlayer ) )
						DecideRespawnPlayer( coachedPlayer, false )
					
					Gamemode1v1_TeleportPlayer( coachedPlayer, getWaitingRoomLocation() )
				}
			}
		)
		
		//HACK, wait for anim to finish
		waitthread function () : ( matchIdentifier, adminDummy )
		{
			if( adminDummy.GetCurrentSequenceName() == "ref" )
				while( IsValid( adminDummy ) && adminDummy.GetCurrentSequenceName() == "ref" ) //it will always start with two or three ref frames
					WaitFrame()
			
			while( IsValid( adminDummy ) && adminDummy.GetCurrentSequenceName() != "ref" )
				WaitFrame()
		}()
		
		//Si no se ejecuta esta parte, significa que se usó la feature "start again"
		file.recordingPlaying = -1
		
		if( IsValid( adminDummy ) )
			adminDummy.Destroy()
				
		if( IsValid( coachedPlayerDummy ) )
			coachedPlayerDummy.Destroy()
	}()
	return true
}

//The problem with this approach is that there is something bad in the engine Anim Recording functs that causes anim to change
//current position when you change the playbackrate mid anim
void function Recordings_SetPlaybackRate( float value )
{
	file.adminSetPlaybackRate = value
	
	if( IsValid( file.coachedPlayerDummy ) )
		file.coachedPlayerDummy.SetRecordedAnimationPlaybackRate( file.adminSetPlaybackRate )
	
	if( IsValid( file.adminDummy ) )
		file.adminDummy.SetRecordedAnimationPlaybackRate( file.adminSetPlaybackRate )
}

void function PlayPlayerShots( entity dummyPlayer, recordingInfo shotsData )
{
	EndSignal( dummyPlayer, "OnDestroy" )
	
	string oldweapon
	float previousShotTime
	entity weapon

	OnThreadEnd(
		function() : ( weapon )
		{
			if( IsValid( weapon ) )
				weapon.Destroy()
		}
	)
	
	foreach( int i, weaponShotRecord shot in shotsData.shots )
	{
		float currentShotTime = shot.shotTime
		float deltaTime = currentShotTime - previousShotTime

		if( deltaTime > 0 )
		{
			wait deltaTime - FrameTime()
		}
		
		if( shot.weaponName != oldweapon )
		{
			dummyPlayer.TakeNormalWeaponByIndex( WEAPON_INVENTORY_SLOT_PRIMARY_0 )
			weapon = dummyPlayer.GiveWeapon( shot.weaponName, WEAPON_INVENTORY_SLOT_PRIMARY_0 )
		}
		
		WeaponFireBoltParams fireBoltParams
		fireBoltParams.pos = shot.attackOrigin
		fireBoltParams.dir = shot.attackDir
		fireBoltParams.speed = 1
		fireBoltParams.scriptTouchDamageType = 0
		fireBoltParams.scriptExplosionDamageType = 0
		fireBoltParams.clientPredicted = false
		fireBoltParams.additionalRandomSeed = 0
		
		entity bullet = weapon.FireWeaponBoltAndReturnEntity( fireBoltParams )
		
		oldweapon = shot.weaponName
		previousShotTime = currentShotTime
	}
}

void function SetCommonDummyLines( entity npc, entity owner )
{
	SetSpawnOption_AISettings( npc, "npc_dummie_wraith" )
	DispatchSpawn( npc )
	npc.SetCanBeMeleed( true )
	npc.SetTakeDamageType( DAMAGE_NO )
	npc.Show()
	npc.AddToAllRealms()
	npc.NotSolid()
	
	//Disable collision with players
	npc.kv.contents = CONTENTS_BULLETCLIP | CONTENTS_MONSTERCLIP | CONTENTS_HITBOX | CONTENTS_BLOCKLOS | CONTENTS_PHYSICSCLIP //CONTENTS_PLAYERCLIP
}
//Recording functions
void function FS_Coaching_StartRecording( entity player )
{
	printw( "1v1 Recording Started for player", player )
	
	player.p.currentOrigin = player.GetOrigin()
	player.p.currentAngles = player.GetAngles()
	player.StartRecordingAnimation( player.p.currentOrigin, player.p.currentAngles )
	
	player.p.recordingStartTime = Time()
}

void function FS_Coaching_StopRecording( int matchIdentifier, entity victim, entity attacker )
{
	printw( "[+] COACHING 1v1 SAVING MATCH RECORD IN SLOT: ", matchIdentifier, "- FOR PLAYERS", victim, attacker  )
	
	entity admin
	entity coachedPlayer
	
	if( IsAdmin( victim ) )
	{
		admin = victim
		coachedPlayer = attacker
	}
	else if( IsAdmin( attacker ) )
	{
		admin = attacker
		coachedPlayer = victim
	}
	
	if( !IsValid( admin ) )
	{
		Message_New( victim, "Couldn't save recording, admin wasn't declared." )
		Message_New( attacker, "Couldn't save recording, admin wasn't declared." )
		return
	}
	
	//admin
	{
		var recording
		
		try{
			recording = admin.StopRecordingAnimation()
		}catch(e420)
		{
			printw( "ERROR SAVING ADMIN PLAYER RECORDING" )
			return
		}
		
		LocPair animData
		animData.origin = admin.p.currentOrigin
		animData.angles = admin.p.currentAngles

		recordingInfo info
		info.locPairData = animData
		info.player = admin
		info.shots = clone admin.p.savedShots
		admin.p.savedShots.clear()
		
		file.recordingAnims[ matchIdentifier ].append( recording )
		file.recordingAnimsInfo[ matchIdentifier ].append( info )
	}
	
	//coached player
	{
		var recording
		
		try{
			recording = coachedPlayer.StopRecordingAnimation()
		}catch(e420)
		{
			printw( "ERROR SAVING COACHED PLAYER RECORDING" )
			return
		}
		
		LocPair animData
		animData.origin = coachedPlayer.p.currentOrigin
		animData.angles = coachedPlayer.p.currentAngles
		
		recordingInfo info
		info.locPairData = animData
		info.player = coachedPlayer
		info.shots = clone coachedPlayer.p.savedShots
		coachedPlayer.p.savedShots.clear()

		file.recordingAnims[ matchIdentifier ].append( recording )
		file.recordingAnimsInfo[ matchIdentifier ].append( info )
	}
	
	recordingInfo_Identifier recordingIdentifier
	recordingIdentifier.index = matchIdentifier
	recordingIdentifier.duration = GetRecordedAnimationDuration( file.recordingAnims[ matchIdentifier ][0] )
	recordingIdentifier.dateTime = 0
	recordingIdentifier.winnerHandle = attacker.GetEncodedEHandle()
	
	file.recordingsIdentifiers.append( recordingIdentifier )
	
	//send data to client vm and ui vm
	Remote_CallFunction_NonReplay(victim, "Flowstate_AddRecordingIdentifierToClient", recordingIdentifier.index, recordingIdentifier.duration, recordingIdentifier.dateTime, recordingIdentifier.winnerHandle )
	Remote_CallFunction_NonReplay(attacker, "Flowstate_AddRecordingIdentifierToClient", recordingIdentifier.index, recordingIdentifier.duration, recordingIdentifier.dateTime, recordingIdentifier.winnerHandle )
}

bool function FS_Coaching_IsValidMatchIdentifier( int matchIdentifier )
{
	if( matchIdentifier < 0 )
		return false 
	
	if( file.recordingAnims[ matchIdentifier ].len() != 0 && file.recordingAnimsInfo[ matchIdentifier ].len() != 0 )
		return true
	
	return false
}

int function FS_Coaching_GetAvailableMatchIdentifier()
{
	for( int i = 0; i < MAX_SLOT; i++ )
	{
		if( file.recordingAnims[i].len() == 0 )
			return i
	}
	
	return -1
}

//Setters and getters
bool function GetStartNewGameBool()
{
	return file.forceStartNewGame
}

void function SetStartNewGameBool( bool start )
{
	file.forceStartNewGame = start
}

void function ReloadRecordingsList_Server( entity player )
{
	foreach( recordingIdentifier in file.recordingsIdentifiers )
	{
		Remote_CallFunction_NonReplay(player, "Flowstate_AddRecordingIdentifierToClient", recordingIdentifier.index, recordingIdentifier.duration, recordingIdentifier.dateTime, recordingIdentifier.winnerHandle )
	}
}

#endif

#if CLIENT
void function CC_StartNewGame()
{
	entity player = GetLocalClientPlayer()
	
	if( !player.GetPlayerNetBool("IsAdmin") )
		return
	
	player.ClientCommand( "coaching_startnew" )
}

void function CC_ReplayFight( int index )
{
	entity player = GetLocalClientPlayer()
	
	if( !player.GetPlayerNetBool("IsAdmin") )
		return
	
	player.ClientCommand( "coaching_playselected " + index )
}

void function Flowstate_OpenCoachingMenu()
{
	RunUIScript( "UI_Open1v1CoachingMenu" )
}

void function Flowstate_CloseCoachingMenu()
{
	RunUIScript( "UI_Close1v1CoachingMenu" )
}

void function Flowstate_AddRecordingIdentifierToClient( int index, float duration, float dateTime, int winnerHandle )
{
	recordingInfo_Identifier newRecording
	newRecording.index = index
	newRecording.duration = duration
	newRecording.dateTime = dateTime
	newRecording.winnerHandle = winnerHandle
	
	file.recordingsIdentifiers.append( newRecording )
	
	RunUIScript( "UI_Flowstate_AddRecordingIdentifierToClient", index, duration, dateTime, winnerHandle )
}

void function ReloadRecordingsList()
{
	foreach( recording in file.recordingsIdentifiers )
	{
		RunUIScript( "UI_Flowstate_AddRecordingIdentifierToClient", recording.index, recording.duration, recording.dateTime, recording.winnerHandle )
	}
}

#endif