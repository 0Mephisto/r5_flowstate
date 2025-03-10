global function FS_Scenarios_CustomTeamCmd																		//mkos
global function FS_Scenarios_CustomTeamInit
global function FS_Scenarios_CheckAndSetRoundTimeForTeam
global function FS_Scenarios_IsPlayerWaitingForTeamates

global function GetCustomTeamOfPlayer
global function GetCustomTeamSetting
global function GetCustomTeamByID

#if DEVELOPER
	global function DEV_GetPlayerCustomTeam
#endif

const int MAX_TEAMNAME_LEN = 12

global struct CustomTeam
{
	int teamID 	= -1
	string name = "New Team"
	float lastRoundEndTime
	
	table< string, int > customTeamSettings	
	
	array< entity >	captains
	array< entity > players
	array< entity > teamJoinRequests	
}

struct 
{
	array< CustomTeam > customTeams
	int uniqueTeamID = 0
	
	table< string, string > paramToSettingTbl

} file

struct 
{
	bool scenarios_allow_team_settings
	bool scenarios_teams_allowed

} settings 

void function FS_Scenarios_CustomTeamInit() //✓
{
	#if DEVELOPER
		printl( "Scenarios CustomTeam Init" )
	#endif

	settings.scenarios_allow_team_settings = GetCurrentPlaylistVarBool( "scenarios_allow_team_settings", true )
	settings.scenarios_teams_allowed = true
	
	AddCallback_OnClientDisconnected( OnPlayerDisconnected_CustomTeam )
	
	file.paramToSettingTbl = StringTableFlip( SHORTHAND_COMMAND_MAP )
	disableoverwrite( file.paramToSettingTbl ) 
}

bool function RequestJoinTeam( entity player, CustomTeam team ) // ✓
{
	if( team.teamJoinRequests.contains( player ) )
		return false 
	else 
		team.teamJoinRequests.append( player )
		
	foreach( captain in team.captains )
		LocalMsg_TEMP( captain, "#TMP_13", player.p.name )
		
	return true
}

string function GetJoinRequestsString( CustomTeam team ) // ✓  -- Todo: send to client ui remote func
{
	string joinRequestsStr
	foreach( int idx, entity player in team.teamJoinRequests )
		joinRequestsStr += format( "%d = %s\n", idx, player.p.name )
		
	return joinRequestsStr
}

string function GetTeamSettingsString( CustomTeam team ) //✓
{
	string settingsStr = format( "\n\nSettings:\n\nname = %s\n", team.name )	
	foreach( string setting, int value in team.customTeamSettings )
		settingsStr += format( "%s = %d\n", SHORTHAND_COMMAND_MAP[ setting ], value )
		
	return settingsStr
}

bool function RevokeJoinRequest( entity player, CustomTeam team ) // ✓ any player
{
	if( !team.teamJoinRequests.contains( player ) )
		return false 
	else
		team.teamJoinRequests.fastremovebyvalue( player )
		
	return true
}

void function RevokeAllJoinRequests( entity player ) //✓
{
	foreach( team in file.customTeams )
	{
		int teamLen = team.teamJoinRequests.len() - 1		
		for( int i = teamLen; i >= 0; i-- )
		{
			if( team.teamJoinRequests[ i ] == player )
				team.teamJoinRequests.remove( i )
		}
	}
}

bool function IsCaptainOfTeam( entity player, CustomTeam team ) //✓
{
	return team.captains.contains( player )
}

bool function IsOnTeam( entity player, CustomTeam team ) //✓
{
	return team.players.contains( player )
}

bool function AcceptJoinRequest( entity captain, entity player ) // ✓ captains run this
{
	if( player.p.hasTeam )
		return false

	CustomTeam ornull team = GetCustomTeamOfPlayer( captain )
	
	if( team == null )
		return false
		
	expect CustomTeam ( team )
	
	if( !IsCaptainOfTeam( captain, team ) )
		return false
		
	if( team.players.len() >= FS_Scenarios_PlayersPerTeam() )
		return false
		
	if ( RevokeJoinRequest( player, team ) )
	{
		if ( AddPlayerToTeam( player, team ) )
			return true 
	}
	
	return false	
}

