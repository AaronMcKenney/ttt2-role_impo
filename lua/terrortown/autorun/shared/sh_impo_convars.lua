--ConVar syncing
CreateConVar("ttt2_impostor_notify_everyone", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_normal_dmg_multi", "0.0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_kill_dist", "125", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_kill_cooldown", "30", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_num_starting_vents", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_global_max_num_vents", "6", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_impostor_traitors_can_enter_vents", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicImpostorCVars", function(tbl)
	tbl[ROLE_IMPOSTOR] = tbl[ROLE_IMPOSTOR] or {}
	
	--# At the beginning of the round, should everyone be told how many impostors are among us?
	--  ttt2_impostor_notify_everyone [0/1] (default: 1)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_notify_everyone",
		checkbox = true,
		desc = "ttt2_impostor_notify_everyone (Def: 1)"
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
	
	--# What is the cooldown on the impostor's instant-kill ability?
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
	
	--# Can any traitor (ex. base traitor, vampire, etc.) access impostor-placed vents?
	--  ttt2_impostor_traitors_can_enter_vents [0/1] (default: 0)
	table.insert(tbl[ROLE_IMPOSTOR], {
		cvar = "ttt2_impostor_traitors_can_enter_vents",
		checkbox = true,
		desc = "ttt2_impostor_traitors_can_enter_vents (Def: 0)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddImpostorGlobals", function()
	SetGlobalBool("ttt2_impostor_notify_everyone", GetConVar("ttt2_impostor_notify_everyone"):GetBool())
	SetGlobalFloat("ttt2_impostor_normal_dmg_multi", GetConVar("ttt2_impostor_normal_dmg_multi"):GetFloat())
	SetGlobalInt("ttt2_impostor_kill_dist", GetConVar("ttt2_impostor_kill_dist"):GetInt())
	SetGlobalInt("ttt2_impostor_kill_cooldown", GetConVar("ttt2_impostor_kill_cooldown"):GetInt())
	SetGlobalInt("ttt2_impostor_num_starting_vents", GetConVar("ttt2_impostor_num_starting_vents"):GetInt())
	SetGlobalBool("ttt2_impostor_traitors_can_enter_vents", GetConVar("ttt2_impostor_traitors_can_enter_vents"):GetBool())
end)

cvars.AddChangeCallback("ttt2_impostor_notify_everyone", function(name, old, new)
	SetGlobalBool("ttt2_impostor_notify_everyone", tobool(tonumber(new)))
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
cvars.AddChangeCallback("ttt2_impostor_traitors_can_enter_vents", function(name, old, new)
	SetGlobalBool("ttt2_impostor_traitors_can_enter_vents", tobool(tonumber(new)))
end)
