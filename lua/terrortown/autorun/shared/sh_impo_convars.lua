--ConVar syncing
--General
CreateConVar("ttt2_impostor_inform_everyone", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_normal_dmg_multi", "0.5", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Instant Kill
CreateConVar("ttt2_impostor_kill_dist", "125", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_kill_cooldown", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Venting (General)
CreateConVar("ttt2_impostor_num_starting_vents", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_global_max_num_vents", "9", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_vent_placement_range", "100", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_hide_unused_vents", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_vent_secondary_fire_mode", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_traitor_team_can_use_vents", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
--Venting (Special Role Handling)
CreateConVar("ttt2_impostor_trapper_venting_time", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_inform_about_trappers_venting", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_inform_trappers_about_venting", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_jesters_can_vent", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
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
	
	--# Should traitors be informed when a trapper enters and exits a vent?
	--  ttt2_impostor_inform_about_trappers_venting [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_inform_about_trappers_venting",
		checkbox = true,
		desc = "ttt2_impostor_inform_about_trappers_venting (Def: 1)"
	})
	
	--# Should trappers be informed when anyone enters and exits a vent?
	--  ttt2_impostor_inform_trappers_about_venting [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_inform_trappers_about_venting",
		checkbox = true,
		desc = "ttt2_impostor_inform_trappers_about_venting (Def: 0)"
	})
	
	--# Should trappers be informed when anyone enters and exits a vent?
	--  ttt2_impostor_jesters_can_vent [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_jesters_can_vent",
		checkbox = true,
		desc = "ttt2_impostor_jesters_can_vent (Def: 1)"
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
	
	--# How long (in seconds) should it take for lights to fade to black upon activating Sabotage Lights (<= 0.0 to disable ability)?
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
		max = 30.0,
		decimal = 2,
		desc = "ttt2_impostor_sabo_lights_length (Def: 5.0)"
	})
	
	--# Should all traitor roles be affected by an Impostor's Sabotage Lights?
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
	
	--# During Sabotage Comms, should players not on the traitor team be deafened in addition to having chat disabled?
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
		max = 30,
		decimal = 0,
		desc = "ttt2_impostor_sabo_comms_length (Def: 20)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddImpostorGlobals", function()
	SetGlobalBool("ttt2_impostor_inform_everyone", GetConVar("ttt2_impostor_inform_everyone"):GetBool())
	SetGlobalFloat("ttt2_impostor_normal_dmg_multi", GetConVar("ttt2_impostor_normal_dmg_multi"):GetFloat())
	SetGlobalInt("ttt2_impostor_kill_dist", GetConVar("ttt2_impostor_kill_dist"):GetInt())
	SetGlobalInt("ttt2_impostor_kill_cooldown", GetConVar("ttt2_impostor_kill_cooldown"):GetInt())
	SetGlobalInt("ttt2_impostor_num_starting_vents", GetConVar("ttt2_impostor_num_starting_vents"):GetInt())
	SetGlobalInt("ttt2_impostor_global_max_num_vents", GetConVar("ttt2_impostor_global_max_num_vents"):GetInt())
	SetGlobalInt("ttt2_impostor_vent_placement_range", GetConVar("ttt2_impostor_vent_placement_range"):GetInt())
	SetGlobalBool("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit", GetConVar("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit"):GetBool())
	SetGlobalBool("ttt2_impostor_hide_unused_vents", GetConVar("ttt2_impostor_hide_unused_vents"):GetBool())
	SetGlobalInt("ttt2_impostor_vent_secondary_fire_mode", GetConVar("ttt2_impostor_vent_secondary_fire_mode"):GetInt())
	SetGlobalBool("ttt2_impostor_traitor_team_can_use_vents", GetConVar("ttt2_impostor_traitor_team_can_use_vents"):GetBool())
	SetGlobalInt("ttt2_impostor_trapper_venting_time", GetConVar("ttt2_impostor_trapper_venting_time"):GetInt())
	SetGlobalBool("ttt2_impostor_inform_about_trappers_venting", GetConVar("ttt2_impostor_inform_about_trappers_venting"):GetBool())
	SetGlobalBool("ttt2_impostor_inform_trappers_about_venting", GetConVar("ttt2_impostor_inform_trappers_about_venting"):GetBool())
	SetGlobalBool("ttt2_impostor_jesters_can_vent", GetConVar("ttt2_impostor_jesters_can_vent"):GetBool())
	SetGlobalInt("ttt2_impostor_sabo_lights_cooldown", GetConVar("ttt2_impostor_sabo_lights_cooldown"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_lights_mode", GetConVar("ttt2_impostor_sabo_lights_mode"):GetInt())
	SetGlobalFloat("ttt2_impostor_sabo_lights_fade", GetConVar("ttt2_impostor_sabo_lights_fade"):GetFloat())
	SetGlobalFloat("ttt2_impostor_sabo_lights_length", GetConVar("ttt2_impostor_sabo_lights_length"):GetFloat())
	SetGlobalBool("ttt2_impostor_traitor_team_is_affected_by_sabo_lights", GetConVar("ttt2_impostor_traitor_team_is_affected_by_sabo_lights"):GetBool())
	SetGlobalInt("ttt2_impostor_sabo_comms_cooldown", GetConVar("ttt2_impostor_sabo_comms_cooldown"):GetInt())
	SetGlobalBool("ttt2_impostor_sabo_comms_deafen", GetConVar("ttt2_impostor_sabo_comms_deafen"):GetBool())
	SetGlobalInt("ttt2_impostor_sabo_comms_length", GetConVar("ttt2_impostor_sabo_comms_length"):GetInt())
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
	SetGlobalFloat("ttt2_impostor_vent_secondary_fire_mode", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_traitor_team_can_use_vents", function(name, old, new)
	SetGlobalBool("ttt2_impostor_traitor_team_can_use_vents", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_trapper_venting_time", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_trapper_venting_time", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_inform_about_trappers_venting", function(name, old, new)
	SetGlobalBool("ttt2_impostor_inform_about_trappers_venting", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_inform_trappers_about_venting", function(name, old, new)
	SetGlobalBool("ttt2_impostor_inform_trappers_about_venting", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_jesters_can_vent", function(name, old, new)
	SetGlobalBool("ttt2_impostor_jesters_can_vent", tobool(tonumber(new)))
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
	SetGlobalFloat("ttt2_impostor_sabo_comms_cooldown", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_comms_deafen", function(name, old, new)
	SetGlobalBool("ttt2_impostor_sabo_comms_deafen", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_comms_length", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_sabo_comms_length", tonumber(new))
end)
