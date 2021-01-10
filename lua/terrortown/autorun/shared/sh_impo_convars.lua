--ConVar syncing
CreateConVar("ttt2_impostor_inform_everyone", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_normal_dmg_multi", "0.0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_kill_dist", "125", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_kill_cooldown", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_cooldown", "180", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_fade_time", "2.0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_sabo_lights_length", "5.0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_num_starting_vents", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_global_max_num_vents", "9", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_vent_placement_range", "100", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_traitor_team_can_use_vents", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

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
	--  ttt2_impostor_normal_dmg_multi [0.0..n.m] (default: 0.0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_normal_dmg_multi",
		slider = true,
		min = 0.0,
		max = 1.0,
		decimal = 2,
		desc = "ttt2_impostor_normal_dmg_multi (Def: 0.0)"
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
	
	--# What is the cooldown (in seconds) on the impostor's sabotage ability?
	--  ttt2_impostor_sabo_cooldown [0..n] (default: 180)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_cooldown",
		slider = true,
		min = 0,
		max = 300,
		decimal = 0,
		desc = "ttt2_impostor_sabo_cooldown (Def: 180)"
	})
	
	--# How long (in seconds) should it take for lights to fade to black upon activating Sabotage Lights (<= 0.0 to disable ability)?
	--  Note 1: Fade time is nonlinear. HUD's color difference may be off for large fade times..
	--  ttt2_impostor_sabo_fade_time [0.0..n.m] (default: 2.0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_sabo_fade_time",
		slider = true,
		min = 0.0,
		max = 30.0,
		decimal = 2,
		desc = "ttt2_impostor_sabo_fade_time (Def: 2.0)"
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
	
	--# Should all traitor roles be able to use vents that the Impostor(s) have placed?
	--  ttt2_impostor_traitor_team_can_use_vents [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_traitor_team_can_use_vents",
		checkbox = true,
		desc = "ttt2_impostor_traitor_team_can_use_vents (Def: 1)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddImpostorGlobals", function()
	SetGlobalBool("ttt2_impostor_inform_everyone", GetConVar("ttt2_impostor_inform_everyone"):GetBool())
	SetGlobalFloat("ttt2_impostor_normal_dmg_multi", GetConVar("ttt2_impostor_normal_dmg_multi"):GetFloat())
	SetGlobalInt("ttt2_impostor_kill_dist", GetConVar("ttt2_impostor_kill_dist"):GetInt())
	SetGlobalInt("ttt2_impostor_kill_cooldown", GetConVar("ttt2_impostor_kill_cooldown"):GetInt())
	SetGlobalInt("ttt2_impostor_sabo_cooldown", GetConVar("ttt2_impostor_sabo_cooldown"):GetInt())
	SetGlobalFloat("ttt2_impostor_sabo_fade_time", GetConVar("ttt2_impostor_sabo_fade_time"):GetFloat())
	SetGlobalFloat("ttt2_impostor_sabo_lights_length", GetConVar("ttt2_impostor_sabo_lights_length"):GetFloat())
	SetGlobalInt("ttt2_impostor_num_starting_vents", GetConVar("ttt2_impostor_num_starting_vents"):GetInt())
	SetGlobalInt("ttt2_impostor_global_max_num_vents", GetConVar("ttt2_impostor_global_max_num_vents"):GetInt())
	SetGlobalInt("ttt2_impostor_vent_placement_range", GetConVar("ttt2_impostor_vent_placement_range"):GetInt())
	SetGlobalBool("ttt2_impostor_traitor_team_can_use_vents", GetConVar("ttt2_impostor_traitor_team_can_use_vents"):GetBool())
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
cvars.AddChangeCallback("ttt2_impostor_sabo_cooldown", function(name, old, new)
	SetGlobalInt("ttt2_impostor_sabo_cooldown", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_fade_time", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_sabo_fade_time", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_impostor_sabo_lights_length", function(name, old, new)
	SetGlobalFloat("ttt2_impostor_sabo_lights_length", tonumber(new))
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
cvars.AddChangeCallback("ttt2_impostor_traitor_team_can_use_vents", function(name, old, new)
	SetGlobalBool("ttt2_impostor_traitor_team_can_use_vents", tobool(tonumber(new)))
end)