void function FS_Scenarios_CheckAndSetRoundTimeForTeam( entity player ) // ✓ called when players die.
{
	CustomTeam ornull team = GetCustomTeamOfPlayer( player )
	if( team == null )
		return 
		
	expect CustomTeam ( team )
	
	if( GetCustomTeamSetting( team, "allow_random_fill" ) == 0 ) //if we don't check for this, teamates in another round can overlap each other by setting the finish time from various rounds.
		team.lastRoundEndTime = Time()
}

int function __GetUniqueCustomTeamID() // ✓ called when creating new team
{
	return ++file.uniqueTeamID
}

bool function CreateCustomTeam( entity player, string name = "" ) // ✓
{
	if( player.p.hasTeam )
		return false
		
	table< string, int > settings
	foreach( string settingName, array<string> allowedValues in ALLOWED_SETTINGS )
		settings[ settingName ] <- allowedValues[ 0 ].tointeger()
		
	CustomTeam team
	
	team.teamID = __GetUniqueCustomTeamID()
	team.captains.append( player )
	team.players.append( player )
	team.lastRoundEndTime = Time()
	team.customTeamSettings = settings
	
	if( name != "" && name.len() <= MAX_TEAMNAME_LEN )
		team.name = name
	else 
		team.name = format( "Team%d", team.teamID )
	
	player.p.hasTeam = true
	file.customTeams.append( team )
	
	return true
}

CustomTeam ornull function GetCustomTeamOfPlayer( entity player ) // ✓
{
	foreach( teamStruct in file.customTeams )
	{
		if( teamStruct.players.contains( player ) )
			return teamStruct 
	}
	
	return null
}

CustomTeam ornull function GetCustomTeamByID( int id ) // ✓
{
	foreach( teamStruct in file.customTeams )
	{
		if( teamStruct.teamID == id )
			return teamStruct
	}
	
	return null
}

bool function IsPlayerTeamCaptain( entity player ) // ✓
{
	CustomTeam ornull team = GetCustomTeamOfPlayer( player )
	
	if( team == null )
		return false
	
	expect CustomTeam ( team )		
	return team.captains.contains( player )
}

int function GetPlayerCustomTeamID( entity player ) //✓
{
	CustomTeam ornull team = GetCustomTeamOfPlayer( player )
	
	if( team == null )
		return -1
	
	expect CustomTeam ( team )
	return team.teamID
}

bool function FS_Scenarios_IsPlayerWaitingForTeamates( entity player ) //✓
{
	if( !player.p.hasTeam )
		return false 
		
	CustomTeam ornull team = GetCustomTeamOfPlayer( player )
	
	if( team == null )
		return false
	
	expect CustomTeam ( team )
	array<entity> playerTeam = team.players
	
	if( settings.scenarios_allow_team_settings )
	{
		bool allowFill = GetCustomTeamSetting( team, "allow_random_fill" ) == 0 ? false : true	
		
		if( !allowFill && playerTeam.len() < FS_Scenarios_PlayersPerTeam() )
		{
			//printf( "Team fill is OFF(0) and player \"%s\" is waiting for teamates", string( player ) )
			return true
		}
			
		int mmTimeOut = GetCustomTeamSetting( team, "matchmaking_timeout" )
		if( Time() - team.lastRoundEndTime < mmTimeOut )
		{
			//printf( "player \"%s\" is waiting for timeout of \"%d\"  remaining: %f", string( player ), mmTimeOut, mmTimeOut - ( Time() - team.lastRoundEndTime ) )
			return true
		}
		
		if( allowFill )
			return false
	}
				
	foreach( entity tPlayer in playerTeam )
	{
		if( !IsCurrentState( tPlayer, e1v1State.WAITING ) )
		{
			//printf( "Not all players of team are in queue: %s", string( tPlayer ) )
			return true
		}
	}
	
	return false
}


int function GetCustomTeamSetting( CustomTeam team, string setting ) //✓
{
	if( setting in team.customTeamSettings )
		return team.customTeamSettings[ setting ]
		
	return 0
}

table< string, string > function StringTableFlip( table< string, string > stringTbl ) //✓
{
	table< string, string > flipped
	
	foreach( string k, string v in stringTbl )
		flipped[ v ] <- k
	
	return flipped
}

