if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_impo.vmt")
	util.AddNetworkString("TTT2ImpostorInformEveryone")
	util.AddNetworkString("TTT2ImpostorInstantKillUpdate")
	util.AddNetworkString("TTT2ImpostorSabotageUpdate")
	util.AddNetworkString("TTT2ImpostorSendInstantKillRequest")
	util.AddNetworkString("TTT2ImpostorSendSabotageLightsRequest")
	util.AddNetworkString("TTT2ImpostorSendSabotageLightsResponse")
	util.AddNetworkString("TTT2ImpostorSabotageLights")
end

function ROLE:PreInitialize()
	--Color of a Red Impostor
	self.color = Color(197, 17, 17, 255)
	self.abbr = "impo" -- abbreviation
	
	--Score vars
	self.surviveBonus = 0.5 -- bonus multiplier for every survive while another player was killed
	self.scoreKillsMultiplier = 5 -- multiplier for kill of player of another team
	self.scoreTeamKillsMultiplier = -16 -- multiplier for teamkill
	
	--Prevent the Impostor from gaining credits normally.
	self.preventFindCredits = true
	self.preventKillCredits = true
	self.preventTraitorAloneCredits = true
	
	self.defaultEquipment = SPECIAL_EQUIPMENT -- here you can set up your own default equipment
	self.defaultTeam = TEAM_TRAITOR
	
	self.conVarData = {
		pct = 0.17, -- necessary: percentage of getting this role selected (per player)
		maximum = 1, -- maximum amount of roles in a round
		minPlayers = 6, -- minimum amount of players until this role is able to get selected
		togglable = true, -- option to toggle a role for a client if possible (F1 menu)
		random = 30,
		traitorButton = 1, -- can use traitor buttons
		
		--Impostor can't access shop, and has no credits.
		credits = 0,
		creditsTraitorKill = 0,
		creditsTraitorDead = 0,
		shopFallback = SHOP_DISABLED
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_TRAITOR)
end

--------------------------------------------
--SHARED CONSTS, GLOBALS, FUNCS, AND HOOKS--
--------------------------------------------
--Used to reduce chances of lag interrupting otherwise seemless player interactions.
local IOTA = 0.3
--Sabotage cooldown is global. If a terrorist triggers a sabotage, all must wait.
impos_can_sabo = true

local function CanKillTarget(impo, tgt, dist)
	--impo is assumed to be a valid impostor and tgt is assumed to be a valid player
	if impo.impo_can_insta_kill and dist <= GetConVar("ttt2_impostor_kill_dist"):GetInt() and impo.impo_in_vent == nil then
		return true
	else
		return false
	end
end

local function SabotageLights(ply)
	--Sabotage ply's lights by performing screen fades.
	local fade_time = GetConVar("ttt2_impostor_sabo_fade_time"):GetFloat()
	local fade_hold = GetConVar("ttt2_impostor_sabo_lights_length"):GetFloat() / 2
	
	--Sabotage Lights is disabled if ttt2_impostor_sabo_lights_length < 0
	if fade_hold >= 0 then
		--SCREENFADE.IN: Cut to black immediately. After fade_hold, transition out over fade_time.
		--SCREENFADE.OUT: Fade to black over fade_time. After fade_hold, cut back to normal immediately.
		--SCREENFADE.MODULATE: Cut to black immediately. Cut back to normal some time after. Not sure how fade_time factors in here.
		--SCREENFADE.STAYOUT: Cut to black immediately. Never returns to normal. Why is this a thing?
		--SCREENFADE.PURGE: Not sure how this differs from SCREENFADE.MODULATE.
		
		--Create temporary lights-out effect: fade to black, hold, then fade to normal.
		--Add IOTA in first ScreenFade call to handle lag between the two calls and create a hopefully seemless blackout effect.
		ply:ScreenFade(SCREENFADE.OUT, COLOR_BLACK, fade_time, fade_hold + IOTA)
		timer.Simple(fade_time + fade_hold, function()
			--Have to create a lambda function() here. ply:ScreenFade by itself doesn't pass compile.
			ply:ScreenFade(SCREENFADE.IN, COLOR_BLACK, fade_time, fade_hold)
		end)
	end
	
	if SERVER then
		--Send request to client to call this same function, just to keep things in sync.
		net.Start("TTT2ImpostorSabotageLights")
		net.Send(ply)
	end
