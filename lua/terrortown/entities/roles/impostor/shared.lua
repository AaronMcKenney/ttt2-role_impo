if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_impo.vmt")
	util.AddNetworkString("TTT2ImpostorInstantKillUpdate")
	util.AddNetworkString("TTT2ImpostorSendInstantKillRequest")
	util.AddNetworkString("TTT2ImpostorEnterVentUpdate")
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
		if not IsValid(ply) or not ply:IsPlayer() or ply:GetSubRole() ~= ROLE_IMPOSTOR then
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
		end
	end)
	
	--BMF???
	--hook.Add("PlayerSwitchWeapon", "ImpostorSwitchWeapon", function(ply, oldWep, newWep)
	--	if ply:GetSubRole() ~= ROLE_IMPOSTOR or not ply:Alive() or ply.impo_in_vent == nil then
	--		return
	--	end
	--	
	--	--Prevent impostors from pulling out weapons while in vents by forcing them to be holstered.
	--	--ply:SetActiveWeapon(ply:GetWeapon("weapon_ttt_unarmed")) --BMF
	--	--newWep = ply:GetWeapon("weapon_ttt_unarmed") --BMF
	--	--return false --BMF
	--	--WHAT IS THE POINT OF THIS FUNCTION?!?!?!?!
	--end)
end

if CLIENT then
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
	
	net.Receive("TTT2ImpostorEnterVentUpdate", function()
		local client = LocalPlayer()
		local new_vent = net.ReadEntity()
		local exit_pos = net.ReadVector()
		local exit_ang = net.ReadAngle()
		
		--Have to re-add any extra bits of info here as they are not sent in ReadEntity
		new_vent.exit_pos = exit_pos
		new_vent.exit_ang = exit_ang
		
		if client.impo_in_vent == nil then
			--client is entering the vent from real space. Put them into vent space.
			IMPOSTOR_DATA.EnterVent(client, new_vent)
		else
			--client is moving from one vent to another.
			IMPOSTOR_DATA.MovePlayerToVent(client, new_vent)
		end
	end)
	
	hook.Add("TTTRenderEntityInfo", "ImpostorRenderEntityInfo", function(tData)
		local client = LocalPlayer()
		local ent = tData:GetEntity()
		
		if not IsValid(client) or not client:IsPlayer() or client:GetSubRole() ~= ROLE_IMPOSTOR or not IsValid(ent) then
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
end

----------------
--SHARED HOOKS--
----------------
hook.Add("KeyPress", "ImpostorKeyPress", function(ply, key)
	--Always use the +USE key without ability to change binding for vent logic (no reason to change it).
	if ply:GetSubRole() ~= ROLE_IMPOSTOR or not ply:Alive() or key ~= IN_USE or ply.impo_in_vent == nil then
		return
	end
	
	IMPOSTOR_DATA.ExitVent(ply)
end)