const table< string, string > SHORTHAND_COMMAND_MAP = //✓
{
	allow_random_fill	= "fill",
	matchmaking_timeout = "timeout",
	anyone_is_captain	= "allcaptain",
	anyone_can_join		= "open"
}

const table< string, array< string > > ALLOWED_SETTINGS = //✓
{
	allow_random_fill 	= [ "0", "1" ],
	matchmaking_timeout = [ "0", "number" ],
	anyone_is_captain 	= [ "0", "1" ],
	anyone_can_join 	= [ "0", "1" ]
}

/*
	-4 = invalid value choice for setting
	-3 = not on a team
	-2 = not captain
	-1 = invalid setting 
	 0 = already set 
	 1 = success
*/

string function GetTokenResponseForSetting( int result ) //✓
{
	switch( result )
	{
		case -4: return "#TMP_40";
		case -3: return "#TMP_8";
		case -2: return "#TMP_37";
		case -1: return "#TMP_38";
		case 0:  return "#TMP_39";
		case 1:  return "#TMP_41";
		default: mAssert( 0, "Invalid" ); return "#TMP_42";
	}
	
	unreachable
}

int function SetCustomTeamSetting( entity player, string setting, string value ) //✓
{
	if( !player.p.hasTeam )
		return -3
		
	if( !( setting in ALLOWED_SETTINGS ) )
		return -1
		
	CustomTeam ornull team = GetCustomTeamOfPlayer( player )	
	if( team == null )
		return -3
		
	expect CustomTeam ( team )
	if( !GetCustomTeamSetting( team, "anyone_is_captain" ) && !team.captains.contains( player ) )
		return -2
		
	if( !ALLOWED_SETTINGS[ setting ].contains( "number" ) && !ALLOWED_SETTINGS[ setting ].contains( value ) )
		return -4
		
	if( !IsNumeric( value ) )	
		return -4
		
	if( !__SetCustomTeamSetting_internal( team, setting, value.tointeger() ) )
		return 0
		
	return 1
}

bool function __SetCustomTeamSetting_internal( CustomTeam team, string setting, int value ) //✓
{
	if( setting in team.customTeamSettings )
	{
		if( team.customTeamSettings[ setting ] == value )
			return false 
			
		team.customTeamSettings[ setting ] = value 
	}
	else
	{
		mAssert( 0, format( "invalid setting was attempted to be set in table in %s()", FUNC_NAME() ) )
		return false
	}
		
	return true
}

//notifications system, use "waiting for players", add "of team"

// add disconnect to remove player:
void function OnPlayerDisconnected_CustomTeam( entity player ) //✓
{
	RemovePlayerFromPlayersTeam( player )
	RevokeAllJoinRequests( player )
}

/*
	"Tokens"
	{
		"TMP_0" "\n\n\n\n\n\n\n\n\n\n\n\n/team help                           - lists commands\n/team list                             - lists teams #\n/team make [name]                                               - makes a team\n/team info [player|uid|team ID]                       - info about team\n/team join [captain name/uid | team id]      - joins a team\n/team leave                                                               - leaves a team -> if no captains exist, team is destroyed\n\nCaptain only:\n\n/team accept [player|uid|id]                    - accepts join request by player or request id\n/team reject [player|uid|id]                      - declines join request by player or request id\n/team kick [player|uid|team member #]                       - kicks member from team\n/team makecaptain [player|uid|team member #]    - gives player captain privileges\n/team settings                                                 - lists teams settings and their values\n/team set [setting] [value]                         - sets a team setting"
		"TMP_1" "Already in team"
		"TMP_2" "Error with command parameter length"
		"TMP_3" "Invalid team"
		"TMP_4" "Player does not own a team"
		"TMP_6" "Team is full"
		"TMP_7" "Join request cooldown"
		"TMP_8" "Not in a team"
		"TMP_9" "Player left the team: "
		"TMP_10" "Player joined the team: "
		"TMP_11" "You joined team: "
		"TMP_12" "Failed to join team: "
		"TMP_13" "New join request: "
		"TMP_14" "Team join request sent to: "
		"TMP_15" "You left team: "
		"TMP_16" "Failed to leave team: "
		"TMP_17" "Join request failed for team: "
		"TMP_18" "Failed. Max length for teamname is: "
		"TMP_19" "Team created successfully"
		"TMP_20" "Failed to create team"
		"TMP_21" "Command \"team info\" Requires team # or player of team as last parameter"
		"TMP_22" "All Teams"
		"TMP_23" "Team info"
		"TMP_24" "Help info"
		"TMP_25" "Team was dismantled"
		"TMP_26" "Join requests"
		"TMP_27" "Command requires last parameter of id/player"
		"TMP_28" "Failed to accept/reject request"
		"TMP_29" "Invalid request player"
		"TMP_30" "Request revoked for: "
		"TMP_31" "Invalid team player"
		"TMP_32" "Failed to kick player"
		"TMP_33" "Player not on team"
		"TMP_34" "Player already captain"
		"TMP_35" "Added as captain: "
		"TMP_36" "Team Settings"
		"TMP_37" "Not captain of team"
		"TMP_38" "Invalid setting"
		"TMP_39" "Setting is already this value"
		"TMP_40" "Invalid value for setting. Numbers only"
		"TMP_41" "Setting successfully set"
		"TMP_42" "Command requires setting & value. ex: /team set fill 0"
		"TMP_43" "Admin has disable teams"
		"TMP_44" "Not on any team"
		"TMP_45" "Success"
		"TMP_46" "Failed"
	}
*/

