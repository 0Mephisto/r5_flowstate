//Made by @CafeFPS
//todo: add how much time to wait before ignoring ibmm
//todo: add max latency allowed for enemy

untyped

global function Init_1v1_SettingsMenu
global function FS_1v1_SettingsMenu_Open
global function FS_1v1_SettingsMenu_Close

struct
{
	var menu

} file


void function Init_1v1_SettingsMenu( var newMenuArg )
{
	var menu = GetMenu( "1v1_SetttingsMenu" )
	file.menu = menu

    // AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	// AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RSB_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_Close )

	AddButtonEventHandler( Hud_GetChild( file.menu, "GoBackButton"), UIE_CLICK, GoBackButtonFunct )
	
	AddButtonEventHandler( Hud_GetChild( file.menu, "SupportFlowstate"), UIE_CLICK, SupportFS)
	AddButtonEventHandler( Hud_GetChild( file.menu, "SupportR5R"), UIE_CLICK, SupportR5R)
	
	SetMenuReceivesCommands( menu, false )
	SetGamepadCursorEnabled( menu, true )

	AddButtonEventHandler( Hud_GetChild( file.menu, "ToggleRestButton"), UIE_CLICK, ToggleRestButton )
	// AddButtonEventHandler( Hud_GetChild( file.menu, "SpectateButton"), UIE_CLICK, SpectateButton )
	// AddButtonEventHandler( Hud_GetChild( file.menu, "WeaponsMenuButton"), UIE_CLICK, WeaponsMenuButton )
	
	AddButtonEventHandler( Hud_GetChild( file.menu, "StartInRestButton"), UIE_CHANGE, StartInRestButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "IBMMButton"), UIE_CHANGE, IBMMButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "AcceptChallengesButton"), UIE_CHANGE, AcceptChallengesButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "ShowInputBannerButton"), UIE_CHANGE, ShowInputBannerButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "VsUIButton"), UIE_CHANGE, ShowVsUIButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "CamoColorButton"), UIE_CHANGE, CamoColorButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "HeirloomButton"), UIE_CHANGE, HeirloomButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "CharmButton"), UIE_CHANGE, CharmButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "IBMMWaitTimeButton"), UIE_CHANGE, MaxIBMMTimeButtonChange )
	AddButtonEventHandler( Hud_GetChild( file.menu, "MaxLatencyAllowedButton"), UIE_CHANGE, MaxEnemyLatencyButtonChange )
	
	Hud_SetSelected( Hud_GetChild( file.menu, "ToggleRestButton"), true )
	Hud_SetSelected( Hud_GetChild( file.menu, "ToggleRestButton"), true )
}

void function FS_1v1_SettingsMenu_Open( )
{
	CloseAllMenus()
	EmitUISound( "UI_Menu_FriendInspect" )
	AdvanceMenu( file.menu )
}

void function FS_1v1_SettingsMenu_Close( )
{
	CloseAllMenus()
	EmitUISound( "UI_Menu_FriendInspect" )
}

void function GoBackButtonFunct(var button)
{
	CloseAllMenus()
	
	if( IsConnected() )
	{
		// RunClientScript("CloseFRChallengesSettingsWpnSelector")
		RunClientScript("FS_1v1_DisplayHints", -1)
	}
}

void function OnR5RSB_Show()
{
    //
}

void function OnR5RSB_Open()
{
	//
}


void function OnR5RSB_Close()
{
	GoBackButtonFunct(null)
}

void function ToggleRestButton(var button)
{
	ClientCommand( "rest" )
}

void function SpectateButton(var button)
{
	ClientCommand( "spectate_1v1" )
}

void function WeaponsMenuButton(var button)
{
	OpenWeaponSelector()
}

void function StartInRestButtonChange(var button)
{
	ClientCommand( "CC_1v1_StartInRest " + GetConVarInt("fs_1v1_startinrest").tostring())
}

void function IBMMButtonChange(var button)
{
	ClientCommand( "CC_1v1_IBMM " + GetConVarInt("fs_1v1_ibmm").tostring())
	
	if(GetConVarInt("fs_1v1_ibmm").tostring() == "0")
	{
		SetConVarInt( "fs_1v1_maxibmmtime", 0 )
	}
	else if(GetConVarInt("fs_1v1_ibmm").tostring() == "1")
	{
		SetConVarInt( "fs_1v1_maxibmmtime", 3 )
	}	
}

void function AcceptChallengesButtonChange(var button)
{
	ClientCommand( "CC_1v1_AcceptChallenges " + GetConVarInt("fs_1v1_acceptchallenges").tostring())
}

void function ShowInputBannerButtonChange(var button)
{
	ClientCommand( "CC_1v1_ShowInputBanner " + GetConVarInt("fs_1v1_showinputbanner").tostring())
}

void function ShowVsUIButtonChange(var button)
{
	ClientCommand( "CC_1v1_ShowVsUI " + GetConVarInt("fs_1v1_showvsui").tostring())
	
	RunClientScript( "SetShow1v1Scoreboard", GetConVarInt("fs_1v1_showvsui").tostring() )
}

void function CamoColorButtonChange(var button)
{
	ClientCommand( "CC_1v1_CamoColor " + GetConVarInt("fs_1v1_camo").tostring())
}

void function HeirloomButtonChange(var button)
{
	ClientCommand( "CC_1v1_Heirloom " + GetConVarInt("fs_1v1_heirloom").tostring())
}

void function CharmButtonChange(var button)
{
	ClientCommand( "CC_1v1_Charm " + GetConVarInt("fs_1v1_charm").tostring())
}

void function MaxEnemyLatencyButtonChange(var button)
{
	ClientCommand( "CC_1v1_MaxEnemyLatency " + GetConVarInt("fs_1v1_maxenemylatency").tostring())
}

void function MaxIBMMTimeButtonChange(var button)
{
	ClientCommand( "CC_1v1_MaxIBMMTime " + GetConVarInt("fs_1v1_maxibmmtime").tostring())

	if( GetConVarInt("fs_1v1_maxibmmtime") <= 0 )
	{
		SetConVarInt( "fs_1v1_ibmm", 0 )
		ClientCommand( "CC_1v1_IBMM 0")
	}
	else
	{
		SetConVarInt( "fs_1v1_ibmm", 1 )
		ClientCommand( "CC_1v1_IBMM 1")
	}
}

void function SupportFS(var button)
{
	LaunchExternalWebBrowser( "https://ko-fi.com/r5r_colombia", WEBBROWSER_FLAG_NONE )
}

void function SupportR5R(var button)
{
	LaunchExternalWebBrowser( "https://ko-fi.com/amos0", WEBBROWSER_FLAG_NONE )
}