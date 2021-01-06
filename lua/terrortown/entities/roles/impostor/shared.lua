if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_impo.vmt")
	util.AddNetworkString("TTT2ImpostorInstantKillUpdate")
	util.AddNetworkString("TTT2ImpostorSendInstantKillRequest")
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

---------------------------
--SHARED CONSTS AND FUNCS--
---------------------------
local function CanKillTarget(impo, tgt, dist)
	--impo is assumed to be a valid impostor and tgt is assumed to be a valid player
	if impo.impo_can_insta_kill and dist <= GetConVar("ttt2_impostor_kill_dist"):GetInt() and impo.impo_in_vent == nil then
		return true
	else
		return false
	end
end

if SERVER then
	local function SendInstantKillUpdateToClient(ply)
		net.Start("TTT2ImpostorInstantKillUpdate")
		net.WriteBool(ply.impo_can_insta_kill)
		net.Send(ply)
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
		
		--Create a timer that is unique to the player. When it finishes, turn on ability to kill
		--Because it's unique, it can be paused/unpaused whenever the impostor enters/leaves a vent.
		--First remove any existing timer of the same name (to prevent wonkiness)
		if timer.Exists("ImposterKillTimer_Server_" .. ply:SteamID64()) then
			timer.Remove("ImposterKillTimer_Server_" .. ply:SteamID64())
		end
		timer.Create("ImposterKillTimer_Server_" .. ply:SteamID64(), kill_cooldown, 1, function()
			ply.impo_can_insta_kill = true
			SendInstantKillUpdateToClient(ply)
		end)
	end
	
	net.Receive("TTT2ImpostorSendInstantKillRequest", function(len, ply)
		if not IsValid(ply) or not ply:IsPlayer() or not ply:IsActive() or ply:GetSubRole() ~= ROLE_IMPOSTOR then
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
		
		client.selected_vent = nil
	end
	hook.Add("TTTPrepareRound", "ImpostorPrepareRoundClient", ResetImpostorForClient)
	hook.Add("TTTEndRound", "ImpostorEndRoundClient", ResetImpostorForClient)
	
	net.Receive("TTT2ImpostorInstantKillUpdate", function()
		local client = LocalPlayer()
		local kill_cooldown = GetConVar("ttt2_impostor_kill_cooldown"):GetInt()
		
		client.impo_can_insta_kill = net.ReadBool()
		
		if not client.impo_can_insta_kill then
			--Create a timer which hopefully will match the server's timer.
			--This is used in the HUD to keep the client up to date in real time on when they can next kill
			timer.Create("ImposterKillTimer_Client_" .. client:SteamID64(), kill_cooldown, 1, function()
				return
			end)
		elseif timer.Exists("ImposterKillTimer_Client_" .. client:SteamID64()) then
			--Remove the previously created timer if it still exists.
			--Hopefully this will prevent cases where multiple timers run around.
			timer.Remove("ImposterKillTimer_Client_" .. client:SteamID64())
		end
	end)
	
	hook.Add("TTTRenderEntityInfo", "ImpostorRenderEntityInfo", function(tData)
		local client = LocalPlayer()
		local ent = tData:GetEntity()
		
		if not IsValid(client) or not client:IsPlayer() or not client:Alive() or not client:IsActive() or client:GetSubRole() ~= ROLE_IMPOSTOR or not IsValid(ent) then
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
	bind.Register("ImpostorSendInstantKillRequest", SendInstantKillRequest, nil, "Impostor", "Instant Kill", KEY_Q)
	
	hook.Add("KeyPress", "ImpostorKeyPress", function(ply, key)
		--Note: Technically KeyPress is called on both the server and client.
		--However, what we do with KeyPress depends on the client's aim, so it is easier to have this
		--hook be client-only, which will then call on the server to replicate the functionality.
		local client = LocalPlayer()
		if ply:SteamID64() == client:SteamID64() and client:GetSubRole() == ROLE_IMPOSTOR and client:Alive() and client:IsActive() and key == IN_USE and client.impo_in_vent ~= nil then
			local ent_idx = -1
			if IsValid(client.selected_vent) then
				ent_idx = client.selected_vent:EntIndex()
			end
			
			--Use timer to prevent cases where key presses are registered multiple times on accident
			--Not quite sure if this is a bug in GMod, my testing server, or my keyboard...
			local cur_time = CurTime()
			if client.impo_last_switch_time == nil or cur_time > client.impo_last_switch_time + 0.2 then
				IMPOSTOR_DATA.SwitchVents(client, ent_idx)
				client.impo_last_switch_time = cur_time
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
		
		if client:GetSubRole() ~= ROLE_IMPOSTOR or not client:Alive() or not client:IsActive() or not IsValid(client.impo_in_vent) then
			return
		end
		
		--If the player was selecting a valid vent on the previous frame then see if they still are
		local selected_vent_idx = -1
		if IsValid(client.selected_vent) then
			selected_vent_idx = client.selected_vent:EntIndex()
			if not IsSelectingVent(client, client.selected_vent, true) then
				client.selected_vent = nil
				selected_vent_idx = -1
			end
		end
		
		--See if we are currently selecting any vents
		if not IsValid(client.selected_vent) then
			for _, vent in ipairs(IMPOSTOR_DATA.VENT_NETWORK) do
				--Make sure not to run IsSelectingVent on selected_vent_idx (which we already checked above)
				if IsValid(vent) and vent:EntIndex() ~= selected_vent_idx and IsSelectingVent(client, vent, false) then
					client.selected_vent = vent
					selected_vent_idx = client.selected_vent.EntIndex()
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
				
				draw.FilteredTexture(vent_scr_pos.x - VENT_BUTTON_MIDPOINT, vent_scr_pos.y - VENT_BUTTON_MIDPOINT, VENT_BUTTON_SIZE, VENT_BUTTON_SIZE, ICON_IN_VENT, 200, IMPOSTOR.color)
			end
		end
		if IsValid(client.selected_vent) and client.selected_vent:EntIndex() ~= client.impo_in_vent:EntIndex() then
			local vent_pos = client.selected_vent:GetPos()
			local vent_scr_pos = vent_pos:ToScreen()
			
			draw.FilteredTexture(vent_scr_pos.x - VENT_SELECTED_BUTTON_MIDPOINT, vent_scr_pos.y - VENT_SELECTED_BUTTON_MIDPOINT, VENT_SELECTED_BUTTON_SIZE, VENT_SELECTED_BUTTON_SIZE, ICON_IN_VENT, 200, IMPOSTOR.color)
		end
	end)
end