bool function RemovePlayerFromTeam( entity player, CustomTeam team, bool alert = true ) //✓
{
	if( player.p.hasTeam )
	{
		if( team.players.contains( player ) )
		{
			team.players.fastremovebyvalue( player )
			
			if( alert )
			{
				foreach( teamPlayer in team.players )
					LocalMsg_TEMP( teamPlayer, "#TMP_9", player.p.name )
			}
				
			if( team.captains.contains( player ) )
			{
				team.captains.fastremovebyvalue( player )			
				if( team.captains.len() == 0 )
					__DismantleTeam( team )
			}
				
			player.p.hasTeam = false
			return true
		}
	}
	
	return false
}

void function __DismantleTeam( CustomTeam team ) //✓
{
	foreach( player in team.players )
	{
		RemovePlayerFromTeam( player, team, false )
		LocalMsg_TEMP( player, "#TMP_25" )
	}
	
	file.customTeams.fastremovebyvalue( team )
}

bool function RemovePlayerFromPlayersTeam( entity player ) //✓
{
	if( !player.p.hasTeam )
		return false 
		
	CustomTeam ornull team = GetCustomTeamOfPlayer( player )
	
	if( team == null )
	{
		player.p.hasTeam = false
		printf( "Player: \"%s\" had team, but could not find it. Returning." )
		//mAssert( 0, format( "Player: \"%s\" had team, but could not find it.", string( player ) ) )
		return false
	}
	
	expect CustomTeam ( team )
	return RemovePlayerFromTeam( player, team )
}

bool function AddPlayerToTeam( entity player, CustomTeam team ) //✓
{
	if( player.p.hasTeam )
		return false 
		
	if( team.players.len() >= FS_Scenarios_PlayersPerTeam() )
		return false 
		
	foreach( teamPlayer in team.players )
		LocalMsg_TEMP( teamPlayer, "#TMP_10", player.p.name )
	
	team.players.append( player )
	player.p.hasTeam = true
	
	LocalMsg_TEMP( player, "#TMP_11", team.name )	
	return true
}

CustomTeam ornull function FindTeamFromQuery( string query ) //✓
{
	entity captainOfTeam 	= GetPlayer( query )	
	
	if( !IsValid( captainOfTeam ) )
	{
		if( IsNumeric( query ) )
			return GetCustomTeamByID( query.tointeger() )
	}
	else 
	{
		return GetCustomTeamOfPlayer( captainOfTeam )
	}
	
	return null
}