end

if SERVER then
	local function SendInstantKillUpdateToClient(ply)
		net.Start("TTT2ImpostorInstantKillUpdate")
		net.WriteBool(ply.impo_can_insta_kill)
		net.Send(ply)
	end
	
	local function SendSabotageUpdateToClients()
		net.Start("TTT2ImpostorSabotageUpdate")
		net.WriteBool(impos_can_sabo)
		net.Broadcast()
	end
	
	local function PutInstantKillOnCooldown(ply)
		local kill_cooldown = GetConVar("ttt2_impostor_kill_cooldown"):GetInt()
		
		--Handle case where admin wants impostor to be overpowered trash.
		if kill_cooldown <= 0 then
			ply.impo_can_insta_kill = true
			SendInstantKillUpdateToClient(ply)
			return
		end
		
		--Turn off ability to kill
		ply.impo_can_insta_kill = false
		SendInstantKillUpdateToClient(ply)
		
		--Create a timer that is unique to the player. When it finishes, turn on ability to kill.
		timer.Create("ImpostorKillTimer_Server_" .. ply:SteamID64(), kill_cooldown, 1, function()
			--Verify the player's existence, in case they are dropped from the Server.
			if IsValid(ply) and ply:IsPlayer() then
				ply.impo_can_insta_kill = true
				SendInstantKillUpdateToClient(ply)
			end
		end)
	end
	
	local function PutSabotageOnCooldown()
		local sabo_cooldown = GetConVar("ttt2_impostor_sabo_cooldown"):GetInt()
		
		--Handle case where admin wants impostor to be overpowered trash.
		if sabo_cooldown <= 0 then
			impos_can_sabo = true
			SendSabotageUpdateToClients()
			return
		end
		
		--Turn off ability to sabotage lights
		impos_can_sabo = false
		SendSabotageUpdateToClients()
		
		--Create a timer that is unique to the player. When it finishes, turn on ability to sabotage lights.
		timer.Create("ImpostorSaboTimer_Server", sabo_cooldown, 1, function()
			impos_can_sabo = true
			SendSabotageUpdateToClients()
		end)
	end
	
	net.Receive("TTT2ImpostorSendInstantKillRequest", function(len, ply)
		if not IsValid(ply) or not ply:IsPlayer() or not ply:IsTerror() or ply:GetSubRole() ~= ROLE_IMPOSTOR then
			return
		end
		
		--Determine if the impostor is looking at someone who isn't on their team
		local trace = ply:GetEyeTrace(MASK_SHOT_HULL)
		local dist = trace.StartPos:Distance(trace.HitPos)
		local tgt = trace.Entity
		if not IsValid(tgt) or not tgt:IsPlayer() then
			return
		end
		
		--If the impostor is able to, instantly kill the target and reset the cooldown.
		if CanKillTarget(ply, tgt, dist) then
			tgt:Kill()
			PutInstantKillOnCooldown(ply)
		end
	end)
	
	net.Receive("TTT2ImpostorSendSabotageLightsRequest", function(len, ply)
		local fade_time = GetConVar("ttt2_impostor_sabo_fade_time"):GetFloat()
		local sabo_lights_len = GetConVar("ttt2_impostor_sabo_lights_length"):GetFloat()
		if not IsValid(ply) or not ply:IsPlayer() or not ply:IsTerror() or ply:GetSubRole() ~= ROLE_IMPOSTOR or fade_time <= 0.0 or sabo_lights_len < 0.0 then
			return
		end
		
		if impos_can_sabo then
			--Prevent button spamming tricks by immediately disabling sabo.
			impos_can_sabo = false
			
			for _, ply_i in ipairs(player.GetAll()) do
				--Inform everyone that the sabotage is starting.
				net.Start("TTT2ImpostorSendSabotageLightsResponse")
				net.Send(ply_i)
				
				if ply_i:GetSubRole() ~= ROLE_IMPOSTOR and (GetConVar("ttt2_impostor_traitor_team_is_affected_by_sabo"):GetBool() or ply_i:GetTeam() ~= TEAM_TRAITOR) then
					SabotageLights(ply_i)
				end
			end
			
			--Only begin cooldown timer after fade effect ends.
			timer.Simple(sabo_lights_len + 2*fade_time, function()
				PutSabotageOnCooldown()
			end)
		end
	end)
	
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		ply:GiveEquipmentWeapon('weapon_ttt_vent')
		PutInstantKillOnCooldown(ply)
	end
	
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		ply:StripWeapon('weapon_ttt_vent')
	end
	
	hook.Add("EntityTakeDamage", "ImpostorModifyDamage", function(target, dmg_info)
		local attacker = dmg_info:GetAttacker()
		
		if IsValid(attacker) and attacker:IsPlayer() and attacker:GetSubRole() == ROLE_IMPOSTOR then
			if attacker.impo_in_vent then
				--Force Impostor to deal no damage if they are in a vent (just to be safe)
				dmg_info:SetDamage(0)
			else
				dmg_info:SetDamage(dmg_info:GetDamage() * GetConVar("ttt2_impostor_normal_dmg_multi"):GetFloat())
			end
		elseif IsValid(victim) and victim:IsPlayer() and victim:GetSubRole() == ROLE_IMPOSTOR and victim.impo_in_vent then
			--Force Impostor to take no damage if they are in a vent (just to be safe)
			dmg_info:SetDamage(0)
		end
	end)
	
	hook.Add("TTTBeginRound", "ImpostorBeginRound", function()
		impos_can_sabo = true
		SendSabotageUpdateToClients()
		
		if GetConVar("ttt2_impostor_inform_everyone"):GetBool() then
			local num_impos = 0
			
			for _, ply in ipairs(player.GetAll()) do
				if ply:GetSubRole() == ROLE_IMPOSTOR then
					num_impos = num_impos + 1
				end
			end
			
			if num_impos > 0 then
				net.Start("TTT2ImpostorInformEveryone")
				net.WriteInt(num_impos, 16)
				net.Broadcast()
			end
		end
		
		--Reset timer for everyone in case someone becomes a trapper.
		for _, ply in ipairs(player.GetAll()) do
			ply.impo_trapper_timer_expired = nil
		end
	end)
