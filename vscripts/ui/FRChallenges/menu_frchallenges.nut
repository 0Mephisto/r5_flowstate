global function InitFRChallengesResultsMenu
global function OpenFRChallengesMenu
global function CloseFRChallengesMenu
global function UpdateFRChallengeResultsTimer
global function UpdateResultsData

struct
{
	var menu
} file

void function OpenFRChallengesMenu()
{
	CloseAllMenus()
	EmitUISound("UI_Menu_MatchSummary_Appear")
	AdvanceMenu( file.menu )
}

void function CloseFRChallengesMenu()
{
	CloseAllMenus()
}

void function InitFRChallengesResultsMenu( var newMenuArg )
{
	var menu = GetMenu( "FRChallengesMenu" )
	file.menu = menu

    AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnR5RSB_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnR5RSB_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnR5RSB_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnR5RSB_NavigateBack )
	
	AddEventHandlerToButton( file.menu, "SkipButton", UIE_CLICK, SkipButtonFunct )
	AddEventHandlerToButton( file.menu, "RestartButton", UIE_CLICK, RestartButtonFunct )
}

void function UpdateResultsData(string challengeName, int shotHits, int dummiesKilled, float accuracy, int damageDealt, int criticalShots, int bestShotsHitRecord, bool isNewRecord)
{
	string accuracyShort = LocalizeAndShortenNumber_Float(accuracy * 100, 3, 2)

	if ( accuracyShort == "-na,n(i,nd).-n" || accuracyShort == "-nan(ind)" || accuracyShort == "-na.n(i.nd),-n" )
		accuracyShort = "0"

	#if DEVELOPER
	printt(accuracyShort)
	#endif

	Hud_SetText(Hud_GetChild( file.menu, "Title"), challengeName)
	Hud_SetText(Hud_GetChild( file.menu, "ResultsText"), "DUMMIES KILLED") //Temp, add to localizations
	Hud_SetText(Hud_GetChild( file.menu, "DummiesKilledResult"), dummiesKilled.tostring())
	Hud_SetText(Hud_GetChild( file.menu, "AccuracyResult"), accuracyShort + "%")
	Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResult"), shotHits.tostring())
	Hud_SetText(Hud_GetChild( file.menu, "DamageDoneResult"), damageDealt.tostring())
	Hud_SetText(Hud_GetChild( file.menu, "CriticalShotsResult"), criticalShots.tostring())
	Hud_SetText(Hud_GetChild( file.menu, "PersonalBestData"), "THIS SESSION BEST:  " + bestShotsHitRecord.tostring())
	
	if ( isNewRecord ) 
	{
		Hud_SetText(Hud_GetChild( file.menu, "WasNotNewPersonalBest"), "")
		Hud_SetText(Hud_GetChild( file.menu, "WasNewPersonalBest"), "NEW BEST SCORE")
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinalWasNotNew"), "")
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinal"), shotHits.tostring())
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinal2WasNotNew"), "")
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinal2"), "Hits")
	}
	else
	{
		Hud_SetText(Hud_GetChild( file.menu, "WasNotNewPersonalBest"), "TRY AGAIN!")
		Hud_SetText(Hud_GetChild( file.menu, "WasNewPersonalBest"), "")
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinalWasNotNew"), shotHits.tostring())
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinal"), "")
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinal2WasNotNew"), "Hits")
		Hud_SetText(Hud_GetChild( file.menu, "ShotsHitResultFinal2"), "")
	}
}
	
void function UpdateFRChallengeResultsTimer(int timeleft)
{
	var rui = Hud_GetChild( file.menu, "TimerText" )
	Hud_SetText(rui, timeleft.tostring() + "s")
}

void function SkipButtonFunct(var button)
{
	EmitUISound("UI_Menu_SelectMode_Close")
	RunClientScript("SkipButtonResultsClient")
}

void function RestartButtonFunct(var button)
{
	EmitUISound("UI_Menu_SelectMode_Close")
	RunClientScript("RestartButtonResultsClient")
}

void function OnR5RSB_Show()
{
}

void function OnR5RSB_Open()
{
}

void function OnR5RSB_Close()
{
}

void function OnR5RSB_NavigateBack()
{
	EmitUISound("UI_Menu_SelectMode_Close")
	RunClientScript("SkipButtonResultsClient")
}