global function Sh_ChallengesByColombia_Init

global int AimTrainer_CHALLENGE_DURATION = 60
global int AimTrainer_AI_HEALTH = 100
global int AimTrainer_AI_SHIELDS_LEVEL = 0
global int AimTrainer_AI_COLOR = 5
global float AimTrainer_STRAFING_SPEED = 1
global float AimTrainer_STRAFING_SPEED_WAITTIME = 1
global float AimTrainer_SPAWN_DISTANCE = 1
global bool RGB_HUD = false
global bool AimTrainer_INFINITE_CHALLENGE = false
global bool AimTrainer_INFINITE_AMMO = true
global bool AimTrainer_INFINITE_AMMO2 = false
global bool AimTrainer_INMORTAL_TARGETS = false
global bool AimTrainer_USER_WANNA_BE_A_DUMMY = false
global bool ENABLE_HIT_DOT = false

global const int AimTrainer_RESULTS_TIME = 10
global const float AimTrainer_PRE_START_TIME = 3.0 //description time

void function Sh_ChallengesByColombia_Init()
{
	//Time Over signal
	RegisterSignal("ChallengeTimeOver")
	RegisterSignal("ForceResultsEnd_SkipButton")
	PrecacheParticleSystem($"P_wpn_lasercannon_aim_short_blue")
}