end

if CLIENT then
	--Client consts
	local VENT_BUTTON_SIZE = 64
	local VENT_BUTTON_MIDPOINT = VENT_BUTTON_SIZE / 2
	local VENT_SELECTED_BUTTON_SIZE = 80
	local VENT_SELECTED_BUTTON_MIDPOINT = VENT_SELECTED_BUTTON_SIZE / 2
	local ICON_IN_VENT = Material("vgui/ttt/icon_vent")
	
	local function ResetImpostorForClient()
		local client = LocalPlayer()
		
		client.impo_selected_vent = nil
		client.impo_last_switch_time = nil
		client.impo_trapper_timer_expired = nil
	end
	hook.Add("TTTPrepareRound", "ImpostorPrepareRoundClient", ResetImpostorForClient)
	hook.Add("TTTBeginRound", "ImpostorBeginRoundClient", ResetImpostorForClient)
	
	net.Receive("TTT2ImpostorInformEveryone", function()
		local client = LocalPlayer()
		local num_impos = net.ReadInt(16)
		
		EPOP:AddMessage({text = LANG.GetParamTranslation("INFORM_" .. IMPOSTOR.name, {n = num_impos}), color = IMPOSTOR.color}, "", 6)
	end)
	
	net.Receive("TTT2ImpostorInstantKillUpdate", function()
		local client = LocalPlayer()
		local kill_cooldown = GetConVar("ttt2_impostor_kill_cooldown"):GetInt()
		
		client.impo_can_insta_kill = net.ReadBool()
		
		if not client.impo_can_insta_kill then
			--Create a timer which hopefully will match the server's timer.
			--This is used in the HUD to keep the client up to date in real time on when they can next kill
			timer.Create("ImpostorKillTimer_Client_" .. client:SteamID64(), kill_cooldown, 1, function()
				return
			end)
		elseif timer.Exists("ImpostorKillTimer_Client_" .. client:SteamID64()) then
			--Remove the previously created timer if it still exists.
			--Hopefully this will prevent cases where multiple timers run around.
			timer.Remove("ImpostorKillTimer_Client_" .. client:SteamID64())
		end
	end)
	
	net.Receive("TTT2ImpostorSabotageUpdate", function()
		local sabo_cooldown = GetConVar("ttt2_impostor_sabo_cooldown"):GetInt()
		
		impos_can_sabo = net.ReadBool()
		
		if not impos_can_sabo then
			--Create a timer which hopefully will match the server's timer.
			--This is used in the HUD to keep the client up to date in real time on when they can next sabotage
			timer.Create("ImpostorSaboTimer_Client", sabo_cooldown, 1, function()
				return
			end)
		elseif timer.Exists("ImpostorSaboTimer_Client") then
			--Remove the previously created timer if it still exists.
			--Hopefully this will prevent cases where multiple timers run around.
			timer.Remove("ImpostorSaboTimer_Client")
		end
	end)
	
	net.Receive("TTT2ImpostorSendSabotageLightsResponse", function()
		--Inform the clients that the lights will be sabotaged.
		local client = LocalPlayer()
		local fade_time = GetConVar("ttt2_impostor_sabo_fade_time"):GetFloat()
		local sabo_lights_len = GetConVar("ttt2_impostor_sabo_lights_length"):GetFloat()
		
		LANG.Msg("SABO_LIGHTS_START_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
		
		--Immediately set impos_can_sabo to false here, to keep things in sync.
		impos_can_sabo = false
		
		--Create a timer which hopefully will match the server's timer.
		--This is used in the HUD to allow impostors to track the darkness other clients are experiencing.
		timer.Create("ImpostorSaboLightsTimer_Client", sabo_lights_len + 2*fade_time, 1, function()
			LANG.Msg("SABO_LIGHTS_END_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
			return
		end)
	end)
	
	net.Receive("TTT2ImpostorSabotageLights", function()
		local client = LocalPlayer()
		SabotageLights(client)
	end)
	
	hook.Add("TTTRenderEntityInfo", "ImpostorRenderEntityInfo", function(tData)
		local client = LocalPlayer()
		local ent = tData:GetEntity()
		
		if not IsValid(client) or not client:IsPlayer() or not client:Alive() or not client:IsTerror() or client:GetSubRole() ~= ROLE_IMPOSTOR or not IsValid(ent) then
			return
		end
		
		--If the player can kill the player they're looking at, inform them by putting a notification
		--on the body. Also tell them which key they need to press.
		if ent:IsPlayer() and CanKillTarget(client, ent, tData:GetEntityDistance()) then
			local kill_key = string.upper(input.GetKeyName(bind.Find("ImpostorSendInstantKillRequest")))
			
			if tData:GetAmountDescriptionLines() > 0 then
				tData:AddDescriptionLine()
			end
			
			tData:AddDescriptionLine(LANG.GetTranslation("PRESS_" .. IMPOSTOR.name) .. kill_key .. LANG.GetTranslation("TO_KILL_" .. IMPOSTOR.name), IMPOSTOR.color)
		end
	end)
	
	local function SendInstantKillRequest()
		net.Start("TTT2ImpostorSendInstantKillRequest")
		net.SendToServer()
	end
	bind.Register("ImpostorSendInstantKillRequest", SendInstantKillRequest, nil, "Impostor", "Instant Kill", KEY_C)
	
	local function SendSabotageLightsRequest()
		net.Start("TTT2ImpostorSendSabotageLightsRequest")
		net.SendToServer()
	end
	bind.Register("ImpostorSendSabotageLightsRequest", SendSabotageLightsRequest, nil, "Impostor", "Sabotage Lights", KEY_V)
	
	hook.Add("KeyPress", "ImpostorKeyPressForClient", function(ply, key)
		--Note: Technically KeyPress is called on both the server and client.
		--However, what we do with KeyPress depends on the client's aim, so it is easier to have this
		--hook be client-only, which will then call on the server to replicate the functionality.
		local client = LocalPlayer()
		if ply:SteamID64() == client:SteamID64() and client:Alive() and client:IsTerror() and key == IN_USE and IsValid(client.impo_in_vent) then
			local ent_idx = -1
			if IsValid(client.impo_selected_vent) and client.impo_selected_vent:EntIndex() ~= client.impo_in_vent:EntIndex() then
				--Selected vent must be valid and different from the one we're currently in.
				ent_idx = client.impo_selected_vent:EntIndex()
			end
			
			--Use timer to prevent cases where key presses are registered multiple times on accident
			--Not quite sure if this is a bug in GMod, my testing server, or my keyboard...
			local cur_time = CurTime()
			if client.impo_last_move_time == nil or cur_time > client.impo_last_move_time + IOTA then
				IMPOSTOR_DATA.MovePlayerFromVentTo(client, ent_idx)
				client.impo_last_move_time = cur_time
			end
		end
	end)
	
	local function IsSelectingVent(ply, vent, previously_selected)
		local midscreen_x = ScrW() / 2
		local midscreen_y = ScrH() / 2
		local vent_pos = vent:GetPos()
		local vent_scr_pos = vent_pos:ToScreen()
		
		if util.IsOffScreen(vent_scr_pos) then
			return false
		end
		
		local dist_from_mid_x = math.abs(vent_scr_pos.x - midscreen_x)
		local dist_from_mid_y = math.abs(vent_scr_pos.y - midscreen_y)
		local vent_button_dist_check = VENT_BUTTON_MIDPOINT
		if previously_selected then
			vent_button_dist_check = VENT_SELECTED_BUTTON_MIDPOINT
		end
		
		if dist_from_mid_x > vent_button_dist_check or dist_from_mid_y > vent_button_dist_check then
			return false
		end
		
		return true
	end
	
	hook.Add("HUDPaint", "ImpostorHUDPaint", function()
		local client = LocalPlayer()
		
		if not client:Alive() or not client:IsTerror() or not IsValid(client.impo_in_vent) then
			return
		end
		
		--If the player was selecting a valid vent on the previous frame then see if they still are
		local selected_vent_idx = -1
		if IsValid(client.impo_selected_vent) then
			selected_vent_idx = client.impo_selected_vent:EntIndex()
			if not IsSelectingVent(client, client.impo_selected_vent, true) then
				client.impo_selected_vent = nil
				selected_vent_idx = -1
			end
		end
		
		--See if we are currently selecting any vents
		if not IsValid(client.impo_selected_vent) then
			for _, vent in ipairs(IMPOSTOR_DATA.VENT_NETWORK) do
				--Make sure not to run IsSelectingVent on selected_vent_idx (which we already checked above)
				if IsValid(vent) and vent:EntIndex() ~= selected_vent_idx and IsSelectingVent(client, vent, false) then
					client.impo_selected_vent = vent
					selected_vent_idx = client.impo_selected_vent:EntIndex()
					break
				end
			end
		end
		
		--Finally, draw all vents, making sure to draw the selected one last (to handle overlaps).
		for _, vent in ipairs(IMPOSTOR_DATA.VENT_NETWORK) do
			if IsValid(vent) and vent:EntIndex() ~= selected_vent_idx and vent:EntIndex() ~= client.impo_in_vent:EntIndex() then
				local vent_pos = vent:GetPos()
				local vent_scr_pos = vent_pos:ToScreen()
				
				if util.IsOffScreen(vent_scr_pos) then
					continue
				end
				
				draw.FilteredTexture(vent_scr_pos.x - VENT_BUTTON_MIDPOINT, vent_scr_pos.y - VENT_BUTTON_MIDPOINT, VENT_BUTTON_SIZE, VENT_BUTTON_SIZE, ICON_IN_VENT, 200, COLOR_ORANGE)
			end
		end
		if IsValid(client.impo_selected_vent) and client.impo_selected_vent:EntIndex() ~= client.impo_in_vent:EntIndex() then
			local vent_pos = client.impo_selected_vent:GetPos()
			local vent_scr_pos = vent_pos:ToScreen()
			
			draw.FilteredTexture(vent_scr_pos.x - VENT_SELECTED_BUTTON_MIDPOINT, vent_scr_pos.y - VENT_SELECTED_BUTTON_MIDPOINT, VENT_SELECTED_BUTTON_SIZE, VENT_SELECTED_BUTTON_SIZE, ICON_IN_VENT, 200, IMPOSTOR.color)
		end
	end)
end
