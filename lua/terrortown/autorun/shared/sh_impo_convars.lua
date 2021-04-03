--ConVar syncing
--General
CreateConVar("ttt2_impostor_inform_everyone", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_normal_dmg_multi", "0.5", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Instant Kill
CreateConVar("ttt2_impostor_kill_dist", "125", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_kill_cooldown", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Venting
CreateConVar("ttt2_impostor_num_starting_vents", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_vent_capacity", "6", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_global_max_num_vents", "9", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_vent_placement_range", "100", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_hide_unused_vents", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_vent_secondary_fire_mode", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_traitor_team_can_use_vents", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Sabotage Station Management
CreateConVar("ttt2_impostor_station_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_station_manager_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_dissuade_station_reuse", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_min_station_dist", "1000", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_station_radius", "750", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_stop_station_ply_prop", "0.25", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_station_hold_time", "5", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Sabotage Lights
CreateConVar("ttt2_impostor_sabo_lights_cooldown", "180", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_lights_mode", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_lights_fade", "2.0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_lights_length", "5.0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_traitor_team_is_affected_by_sabo_lights", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Sabotage Comms
CreateConVar("ttt2_impostor_sabo_comms_cooldown", "120", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_comms_deafen", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_comms_length", "20", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_traitor_team_is_affected_by_sabo_comms", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Sabotage O2
CreateConVar("ttt2_impostor_sabo_o2_cooldown", "240", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_o2_hp_loss", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_o2_interval", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_o2_grace_period", "10", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_o2_stop_thresh", "10", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_o2_length", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_traitor_team_is_affected_by_sabo_o2", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_is_affected_by_sabo_o2", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Special Role Handling
CreateConVar("ttt2_impostor_inform_about_non_traitors_venting", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_trapper_venting_time", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_inform_trappers_about_venting", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_jesters_can_vent", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_dopt_special_handling", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicImpostorCVars", function(tbl)
	tbl[ROLE_IMPOSTOR] = tbl[ROLE_IMPOSTOR] or {}
	
	--# At the beginning of the round, should everyone be told how many impostors are among us?
	--  ttt2_impostor_inform_everyone [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_inform_everyone",
		checkbox = true,
		desc = "ttt2_impostor_inform_everyone (Def: 0)"
	})
	
	--# How much damage should the impostor be able to do with traditional guns and crowbars?
	--  ttt2_impostor_normal_dmg_multi [0.0..n.m] (default: 0.5)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_normal_dmg_multi",
		slider = true,
		min = 0.0,
		max = 1.0,
		decimal = 2,
		desc = "ttt2_impostor_normal_dmg_multi (Def: 0.5)"
	})
	
	--# What is the range on the impostor's instant-kill ability?
	--  ttt2_impostor_kill_dist [0..n] (default: 125)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_kill_dist",
		slider = true,
		min = 0,
		max = 1000,
		decimal = 0,
		desc = "ttt2_impostor_kill_dist (Def: 125)"
	})
	
	--# What is the cooldown (in seconds) on the impostor's instant-kill ability?
	--  ttt2_impostor_kill_cooldown [0..n] (default: 30)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_kill_cooldown",
		slider = true,
		min = 0,
		max = 120,
		decimal = 0,
		desc = "ttt2_impostor_kill_cooldown (Def: 30)"
	})
	
	--# How many vents does the impostor start with?
	--  ttt2_impostor_num_starting_vents [0..n] (default: 3)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_num_starting_vents",
		slider = true,
		min = 0,
		max = 10,
		decimal = 0,
		desc = "ttt2_impostor_num_starting_vents (Def: 3)"
	})
	
	--# How many vents does can the impostor hold?
	--  ttt2_impostor_vent_capacity [0..n] (default: 6)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_vent_capacity",
		slider = true,
		min = 0,
		max = 10,
		decimal = 0,
		desc = "ttt2_impostor_vent_capacity (Def: 6)"
	})
	
	--# What is the maximum number of vents allowed on the map (-1 for unlimited)?
	--  ttt2_impostor_global_max_num_vents [-1..n] (default: 9)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_global_max_num_vents",
		slider = true,
		min = -1,
		max = 15,
		decimal = 0,
		desc = "ttt2_impostor_global_max_num_vents (Def: 9)"
	})
	
	--# What is the range on the Impostor's vent placement tool?
	--  ttt2_impostor_vent_placement_range [0..n] (default: 100)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_vent_placement_range",
		slider = true,
		min = 0,
		max = 1000,
		decimal = 0,
		desc = "ttt2_impostor_vent_placement_range (Def: 100)"
	})
	
	--# If set, newly created vents will attempt to use the creator's position as the exit point (as long as the vent is close enough to them).
	--    Allows for quick and creative vent placement. Can lead to map abuse (i.e. hiding vents in ridiculous locations).
	--  If not set, all created vents (regardless of placement distance) will attempt to set the exit point out and in front automatically.
	--    Enforces sane vent placement. However, the user will be forced to place vents on walls near the floor in most scenarios.
	--  ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit",
		checkbox = true,
		desc = "ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit (Def: 1)"
	})
	
	--# Should vents be invisible upon creation, only being revealed when entered or exited?
	--  ttt2_impostor_hide_unused_vents [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_hide_unused_vents",
		checkbox = true,
		desc = "ttt2_impostor_hide_unused_vents (Def: 1)"
	})
	
	--# Can the secondary fire on the Vent tool be used to take back already placed vents?
	--  ttt2_impostor_vent_secondary_fire_mode [0..2] (default: 1)
	--  # 0: Impostors cannot take vents back
	--  # 1: Impostors can only take unrevealed vents back
	--  # 2: Impostors can take any kind of vent back
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_vent_secondary_fire_mode",
		combobox = true,
		desc = "ttt2_impostor_vent_secondary_fire_mode (Def: 1)",
		choices = {
			"0 - Impostors cannot take vents back",
			"1 - Impostors can only take unrevealed vents back",
			"2 - Impostors can take any kind of vent back"
		},
		numStart = 0
	})
	
	--# Should all traitor roles be able to use vents that the Impostor(s) have placed?
	--  ttt2_impostor_traitor_team_can_use_vents [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_traitor_team_can_use_vents",
		checkbox = true,
		desc = "ttt2_impostor_traitor_team_can_use_vents (Def: 1)"
	})
	
	--# Should the Impostor's sabotage abilities create a Sabotage Station entity (If disabled, the sabotage abilities can only end once their duration has been exceeded)?
	--  ttt2_impostor_station_enable [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_station_enable",
		checkbox = true,
		desc = "ttt2_impostor_station_enable (Def: 1)"
	})
	
	--# Should the Impostor be able to know where the sabotage station will spawn, be able to switch the spawn location, and add new station spawns?
	--  ttt2_impostor_station_manager_enable [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_station_manager_enable",
		checkbox = true,
		desc = "ttt2_impostor_station_manager_enable (Def: 1)"
	})
	
	--# Should Impostors be unable to create sabotage stations in the same place twice (until all available locations have been exhausted)?
	--  ttt2_impostor_dissuade_station_reuse [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_dissuade_station_reuse",
		checkbox = true,
		desc = "ttt2_impostor_dissuade_station_reuse (Def: 1)"
	})
	
	--# How far away can sabotage station spawn locations be from each other?
	--  ttt2_impostor_min_station_dist [0..n] (default: 1000)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_min_station_dist",
		slider = true,
		min = 0,
		max = 2000,
		decimal = 0,
		desc = "ttt2_impostor_min_station_dist (Def: 1000)"
	})
	
	--# What is the radius of the circle that players need to enter in order to disable the current sabotage?
	--  ttt2_impostor_station_radius [0..n] (default: 750)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_station_radius",
		slider = true,
		min = 0,
		max = 2000,
		decimal = 0,
		desc = "ttt2_impostor_station_radius (Def: 750)"
	})
	
	--# What proportion of the players (alive and dead, rounded up) need to enter the sabotage station's radius in order to end the current sabotage (ex. If 0.25, and there are 6 players, then at least 2 need to enter the station's radius)?
	--  Note: Both dead and alive players are counted for determining this threshold.
	--  ttt2_impostor_stop_station_ply_prop [0.0..n.m] (default: 0.25)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_stop_station_ply_prop",
		slider = true,
		min = 0.0,
		max = 1.0,
		decimal = 2,
		desc = "ttt2_impostor_stop_station_ply_prop (Def: 0.25)"
	})
	
	--# How long must enough players be in the sabotage station's radius to end it?
	--  ttt2_impostor_station_hold_time [0..n] (default: 5)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_station_hold_time",
		slider = true,
		min = 0,
		max = 10,
		decimal = 0,
		desc = "ttt2_impostor_station_hold_time (Def: 5)"
	})
	
	--# What is the cooldown (in seconds) on the impostor's Sabotage Lights ability?
	--  ttt2_impostor_sabo_lights_cooldown [0..n] (default: 180)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_lights_cooldown",
		slider = true,
		min = 0,
		max = 300,
		decimal = 0,
		desc = "ttt2_impostor_sabo_lights_cooldown (Def: 180)"
	})
	
	--# What should happen when the lights are sabotaged?
	--  ttt2_impostor_sabo_lights_mode [0..1] (default: 0)
	--  # 0: A Screen fade occurs, which blacks out the entire screen. Flashlights will not help you.
	--  # 1: Map lighting is temporarily disabled. Flashlights work. Effectiveness depends on map (ex. some props may still be fully lit, and players may be easier to see instead of harder)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_lights_mode",
		combobox = true,
		desc = "ttt2_impostor_sabo_lights_mode (Def: 0)",
		choices = {
			"0 - Screen fade (flashlights do nothing)",
			"1 - Disable map lighting (Strange behavior on certain maps)",
		},
		numStart = 0
	})
	
	--# How long (in seconds) should it take for lights to fade to black upon activating Sabotage Lights under Screen Fade mode (<= 0.0 to disable ability)?
	--  Note: Only applicable if ttt2_impostor_sabo_lights_mode is 0 (Screen fade mode)
	--  Note: Fade time is nonlinear. HUD's color difference may be off for large fade times..
	--  ttt2_impostor_sabo_lights_fade [0.0..n.m] (default: 2.0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_lights_fade",
		slider = true,
		min = 0.0,
		max = 30.0,
		decimal = 2,
		desc = "ttt2_impostor_sabo_lights_fade (Def: 2.0)"
	})
	
	--# How long (in seconds) should the lights be sabotaged for (< 0.0 to disable ability)?
	--  ttt2_impostor_sabo_lights_length [-n.m..n.m] (default: 5.0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_lights_length",
		slider = true,
		min = -1.0,
		max = 120.0,
		decimal = 2,
		desc = "ttt2_impostor_sabo_lights_length (Def: 5.0)"
	})
	
	--# Should all (non-Impostor) traitor roles be affected by an Impostor's Sabotage Lights?
	--  ttt2_impostor_traitor_team_is_affected_by_sabo_lights [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_traitor_team_is_affected_by_sabo_lights",
		checkbox = true,
		desc = "ttt2_impostor_traitor_team_is_affected_by_sabo_lights (Def: 0)"
	})
	
	--# What is the cooldown (in seconds) on the impostor's Sabotage Comms ability?
	--  ttt2_impostor_sabo_comms_cooldown [0..n] (default: 120)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_comms_cooldown",
		slider = true,
		min = 0,
		max = 300,
		decimal = 0,
		desc = "ttt2_impostor_sabo_comms_cooldown (Def: 120)"
	})
	
	--# During Sabotage Comms, should the affected be deafened in addition to having text/voice chat disabled?
	--  ttt2_impostor_sabo_comms_deafen [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_comms_deafen",
		checkbox = true,
		desc = "ttt2_impostor_sabo_comms_deafen (Def: 1)"
	})
	
	--# How long (in seconds) should the comms be sabotaged for (<= 0 to disable ability)?
	--  ttt2_impostor_sabo_comms_length [-n..m] (default: 20)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_comms_length",
		slider = true,
		min = 0,
		max = 120,
		decimal = 0,
		desc = "ttt2_impostor_sabo_comms_length (Def: 20)"
	})
	
	--# Should all (non-Impostor) traitor roles be affected by an Impostor's Sabotage Comms?
	--  ttt2_impostor_traitor_team_is_affected_by_sabo_comms [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_traitor_team_is_affected_by_sabo_comms",
		checkbox = true,
		desc = "ttt2_impostor_traitor_team_is_affected_by_sabo_comms (Def: 0)"
	})
	
	--# What is the cooldown (in seconds) on an Impostor's Sabotage O2 ability?
	--  ttt2_impostor_sabo_o2_cooldown [0..n] (default: 240)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_o2_cooldown",
		slider = true,
		min = 0,
		max = 300,
		decimal = 0,
		desc = "ttt2_impostor_sabo_o2_cooldown (Def: 240)"
	})
	
	--# For Sabotage O2, How much HP per second should be lost?
	--  ttt2_impostor_sabo_o2_hp_loss [1..n] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_o2_hp_loss",
		slider = true,
		min = 1,
		max = 10,
		decimal = 0,
		desc = "ttt2_impostor_sabo_o2_hp_loss (Def: 1)"
	})
	
	--# For Sabotage O2, How many seconds should occur between HP deductions?
	--  ttt2_impostor_sabo_o2_interval [1..n] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_o2_interval",
		slider = true,
		min = 1,
		max = 10,
		decimal = 0,
		desc = "ttt2_impostor_sabo_o2_interval (Def: 1)"
	})
	
	--# How many seconds until Sabotage O2 starts incurring hp loss?
	--  ttt2_impostor_sabo_o2_grace_period [0..n] (default: 10)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_o2_grace_period",
		slider = true,
		min = 0,
		max = 120,
		decimal = 0,
		desc = "ttt2_impostor_sabo_o2_grace_period (Def: 10)"
	})
	
	--# At what HP threshold should Sabotage O2 stop damaging a given player?
	--  ttt2_impostor_sabo_o2_stop_thresh [-n..m] (default: 10)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_o2_stop_thresh",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_impostor_sabo_o2_stop_thresh (Def: 10)"
	})
	
	--# How long (in seconds) should O2 be sabotaged for (<= 0 to disable ability)?
	--  ttt2_impostor_sabo_o2_length [-n..m] (default: 30)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_o2_length",
		slider = true,
		min = 0,
		max = 120,
		decimal = 0,
		desc = "ttt2_impostor_sabo_o2_length (Def: 30)"
	})
	
	--# Should all (non-Impostor) traitor roles be affected by an Impostor's Sabotage O2?
	--  ttt2_impostor_traitor_team_is_affected_by_sabo_o2 [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_traitor_team_is_affected_by_sabo_o2",
		checkbox = true,
		desc = "ttt2_impostor_traitor_team_is_affected_by_sabo_o2 (Def: 0)"
	})
	
	--# Should impostors be affected by their own Sabotage O2?
	--  ttt2_impostor_is_affected_by_sabo_o2 [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_is_affected_by_sabo_o2",
		checkbox = true,
		desc = "ttt2_impostor_is_affected_by_sabo_o2 (Def: 0)"
	})
	
	--# Should traitors be informed when a player who doesn't have a Traitor subrole enters and exits a vent?
	--  ttt2_impostor_inform_about_non_traitors_venting [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_inform_about_non_traitors_venting",
		checkbox = true,
		desc = "ttt2_impostor_inform_about_non_traitors_venting (Def: 1)"
	})
	
	--# Can the Trapper use the vents, and if so, for how long (Disabled if 0)?
	--  ttt2_impostor_trapper_venting_time [0..n] (default: 30)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_trapper_venting_time",
		slider = true,
		min = 0,
		max = 90,
		decimal = 0,
		desc = "ttt2_impostor_trapper_venting_time (Def: 30)"
	})
	
	--# Should trappers be informed when anyone enters and exits a vent?
	--  ttt2_impostor_inform_trappers_about_venting [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_inform_trappers_about_venting",
		checkbox = true,
		desc = "ttt2_impostor_inform_trappers_about_venting (Def: 1)"
	})
	
	--# Should jesters be able to use vents?
	--  ttt2_impostor_jesters_can_vent [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_jesters_can_vent",
		checkbox = true,
		desc = "ttt2_impostor_jesters_can_vent (Def: 0)"
	})
	
	--# Should Doppelgangers that have stolen a Traitor role be treated like Traitors for the Impostor (ex. have access to vents and sabotage immunity by default)?
	--  ttt2_impostor_dopt_special_handling [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_dopt_special_handling",
		checkbox = true,
		desc = "ttt2_impostor_dopt_special_handling (Def: 1)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddImpostorGlobals", function()
	SetGlobalBool("ttt2_impostor_inform_everyone", GetConVar("ttt2_impostor_inform_everyone"):GetBool())
	SetGlobalFloat("ttt2_impostor_normal_dmg_multi", GetConVar("ttt2_impostor_normal_dmg_multi"):GetFloat())
	SetGlobalInt("ttt2_impostor_kill_dist", GetConVar("ttt2_impostor_kill_dist"):GetInt())
	SetGlobalInt("ttt2_impostor_kill_cooldown", GetConVar("ttt2_impostor_kill_cooldown"):GetInt())
	SetGlobalInt("ttt2_impostor_num_starting_vents", GetConVar("ttt2_impostor_num_starting_vents"):GetInt())
	SetGlobalInt("ttt2_impostor_vent_capacity", GetConVar("ttt2_impostor_vent_capacity"):GetInt())
	SetGlobalInt("ttt2_impostor_global_max_num_vents", GetConVar("ttt2_impostor_global_max_num_vents"):GetInt())
	SetGlobalInt("ttt2_impostor_vent_placement_range", GetConVar("ttt2_impostor_vent_placement_range"):GetInt())
	SetGlobalBool("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit", GetConVar("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit"):GetBool())
	SetGlobalBool("ttt2_impostor_hide_unused_vents", GetConVar("ttt2_impostor_hide_unused_vents"):GetBool())
	SetGlobalInt("ttt2_impostor_vent_secondary_fire_mode", GetConVar("ttt2_impostor_vent_secondary_fire_mode"):GetInt())
	SetGlobalBool("ttt2_impostor_traitor_team_can_use_vents", GetConVar("ttt2_impostor_traitor_team_can_use_vents"):GetBool())
	SetGlobalBool("ttt2_impostor_station_enable", GetConVar("ttt2_impostor_station_enable"):GetBool())
	SetGlobalBool("ttt2_impostor_station_manager_enable", GetConVar("ttt2_impostor_station_manager_enable"):GetBool())
	SetGlobalBool("ttt2_impostor_dissuade_station_reuse", GetConVar("ttt2_impostor_dissuade_station_reuse"):GetBool())
	SetGlobalInt("ttt2_impostor_min_station_dist", GetConVar("ttt2_impostor_min_station_dist"):GetInt())
	SetGlobalInt("ttt2_impostor_station_radius", GetConVar("ttt2_impostor_station_radius"):GetInt())
	SetGlobalFloat("ttt2_impostor_stop_station_ply_prop", GetConVar("ttt2_impostor_stop_station_ply_prop"):GetFloat())
	SetGlobalInt("ttt2_impostor_station_hold_time", GetConVar("ttt2_impostor_station_hold_time"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_lights_cooldown", GetConVar("ttt2_impostor_sabo_lights_cooldown"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_lights_mode", GetConVar("ttt2_impostor_sabo_lights_mode"):GetInt())
	SetGlobalFloat("ttt2_impostor_sabo_lights_fade", GetConVar("ttt2_impostor_sabo_lights_fade"):GetFloat())
	SetGlobalFloat("ttt2_impostor_sabo_lights_length", GetConVar("ttt2_impostor_sabo_lights_length"):GetFloat())
	SetGlobalBool("ttt2_impostor_traitor_team_is_affected_by_sabo_lights", GetConVar("ttt2_impostor_traitor_team_is_affected_by_sabo_lights"):GetBool())
	SetGlobalInt("ttt2_impostor_sabo_comms_cooldown", GetConVar("ttt2_impostor_sabo_comms_cooldown"):GetInt())
	SetGlobalBool("ttt2_impostor_sabo_comms_deafen", GetConVar("ttt2_impostor_sabo_comms_deafen"):GetBool())
	SetGlobalInt("ttt2_impostor_sabo_comms_length", GetConVar("ttt2_impostor_sabo_comms_length"):GetInt())
	SetGlobalBool("ttt2_impostor_traitor_team_is_affected_by_sabo_comms", GetConVar("ttt2_impostor_traitor_team_is_affected_by_sabo_comms"):GetBool())
	SetGlobalInt("ttt2_impostor_sabo_o2_cooldown", GetConVar("ttt2_impostor_sabo_o2_cooldown"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_o2_hp_loss", GetConVar("ttt2_impostor_sabo_o2_hp_loss"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_o2_interval", GetConVar("ttt2_impostor_sabo_o2_interval"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_o2_grace_period", GetConVar("ttt2_impostor_sabo_o2_grace_period"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_o2_stop_thresh", GetConVar("ttt2_impostor_sabo_o2_stop_thresh"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_o2_length", GetConVar("ttt2_impostor_sabo_o2_length"):GetInt())
	SetGlobalBool("ttt2_impostor_traitor_team_is_affected_by_sabo_o2", GetConVar("ttt2_impostor_traitor_team_is_affected_by_sabo_o2"):GetBool())
	SetGlobalBool("ttt2_impostor_is_affected_by_sabo_o2", GetConVar("ttt2_impostor_is_affected_by_sabo_o2"):GetBool())
	SetGlobalBool("ttt2_impostor_inform_about_non_traitors_venting", GetConVar("ttt2_impostor_inform_about_non_traitors_venting"):GetBool())
	SetGlobalInt("ttt2_impostor_trapper_venting_time", GetConVar("ttt2_impostor_trapper_venting_time"):GetInt())
	SetGlobalBool("ttt2_impostor_inform_trappers_about_venting", GetConVar("ttt2_impostor_inform_trappers_about_venting"):GetBool())
	SetGlobalBool("ttt2_impostor_jesters_can_vent", GetConVar("ttt2_impostor_jesters_can_vent"):GetBool())
	SetGlobalBool("ttt2_impostor_dopt_special_handling", GetConVar("ttt2_impostor_dopt_special_handling"):GetBool())
end)

cvars.AddChangeCallback("ttt2_impostor_inform_everyone", function(name, old, new)
	SetGlobalBool("ttt2_impostor_inform_everyone", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_normal_dmg_multi", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_normal_dmg_multi", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_kill_dist", function(name, old, new)
	SetGlobalInt("ttt2_impostor_kill_dist", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_kill_cooldown", function(name, old, new)
	SetGlobalInt("ttt2_impostor_kill_cooldown", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_num_starting_vents", function(name, old, new)
	SetGlobalInt("ttt2_impostor_num_starting_vents", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_vent_capacity", function(name, old, new)
	SetGlobalInt("ttt2_impostor_vent_capacity", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_global_max_num_vents", function(name, old, new)
	SetGlobalInt("ttt2_impostor_global_max_num_vents", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_vent_placement_range", function(name, old, new)
	SetGlobalInt("ttt2_impostor_vent_placement_range", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit", function(name, old, new)
	SetGlobalBool("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_hide_unused_vents", function(name, old, new)
	SetGlobalBool("ttt2_impostor_hide_unused_vents", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_vent_secondary_fire_mode", function(name, old, new)
	SetGlobalInt("ttt2_impostor_vent_secondary_fire_mode", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_traitor_team_can_use_vents", function(name, old, new)
	SetGlobalBool("ttt2_impostor_traitor_team_can_use_vents", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_inform_about_non_traitors_venting", function(name, old, new)
	SetGlobalBool("ttt2_impostor_inform_about_non_traitors_venting", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_station_enable", function(name, old, new)
	SetGlobalBool("ttt2_impostor_station_enable", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_station_manager_enable", function(name, old, new)
	SetGlobalBool("ttt2_impostor_station_manager_enable", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_dissuade_station_reuse", function(name, old, new)
	SetGlobalBool("ttt2_impostor_dissuade_station_reuse", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_min_station_dist", function(name, old, new)
	SetGlobalInt("ttt2_impostor_min_station_dist", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_station_radius", function(name, old, new)
	SetGlobalInt("ttt2_impostor_station_radius", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_stop_station_ply_prop", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_stop_station_ply_prop", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_station_hold_time", function(name, old, new)
	SetGlobalInt("ttt2_impostor_station_hold_time", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_lights_cooldown", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_lights_cooldown", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_lights_mode", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_lights_mode", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_lights_fade", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_sabo_lights_fade", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_lights_length", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_sabo_lights_length", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_traitor_team_is_affected_by_sabo_lights", function(name, old, new)
	SetGlobalBool("ttt2_impostor_traitor_team_is_affected_by_sabo_lights", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_comms_cooldown", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_comms_cooldown", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_comms_deafen", function(name, old, new)
	SetGlobalBool("ttt2_impostor_sabo_comms_deafen", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_comms_length", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_comms_length", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_traitor_team_is_affected_by_sabo_comms", function(name, old, new)
	SetGlobalBool("ttt2_impostor_traitor_team_is_affected_by_sabo_comms", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_o2_cooldown", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_o2_cooldown", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_o2_hp_loss", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_o2_hp_loss", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_o2_interval", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_o2_interval", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_o2_grace_period", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_o2_grace_period", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_o2_stop_thresh", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_o2_stop_thresh", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_o2_length", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_o2_length", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_traitor_team_is_affected_by_sabo_o2", function(name, old, new)
	SetGlobalBool("ttt2_impostor_traitor_team_is_affected_by_sabo_o2", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_is_affected_by_sabo_o2", function(name, old, new)
	SetGlobalBool("ttt2_impostor_is_affected_by_sabo_o2", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_trapper_venting_time", function(name, old, new)
	SetGlobalInt("ttt2_impostor_trapper_venting_time", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_inform_trappers_about_venting", function(name, old, new)
	SetGlobalBool("ttt2_impostor_inform_trappers_about_venting", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_jesters_can_vent", function(name, old, new)
	SetGlobalBool("ttt2_impostor_jesters_can_vent", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_dopt_special_handling", function(name, old, new)
	SetGlobalBool("ttt2_impostor_dopt_special_handling", tobool(tonumber(new)))
end)