string function GetTeamInfo( CustomTeam team ) //✓ --todo remote func send to client for ui
{
	string teamInfo = format
	(
		"\n\n\n\n\nTeam#: %d    %s\n",
		team.teamID,
		team.name
	)
	
	teamInfo += "\n Captains: \n"
	foreach( captain in team.captains )
		teamInfo += format( "%s\n", captain.p.name )
		
	teamInfo += "\n\n Players: \n"
	foreach( int idx, entity player in team.players )
	{
		string state = "Unknown"
		if( isPlayerInWaitingList( player ) )
			state = "In-Queue"
		else if( isPlayerInRestingList( player ) )
			state = "Resting"
		else 
			state = "Playing"
			
		teamInfo += format( "#%d: %s   |   Score: %d   |   State: %s\n", idx, player.p.name, player.GetPlayerNetInt( "FS_Scenarios_PlayerScore" ), state )
	}
	
	float waitingTime
	int mmTimeOut 		= GetCustomTeamSetting( team, "matchmaking_timeout" )
	
	if( mmTimeOut > 0 )
		waitingTime = mmTimeOut - ( max( 0, Time() - team.lastRoundEndTime ) )
	
	teamInfo += format( "\n\n Timeout time remaining: \n%.1f", waitingTime )
	
	return teamInfo
}

string function GetAllTeamsListString() //✓ --todo remote func send to client for ui
{
	string teamInfo
	
	foreach( team in file.customTeams )
		teamInfo += format( "Team#: %d    %s\n", team.teamID, team.name )
	
	return teamInfo
}

entity function FindTeamPlayerFromQuery( string param, CustomTeam team, string type ) //✓
{
	entity targetPlayer = GetPlayer( param )
	
	if( !IsValid( targetPlayer ) )
	{
		switch( type )
		{
			case "action":
				int teamLen = team.players.len()
				if( teamLen > 0 && IsNumeric( param, 0, teamLen - 1 ) )
					targetPlayer = team.players[ param.tointeger() ]
				break 
			
			case "requests":
				int requestsLen = team.teamJoinRequests.len()
				if( requestsLen > 0 && IsNumeric( param, 0, requestsLen - 1 ) )
					targetPlayer = team.teamJoinRequests[ param.tointeger() ]			
				break
		}
	}
	
	return targetPlayer
}

