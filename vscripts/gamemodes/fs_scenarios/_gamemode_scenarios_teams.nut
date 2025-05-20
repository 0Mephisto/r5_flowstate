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
		printl( "[Scenarios] CustomTeam Init" )
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
		TeamsMsg( captain, "#FS_NEW_JOIN_REQUEST", player.p.name )
		
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
			//printf( "[Scenarios] Team fill is OFF(0) and player \"%s\" is waiting for teamates", string( player ) )
			return true
		}
			
		int mmTimeOut = GetCustomTeamSetting( team, "matchmaking_timeout" )
		if( Time() - team.lastRoundEndTime < mmTimeOut )
		{
			//printf( "[Scenarios] player \"%s\" is waiting for timeout of \"%d\"  remaining: %f", string( player ), mmTimeOut, mmTimeOut - ( Time() - team.lastRoundEndTime ) )
			return true
		}
		
		if( allowFill )
			return false
	}
				
	foreach( entity tPlayer in playerTeam )
	{
		if( !Gamemode1v1_IsPlayerInState( tPlayer, e1v1State.WAITING ) )
		{
			//printf( "[Scenarios] Not all players of team are in queue: %s", string( tPlayer ) )
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
		case -4: return "#FS_INV_SETT_VALUE";
		case -3: return "#FS_NOT_IN_TEAM";
		case -2: return "#FS_NOT_CAPTAIN";
		case -1: return "#FS_INV_TEAM_SETTING";
		case 0:  return "#FS_SAME_SETT_VALUE";
		case 1:  return "#FS_SETTING_SET";
		default: mAssert( 0, "Invalid" ); return "#FS_TEAMCMD_ERR_01";
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
		
	if( !IsStringNumeric( value ) )	
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
		mAssert( 0, "invalid setting was attempted to be set in table in %s()", FUNC_NAME() )
		return false
	}
		
	return true
}

//todo: notifications system, use "waiting for players", add "of team"

// add disconnect to remove player:
void function OnPlayerDisconnected_CustomTeam( entity player ) //✓
{
	RemovePlayerFromPlayersTeam( player )
	RevokeAllJoinRequests( player )
}

