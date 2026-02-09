For Players:

- Added the ability to cancel wraith q with tactical button after entering the void
- Removed Helmets from realistic TTV playlist (mode)
- 1v1: Added legend select to esc menu buttons
- 1v1: Added view champion card to esc menu buttons
- Weapons menu: Added a 'reset' button for quickly resetting saved guns.
- MOTD will automatically show *one time* for any server you join unless changed in settings under "ACCESSIBILITY"
- Fixed not being able to heal some times in realistic ttv building playlist ( mode )
- Fixed weapons not saving in realistic ttv building playlist ( mode )
- Fixed start in rest setting applying when joining a 1v1 server mid-game.
- Taking damage ( other than ring damage ) now closes a deathbox if setting "Taking Damage Closes Deathbox or Menu" is set to on.
- Fixed not being able to recall drone in fs_rankupmapmovementpractice
- New gamemode envisioned by SlapsMcGaps, implemented by mkos: fs_grapples_n_guns
- disabled battle chatter for fs_grapples_n_guns
- Added several text to all 12 languages
- added settings menu setting to persist cl_show pos info with localization tokens
- fixed movement recorder playback duration display
- potential fix for sometimes spawning backwards in 1v1 applied
- prevent ability to melee or do damage in rest to prevent any exploits
- added ability to enable cl_showfps from in game settings. Saves to settings.
- Added warning dialog for when launching in developer mode
- Added warning dialog for when launching in client mode
- Added 3p client command to rankup map practice playlist

For Hosts:

- Added playlist var 'enable_loose_playername_comparison', which allows partial playername searches when doing cc commands - also works for things like chal. Example for a player named BobTheBuilder:  /chal bob  -- will match for "BobTheBuilder"
- New proto feature to reserve at least one admin slot by enabling the feature in playlists via playlist var: reserve_admin_slot
- Realistic TTV building now has a proto feature to spawn ai on a random player if playlist var 'random_dummy_spawn' is eanbled, and can be configured with: random_dummy_spawn_mintime and random_dummy_spawn_maxtime
- fixed disable pings playlist var.  Setting playlist var 'player_can_ping' to 0 will disable all player pings for the specified playlist.
- fixed 'cc map' command not loading specified playlist if gamemode was omitted in params.
- For servers running tracker, loop messages now function again. Todo: Global feature
- fix motd showing on join for players automatically on first join
- cc command to enable/disable map rotation
- added ability to change stim duration from playlists file via playlist var float:  octane_stim_duration
- Added a crypto disable scan playlist var to prevent crypto drones from scanning players. Set with 'disable_crypto_scan'. This was set to 1 for playlist: fs_rankupmapmovementpractice
- Set playlist var teammate_huds_enabled to 0 for fs_rankupmapmovementpractice
- Add abiltiy to disable giving items by default from playlist: give_basic_survival_items: Note this can interfere with loadout related abilities in survival playlists
- Validate admin provided timeout time, if it is less than or equal to 0, uses default timeout time set in playlist with playlist var: 'timeout_default_time'
- All cc admin commands that allow a reason to be specified now require you to add the reason with -r or -reason followed by the reason in quotes. Example: cc kick bobthebuilder -r "Bad boy"
- Timestring arguments for time units now additionally accept 's', 'd', 'm' and 'y' for seconds, days, months, and years respectively.
- Fixed an issue where game logic would not work correctly for admins causing IBMM to malfunction.
- Added the ability to register weapons from scripts ( complementing rpak/playlist registration )
- Added the ability to register worlddraw assets from scripts ( complementing playlist/rpak registration )
- CC admin commands that a reason is provided for can also be annoucned to the server by adding -say. Example:    cc kick bobthebuilder -r "Can't build" -say
- weapons charms are now disabled for a mode unless playlist var: flowstate_givecharms_weapons is set to 1.
- Removed giving helmets consistently unless playlist var: enable_helmets is set to 1
- added an additional spawn set for aqueduct
- expanded the SpawnSystem options to be able to cycle a list of spawn sets for each map as confgiured in playlist and enabled playlist var: spawnpaks_rotate_all 1
- added playlist vars to movement recorder for:  enable_helmets(default 0), dummy_shield_level(default 2 = blue ), dummy_health( default = 100 )
- Added 1v1 exploit protection for melee from rest -- If any issues arrive for 1v1 gamemode with not being able to melee or damage during a fight, you can set enable_state_flags to 0 in playlists file.
- Added the ability to disable message sounds via playlist with playlist var: disable_message_sounds

The following commands can utilize -say
[
    cc kick
    cc ban
    cc timeout
    cc mute
]

- Removed commands: cc kicksay, cc bansay


Misc (Scripters):

- restore playlist override to blank after usage so that subsequent usage of server browser loading does not get locked to previous override.
- badge stat crash fix
- fix a bug not allowing you to do 'cc map' to reload current map playlist gamemode in some situations
- antiafk system had other logic relying on it's functionality, this was split to retain required logic, and optionally disable the afk thread if setting 'enable_afk_thread' or 'flowstate_afk_kick_enable' is disabled.
- Temporarily limited custom audio queues to only one group until rework is done.
- added FS callback registry for onspawned to remove the need for threading and waiting to control behavior
- fixed a crash exploit leftover from old respawn code
- reworked bannerassets to WorldAssets and revitalized with refactors.
- Made WorldAsset audio queues multi group compatible and remove s_audioQueueRegistered temp flag
- fixed a bug in replay hud not deactivating when killer becomes invalid
- created client sided AddCallback_OnPlayerConnected registry
- rework client stats to uid indexed and fixed preload bugs
- match timer bug and other issues fixed due to replay logic replaying
- fixed error message display when incorrectly using 'cc map'
- improve WorldAssets to allow playing a single asset for a specific asset group for a specific player
- disabled usage of use_r2_deathcam in combo with replay system due to crashes
- fixed an issue in rpaks cuasing mismatched server/client issues (fs_spawns contained audio datatables that don't belong there)
- removed specifying map for global rpaks in scripts/levels/settings
- fixed an issue in remote func float precision
- ability to register tracking as non combat mode and ship only live data for custom stats
- other minor bug fixes and feature/code improvements