void function FS_Scenarios_CustomTeamCmd( entity player, array<string> args ) //✓
{
	if( !settings.scenarios_teams_allowed )
	{
		LocalMsg_TEMP( player, "#TMP_43" )
		return
	}
		
	if( args.len() > 0 && Commands_GetCommandAliases( "!team" ).contains( args[ 0 ] ) )
		args.remove( 0 )
		
	string command = args.len() > 0 ? args[ 0 ] : ""
	string param   = args.len() > 1 ? args[ 1 ] : ""
	string param2  = args.len() > 2 ? args[ 2 ] : ""
	string param3  = args.len() > 3 ? args[ 3 ] : ""
	string param4  = args.len() > 4 ? args[ 4 ] : ""

	switch( command )
	{
		case "help":
			LocalMsg_TEMP( player, "#TMP_24", "#TMP_0", eMsgUI.DEFAULT, 35.0 )
			return
		
		case "list":
			if( !CheckRate( player, true, 1.5 ) )
				return
				
			string listInfo = GetAllTeamsListString()
			
			if( listInfo.len() <= 593 )
				LocalMsg_TEMP( player, "#TMP_22", listInfo, eMsgUI.DEFAULT, 10.0 )
			else
				LocalMsg( player, "#FS_OVERFLOW" )
			
			return
		
		case "info":
			if( !CheckRate( player, true, 1.5 ) )
				return
			
			CustomTeam ornull potentialTeam
			if( param == "" )
			{
				if( !player.p.hasTeam )
				{
					LocalMsg_TEMP( player, "#TMP_44" )
					return
				}
				
				potentialTeam = GetCustomTeamOfPlayer( player )
			}
			else 
				potentialTeam = FindTeamFromQuery( param )
			
			if( potentialTeam == null )
			{
				LocalMsg_TEMP( player, "#TMP_3" )
				return 
			}
			
			expect CustomTeam ( potentialTeam )	
			
			string teamInfo = GetTeamInfo( potentialTeam )
			
			if( teamInfo.len() <= 593 )
				LocalMsg_TEMP( player, "#TMP_23", teamInfo, eMsgUI.DEFAULT, 10.0 )
			else 
				LocalMsg( player, "#FS_OVERFLOW" )
			
			return
		
		case "make":
			if( player.p.hasTeam )
			{
				LocalMsg_TEMP( player, "#TMP_1" )
				return
			}
			
			if( param != "" && param.len() > MAX_TEAMNAME_LEN )
			{
				LocalMsg_TEMP( player, "#TMP_18", MAX_TEAMNAME_LEN.tostring() )
				return
			}
			
			param = StringReplace( param, "\"", "" )
			if( CreateCustomTeam( player, param ) )
				LocalMsg_TEMP( player, "#TMP_19" )
			else 
				LocalMsg_TEMP( player, "#TMP_20" )
				
			return
		
		case "join":
		
			if( !CheckRate( player, false, 5.0 ) )
			{
				LocalMsg_TEMP( player, "#TMP_7" )
				return 
			}
		
			if( player.p.hasTeam )
			{
				LocalMsg_TEMP( player, "#TMP_1" )
				return
			}

			if( param.len() > 20 )
			{
				LocalMsg_TEMP( player, "#TMP_2" )
				return
			}
			
			CustomTeam ornull potentialTeam = FindTeamFromQuery( param )
			
			if( potentialTeam == null )
			{
				LocalMsg_TEMP( player, "#TMP_3" )
				return 
			}
			
			expect CustomTeam ( potentialTeam )

			if( potentialTeam.players.len() >= FS_Scenarios_PlayersPerTeam() )
			{
				LocalMsg_TEMP( player, "#TMP_6" )
				return
			}
			
			if( potentialTeam.customTeamSettings[ "anyone_can_join" ] == 1 )
			{
				if( AddPlayerToTeam( player, potentialTeam ) )
					LocalMsg_TEMP( player, "#TMP_11", potentialTeam.name )
				else 
					LocalMsg_TEMP( player, "#TMP_12", potentialTeam.name )
			}
			else 
			{
				if( RequestJoinTeam( player, potentialTeam ) )
					LocalMsg_TEMP( player, "#TMP_14", potentialTeam.name )
				else 
					LocalMsg_TEMP( player, "#TMP_17", potentialTeam.name )
			}
			
			return
	}
		
	//requires team
	switch( command )
	{		
		case "leave":
		
			if( !player.p.hasTeam )
			{
				LocalMsg_TEMP( player, "#TMP_8" )
				return
			}

			if( RemovePlayerFromPlayersTeam( player ) )
				LocalMsg_TEMP( player, "#TMP_15" )
			else 
				LocalMsg_TEMP( player, "#TMP_17" )
	}
	
		
	//requires captain
	bool bAccept
	bool bReject
	switch( command )
	{	
		case "requests":
		
			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				LocalMsg_TEMP( player, "#TMP_44" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				LocalMsg_TEMP( player, "#TMP_37" )
				return
			}
				
			LocalMsg_TEMP( player, "#TMP_26", GetJoinRequestsString( team ) )		
			return
			
		case "accept":
			
			bAccept = true
			break //logic below
			
		case "reject":
		
			bReject = true
			break //logic below
			
		case "kick":
		
			if( param == "" )
			{
				LocalMsg_TEMP( player, "#TMP_46", "#TMP_27" )
				return
			}
			
			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				LocalMsg_TEMP( player, "#TMP_44" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				LocalMsg_TEMP( player, "#TMP_37" )
				return
			}

			entity targetPlayer = FindTeamPlayerFromQuery( param, team, "action" )
			
			if( IsValid( player ) )
			{
				if( !IsOnTeam( targetPlayer, team ) )
				{
					LocalMsg_TEMP( player, "#TMP_33" )
					return
				}
			
				if( !RemovePlayerFromTeam( targetPlayer, team ) )
					LocalMsg_TEMP( player, "#TMP_32" )
			}
			else 
				LocalMsg_TEMP( player, "#TMP_31" )
			
			return 
		
		case "makecaptain":
			
			if( param == "" )
			{
				LocalMsg_TEMP( player, "#TMP_46", "#TMP_27" )
				return
			}
			
			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				LocalMsg_TEMP( player, "#TMP_44" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				LocalMsg_TEMP( player, "#TMP_37" )
				return
			}
			
			entity targetPlayer = FindTeamPlayerFromQuery( param, team, "action" )		
			
			if( IsValid( player ) )
			{
				if( !IsOnTeam( targetPlayer, team ) )
				{
					LocalMsg_TEMP( player, "#TMP_33" )
					return
				}
				
				if( IsCaptainOfTeam( targetPlayer, team ) )
				{
					LocalMsg_TEMP( player, "#TMP_34" )
					return
				}
				
				team.captains.append( targetPlayer )
				LocalMsg_TEMP( player, "#TMP_35", targetPlayer.p.name )
			}
			else 
				LocalMsg_TEMP( player, "#TMP_31" )
			
			return
		
		case "settings":
		
			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				LocalMsg_TEMP( player, "#TMP_44" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				LocalMsg_TEMP( player, "#TMP_37" )
				return
			}
				
			string currentSettings = GetTeamSettingsString( team ) 
			LocalMsg_TEMP( player, "#TMP_36", currentSettings, eMsgUI.DEFAULT, 10.0 )
			return
		
		case "set":
		
			if( param == "" || param2 == "" )
			{
				LocalMsg_TEMP( player, "#TMP_46", "#TMP_42" )
				return
			}	

			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				LocalMsg_TEMP( player, "#TMP_44" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				LocalMsg_TEMP( player, "#TMP_37" )
				return
			}		
			
			if( param == "name" )
			{ 
				if( param2.len() > MAX_TEAMNAME_LEN )
				{
					LocalMsg_TEMP( player, "#TMP_18", MAX_TEAMNAME_LEN.tostring() )
					return
				}
				
				team.name = param2
				LocalMsg_TEMP( player, "#TMP_41" )
				return
			}
			
			if( !( param in file.paramToSettingTbl ) )
			{
				LocalMsg_TEMP( player, "#TMP_38" )
				return
			}
			
			int result = SetCustomTeamSetting( player, file.paramToSettingTbl[ param ], param2 )
			
			string statusToken
			if( result == 1 )
				statusToken = "#TMP_45"
			else
				statusToken = "#TMP_46"
			
			LocalMsg_TEMP( player, statusToken, GetTokenResponseForSetting( result ) )
			return
	}
	
	if( bAccept || bReject )
	{
		CustomTeam ornull team = GetCustomTeamOfPlayer( player )
		if( team == null )
		{
			LocalMsg_TEMP( player, "#TMP_44" )
			return
		}
		
		expect CustomTeam ( team )
		if( !IsCaptainOfTeam( player, team ) )
		{
			LocalMsg_TEMP( player, "#TMP_37" )
			return
		}
				
		if( param == "" )
		{
			LocalMsg_TEMP( player, "#TMP_46", "#TMP_27" )
			return
		}
		
		entity targetPlayer = FindTeamPlayerFromQuery( param, team, "requests" )
		
		if( IsValid( targetPlayer ) )
		{
			if( !team.teamJoinRequests.contains( targetPlayer ) )
			{
				LocalMsg_TEMP( player, "#TMP_29" )
				return
			}
		
			if( bAccept )
			{
				if( !AcceptJoinRequest( player, targetPlayer ) )//no need to print success message, all players get an alert on accept.
					LocalMsg_TEMP( player, "#TMP_28" )
			}
			else if( bReject )
			{
				if( !RevokeJoinRequest( targetPlayer, team ) )
					LocalMsg_TEMP( player, "#TMP_28" )
				else
					LocalMsg_TEMP( player, "#TMP_30", targetPlayer.p.name )
			}
		}
		else
			LocalMsg_TEMP( player, "#TMP_29" )
	}
}

#if DEVELOPER 

	CustomTeam function DEV_GetPlayerCustomTeam( string query )
	{
		CustomTeam team 
		
		entity candidate = GetPlayer( query )
		if( !IsValid( candidate ) )
		{
			printl( "Invalid player" )
			return team
		}
		
		CustomTeam ornull candidateTeam = GetCustomTeamOfPlayer( candidate )
		if( candidateTeam == null )
		{
			printl( "Player has no team" )
			return team
		}
		
		expect CustomTeam ( candidateTeam )
		return candidateTeam
	}
#endif 