/*
	"Tokens"
	{
		"FS_TEAMHELP" "\n\n\n\n\n\n\n\n\n\n\n\n/team help                           - lists commands\n/team list                             - lists teams #\n/team make [name]                                               - makes a team\n/team info [player|uid|team ID]                       - info about team\n/team join [captain name/uid | team id]      - joins a team\n/team leave                                                               - leaves a team -> if no captains exist, team is destroyed\n\nCaptain only:\n\n/team accept [player|uid|id]                    - accepts join request by player or request id\n/team reject [player|uid|id]                      - declines join request by player or request id\n/team kick [player|uid|team member #]                       - kicks member from team\n/team makecaptain [player|uid|team member #]    - gives player captain privileges\n/team settings                                                 - lists teams settings and their values\n/team set [setting] [value]                         - sets a team setting"
		"FS_IN_TEAM" "Already in team"
		"FS_ERR_CMD_PARAM_LEN" "Error with command parameter length"
		"FS_INVALID_TEAM" "Invalid team"
		"FS_PLAYER_NOT_OWNER" "Player does not own a team"
		"FS_TEAM_FULL" "Team is full"
		"FS_JOIN_REQUEST_COOLDOWN" "Join request cooldown"
		"FS_NOT_IN_TEAM" "Not in a team"
		"FS_PLAYER_LEFT_TEAM" "Player left the team: "
		"FS_PLAYER_JOINED_TEAM" "Player joined the team: "
		"FS_YOU_JOINED_TEAM" "You joined team: "
		"FS_FAILED_JOIN_TEAM" "Failed to join team: "
		"FS_NEW_JOIN_REQUEST" "New join request: "
		"FS_JOIN_REQUEST_SENT" "Team join request sent to: "
		"FS_LEFT_TEAM" "You left team: "
		"FS_FAILED_LEAVE_TEAM" "Failed to leave team: "
		"FS_JOIN_REQ_FAILED" "Join request failed for team: "
		"FS_TEAMNAME_MAXLEN" "Failed. Max length for teamname is: "
		"FS_TEAM_CREATED" "Team created successfully"
		"FS_FAILED_CREATETEAM" "Failed to create team"
		"FS_TEAMINFO_ERR" "Command \"team info\" Requires team # or player of team as last parameter"
		"FS_ALL_TEAMS" "All Teams"
		"FS_TEAM_INFO" "Team info"
		"FS_HELP_INFO" "Help info"
		"FS_TEAM_DISMANTLED" "Team was dismantled"
		"FS_JOIN_REQ" "Join requests"
		"FS_TEAMS_CMDHLP_01" "Command requires last parameter of id/player"
		"FS_TEAMS_FAIL_REQ" "Failed to accept/reject request"
		"FS_INV_REQ_PLAYER" "Invalid request player"
		"FS_REQ_REVOKED" "Request revoked for: "
		"FS_INV_TEAM_PLAYER" "Invalid team player"
		"FS_TEAMKICK_FAIL" "Failed to kick player"
		"FS_PLAYER_NOT_ON_TEAM" "Player not on team"
		"FS_PLAYER_CAPTAIN_ERR" "Player already captain"
		"FS_ADDED_CAPTAIN" "Added as captain: "
		"FS_TEAM_SETTINGS" "Team Settings"
		"FS_NOT_CAPTAIN" "Not captain of team"
		"FS_INV_TEAM_SETTING" "Invalid setting"
		"FS_SAME_SETT_VALUE" "Setting is already this value"
		"FS_INV_SETT_VALUE" "Invalid value for setting. Numbers only"
		"FS_SETTING_SET" "Setting successfully set"
		"FS_TEAMCMD_ERR_01" "Command requires setting & value. ex: /team set fill 0"
		"FS_TEAMS_DISABLED" "Admin has disable teams"
		"FS_NOT_ON_A_TEAM" "Not on any team"
		"FS_SUCCESS" "Success"
		"FS_FAILED" "Failed"
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
					TeamsMsg( teamPlayer, "#FS_PLAYER_LEFT_TEAM", player.p.name )
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
		TeamsMsg( player, "#FS_TEAM_DISMANTLED" )
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
		printf( "[Scenarios] Player: \"%s\" had team, but could not find it. Returning.", string( player ) )
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
		TeamsMsg( teamPlayer, "#FS_PLAYER_LEFT_TEAM", player.p.name )
	
	team.players.append( player )
	player.p.hasTeam = true
	
	TeamsMsg( player, "#FS_YOU_JOINED_TEAM", team.name )	
	return true
}

CustomTeam ornull function FindTeamFromQuery( string query ) //✓
{
	entity captainOfTeam 	= GetPlayer( query )	
	
	if( !IsValid( captainOfTeam ) )
	{
		if( IsStringNumeric( query ) )
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
		if( Gamemode1v1_IsPlayerWaiting( player ) )
			state = "In-Queue"
		else if( Gamemode1v1_IsPlayerResting( player ) )
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
				if( teamLen > 0 && IsStringNumeric( param, 0, teamLen - 1 ) )
					targetPlayer = team.players[ param.tointeger() ]
				break 
			
			case "requests":
				int requestsLen = team.teamJoinRequests.len()
				if( requestsLen > 0 && IsStringNumeric( param, 0, requestsLen - 1 ) )
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
		TeamsMsg( player, "#FS_TEAMS_DISABLED" )
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
			LocalMsg( player, "#FS_HELP_INFO", "#FS_TEAMHELP", eMsgUI.DEFAULT, 35.0 )
			return
		
		case "list":
			if( !CheckRate( player, "teams_stream", 2.5, true ) )
				return
				
			string listInfo = GetAllTeamsListString()
			
			TeamsMsg( player, "#FS_ALL_TEAMS", listInfo, 10.0 )			
			return
		
		case "info":
			if( !CheckRate( player, "teams_stream", 1.5, true ) )
				return
			
			CustomTeam ornull potentialTeam
			if( param == "" )
			{
				if( !player.p.hasTeam )
				{
					TeamsMsg( player, "#FS_NOT_ON_A_TEAM" )
					return
				}
				
				potentialTeam = GetCustomTeamOfPlayer( player )
			}
			else 
				potentialTeam = FindTeamFromQuery( param )
			
			if( potentialTeam == null )
			{
				TeamsMsg( player, "#FS_INVALID_TEAM" )
				return 
			}
			
			expect CustomTeam ( potentialTeam )	
			
			string teamInfo = GetTeamInfo( potentialTeam )			
			TeamsMsg( player, "#FS_TEAM_INFO", teamInfo, 10.0 )
			
			return
		
		case "make":
			if( player.p.hasTeam )
			{
				TeamsMsg( player, "#FS_IN_TEAM" )
				return
			}
			
			if( param != "" && param.len() > MAX_TEAMNAME_LEN )
			{
				TeamsMsg( player, "#FS_TEAMNAME_MAXLEN", MAX_TEAMNAME_LEN.tostring() )
				return
			}
			
			param = StringReplace( param, "\"", "" )
			if( CreateCustomTeam( player, param ) )
				TeamsMsg( player, "#FS_TEAM_CREATED" )
			else
				TeamsMsg( player, "#FS_FAILED_CREATETEAM" )
				
			return
		
		case "join":
		
			if( !CheckRate( player, "join_team", 5.0, true ) )
			{
				TeamsMsg( player, "#FS_JOIN_REQUEST_COOLDOWN" )
				return 
			}
		
			if( player.p.hasTeam )
			{
				TeamsMsg( player, "#FS_IN_TEAM" )
				return
			}

			if( param.len() > 20 )
			{
				TeamsMsg( player, "#FS_ERR_CMD_PARAM_LEN" )
				return
			}
			
			CustomTeam ornull potentialTeam = FindTeamFromQuery( param )
			
			if( potentialTeam == null )
			{
				TeamsMsg( player, "#FS_INVALID_TEAM" )
				return 
			}
			
			expect CustomTeam ( potentialTeam )

			if( potentialTeam.players.len() >= FS_Scenarios_PlayersPerTeam() )
			{
				TeamsMsg( player, "#FS_TEAM_FULL" )
				return
			}
			
			if( potentialTeam.customTeamSettings[ "anyone_can_join" ] == 1 )
			{
				if( AddPlayerToTeam( player, potentialTeam ) )
					TeamsMsg( player, "#FS_YOU_JOINED_TEAM", potentialTeam.name )
				else 
					TeamsMsg( player, "#FS_FAILED_JOIN_TEAM", potentialTeam.name )
			}
			else 
			{
				if( RequestJoinTeam( player, potentialTeam ) )
					TeamsMsg( player, "#FS_JOIN_REQUEST_SENT", potentialTeam.name )
				else 
					TeamsMsg( player, "#FS_JOIN_REQ_FAILED", potentialTeam.name )
			}
			
			return
	}
		
	//requires team
	switch( command )
	{		
		case "leave":
		
			if( !player.p.hasTeam )
			{
				TeamsMsg( player, "#FS_NOT_IN_TEAM" )
				return
			}

			if( RemovePlayerFromPlayersTeam( player ) )
				TeamsMsg( player, "#FS_LEFT_TEAM" )
			else 
				TeamsMsg( player, "#FS_JOIN_REQ_FAILED" )
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
				TeamsMsg( player, "#FS_NOT_ON_A_TEAM" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				TeamsMsg( player, "#FS_NOT_CAPTAIN" )
				return
			}
				
			TeamsMsg( player, "#FS_JOIN_REQ", GetJoinRequestsString( team ) )		
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
				LocalMsg( player, "#FS_FAILED", "#FS_TEAMS_CMDHLP_01" )
				return
			}
			
			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				TeamsMsg( player, "#FS_NOT_ON_A_TEAM" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				TeamsMsg( player, "#FS_NOT_CAPTAIN" )
				return
			}

			entity targetPlayer = FindTeamPlayerFromQuery( param, team, "action" )
			
			if( IsValid( player ) )
			{
				if( !IsOnTeam( targetPlayer, team ) )
				{
					TeamsMsg( player, "#FS_PLAYER_NOT_ON_TEAM" )
					return
				}
			
				if( !RemovePlayerFromTeam( targetPlayer, team ) )
					TeamsMsg( player, "#FS_TEAMKICK_FAIL" )
			}
			else 
				TeamsMsg( player, "#FS_INV_TEAM_PLAYER" )
			
			return 
		
		case "makecaptain":
			
			if( param == "" )
			{
				LocalMsg( player, "#FS_FAILED", "#FS_TEAMS_CMDHLP_01" )
				return
			}
			
			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				TeamsMsg( player, "#FS_NOT_ON_A_TEAM" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				TeamsMsg( player, "#FS_NOT_CAPTAIN" )
				return
			}
			
			entity targetPlayer = FindTeamPlayerFromQuery( param, team, "action" )		
			
			if( IsValid( player ) )
			{
				if( !IsOnTeam( targetPlayer, team ) )
				{
					TeamsMsg( player, "#FS_PLAYER_NOT_ON_TEAM" )
					return
				}
				
				if( IsCaptainOfTeam( targetPlayer, team ) )
				{
					TeamsMsg( player, "#FS_PLAYER_CAPTAIN_ERR" )
					return
				}
				
				team.captains.append( targetPlayer )
				TeamsMsg( player, "#FS_ADDED_CAPTAIN", targetPlayer.p.name )
			}
			else 
				TeamsMsg( player, "#FS_INV_TEAM_PLAYER" )
			
			return
		
		case "settings":
		
			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				TeamsMsg( player, "#FS_NOT_ON_A_TEAM" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				TeamsMsg( player, "#FS_NOT_CAPTAIN" )
				return
			}
				
			string currentSettings = GetTeamSettingsString( team ) 
			TeamsMsg( player, "#FS_TEAM_SETTINGS", currentSettings, 10.0 )
			return
		
		case "set":
		
			if( param == "" || param2 == "" )
			{
				LocalMsg( player, "#FS_FAILED", "#FS_TEAMCMD_ERR_01" )
				return
			}

			CustomTeam ornull team = GetCustomTeamOfPlayer( player )
			if( team == null )
			{
				TeamsMsg( player, "#FS_NOT_ON_A_TEAM" )
				return
			}
			
			expect CustomTeam ( team )
			if( !IsCaptainOfTeam( player, team ) )
			{
				TeamsMsg( player, "#FS_NOT_CAPTAIN" )
				return
			}		
			
			if( param == "name" )
			{ 
				if( param2.len() > MAX_TEAMNAME_LEN )
				{
					TeamsMsg( player, "#FS_TEAMNAME_MAXLEN", MAX_TEAMNAME_LEN.tostring() )
					return
				}
				
				team.name = param2
				TeamsMsg( player, "#FS_SETTING_SET" )
				return
			}
			
			if( !( param in file.paramToSettingTbl ) )
			{
				TeamsMsg( player, "#FS_INV_TEAM_SETTING" )
				return
			}
			
			int result = SetCustomTeamSetting( player, file.paramToSettingTbl[ param ], param2 )
			
			string statusToken
			if( result == 1 )
				statusToken = "#FS_SUCCESS"
			else
				statusToken = "#FS_FAILED"
			
			TeamsMsg( player, statusToken, GetTokenResponseForSetting( result ) )
			return
	}
	
	if( bAccept || bReject )
	{
		CustomTeam ornull team = GetCustomTeamOfPlayer( player )
		if( team == null )
		{
			TeamsMsg( player, "#FS_NOT_ON_A_TEAM" )
			return
		}
		
		expect CustomTeam ( team )
		if( !IsCaptainOfTeam( player, team ) )
		{
			TeamsMsg( player, "#FS_NOT_CAPTAIN" )
			return
		}
				
		if( param == "" )
		{
			LocalMsg( player, "#FS_FAILED", "#FS_TEAMS_CMDHLP_01" )
			return
		}
		
		entity targetPlayer = FindTeamPlayerFromQuery( param, team, "requests" )
		
		if( IsValid( targetPlayer ) )
		{
			if( !team.teamJoinRequests.contains( targetPlayer ) )
			{
				TeamsMsg( player, "#FS_INV_REQ_PLAYER" )
				return
			}
		
			if( bAccept )
			{
				if( !AcceptJoinRequest( player, targetPlayer ) )//no need to print success message, all players get an alert on accept.
					TeamsMsg( player, "#FS_TEAMS_FAIL_REQ" )
			}
			else if( bReject )
			{
				if( !RevokeJoinRequest( targetPlayer, team ) )
					TeamsMsg( player, "#FS_TEAMS_FAIL_REQ" )
				else
					TeamsMsg( player, "#FS_REQ_REVOKED", targetPlayer.p.name )
			}
		}
		else
			TeamsMsg( player, "#FS_INV_REQ_PLAYER" )
	}
}

void function TeamsMsg( entity player, string token, string varString = "", float duration = 5.0 )
{
	#if DEVELOPER 
		mAssert( varString.find( "#" ) != 0, "Use LocalMsg() instead of TeamsMsg() for passing more than one token." )
	#endif
	
	LocalMsg( player, token, "#FS_NULL", eMsgUI.DEFAULT, duration, "", varString )
}

#if DEVELOPER 

	CustomTeam function DEV_GetPlayerCustomTeam( string query )
	{
		CustomTeam team 
		
		entity candidate = GetPlayer( query )
		if( !IsValid( candidate ) )
		{
			printl( "[Scenarios] Invalid player" )
			return team
		}
		
		CustomTeam ornull candidateTeam = GetCustomTeamOfPlayer( candidate )
		if( candidateTeam == null )
		{
			printl( "[Scenarios] Player has no team" )
			return team
		}
		
		expect CustomTeam ( candidateTeam )
		return candidateTeam
	}
#endif 