if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2ImpostorEnterVentUpdate")
	util.AddNetworkString("TTT2ImpostorMoveFromVentUpdate")
	util.AddNetworkString("TTT2ImpostorForceExitFromVentUpdate")
	util.AddNetworkString("TTT2ImpostorRevealVentUpdate")
end

IMPOSTOR_DATA = {}
IMPOSTOR_DATA.VENT_NETWORK = {}

function IMPOSTOR_DATA.RemoveVentFromNetwork(vent_idx)
	for i, v in ipairs(IMPOSTOR_DATA.VENT_NETWORK) do
		if v:EntIndex() == vent_idx then
			table.remove(IMPOSTOR_DATA.VENT_NETWORK, i)
			--BMF
			if SERVER then
				print("BMF RemoveVentFromNetwork: There are now " .. #IMPOSTOR_DATA.VENT_NETWORK .. " vents on the Server.")
			elseif CLIENT then
				print("BMF RemoveVentFromNetwork: There are now " .. #IMPOSTOR_DATA.VENT_NETWORK .. " vents on the Client.")
			end
			--BMF
			break
		end
	end
end

function IMPOSTOR_DATA.ResetVentNetwork()
	IMPOSTOR_DATA.VENT_NETWORK = {}
	
	print("BMF ResetVentNetwork: Number of vents is now " .. #IMPOSTOR_DATA.VENT_NETWORK)
end
hook.Add("TTTPrepareRound", "ImpostorDataPrepareRound", IMPOSTOR_DATA.ResetVentNetwork)
hook.Add("TTTBeginRound", "ImpostorDataPrepareRound", IMPOSTOR_DATA.ResetVentNetwork)

function GetVentFromIndex(new_vent_idx)
	for _, vent in ipairs(IMPOSTOR_DATA.VENT_NETWORK) do
		if vent:EntIndex() == new_vent_idx then
			return vent
		end
	end
	
	return nil
end

local function TrapperCanVent(ply)
	local total_trapper_time_allowed = GetConVar("ttt2_impostor_trapper_venting_time"):GetInt()
	
	if ply:GetSubRole() == ROLE_TRAPPER and total_trapper_time_allowed > 0 and not ply.impo_trapper_timer_expired then
		return true
	end
	
	return false
end

local function HandleTrapperVenting(ply, is_entering_vent)
	if not TrapperCanVent(ply) then
		return
	end
	
	local inform_traitors = GetConVar("ttt2_impostor_inform_about_trappers_venting"):GetBool()
	local server_client_str = "SERVER_"
	if CLIENT then
		server_client_str = "CLIENT_"
	end
	
	if not timer.Exists("ImpostorTrapperVent_" .. server_client_str .. ply:SteamID64()) then
		local total_trapper_time_allowed = GetConVar("ttt2_impostor_trapper_venting_time"):GetInt()
		timer.Create("ImpostorTrapperVent_" .. server_client_str .. ply:SteamID64(), total_trapper_time_allowed, 1, function()
			--Verify the player's existence, in case they are dropped from the Server.
			if IsValid(ply) and ply:IsPlayer() and ply:GetSubRole() == ROLE_TRAPPER then
				ply.impo_trapper_timer_expired = true
				if IsValid(ply.impo_in_vent) then
					IMPOSTOR_DATA.ExitVent(ply)
					
					if CLIENT then
						LANG.Msg("VENT_TRAPPER_TIME_UP_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
					end
				end
			end
		end)
	end
	
	if CLIENT then
		local time_left = math.ceil(math.abs(timer.TimeLeft("ImpostorTrapperVent_" .. server_client_str .. ply:SteamID64())))
		LANG.Msg("VENT_TRAPPER_TIME_LEFT_" .. IMPOSTOR.name, {t = time_left}, MSG_MSTACK_WARN)
	end
	
	--Timer should only run while the trapper is in a vent.
	--Also inform traitors when a trapper enters/exits a vent.
	if is_entering_vent then
		timer.UnPause("ImpostorTrapperVent_" .. server_client_str .. ply:SteamID64())
		
		if SERVER and inform_traitors then
			for _, ply_i in ipairs(player.GetAll()) do
				if ply_i:GetSubRole() == ROLE_IMPOSTOR or ply_i:GetTeam() == TEAM_TRAITOR then
					LANG.Msg(ply_i, "VENT_TRAPPER_ENTER_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
				end
			end
		end
	else
		timer.Pause("ImpostorTrapperVent_" .. server_client_str .. ply:SteamID64())
		
		if SERVER and inform_traitors then
			for _, ply_i in ipairs(player.GetAll()) do
				if ply_i:GetSubRole() == ROLE_IMPOSTOR or ply_i:GetTeam() == TEAM_TRAITOR then
					LANG.Msg(ply_i, "VENT_TRAPPER_EXIT_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
				end
			end
		end
	end
end

local function InformTrappers(ply, is_entering_vent)
	if not SERVER or not GetConVar("ttt2_impostor_inform_trappers_about_venting"):GetBool() then
		return
	end
	
	if is_entering_vent then
		for _, ply_i in ipairs(player.GetAll()) do
			if ply_i:GetSubRole() == ROLE_TRAPPER and ply:SteamID64() == ply_i:SteamID64() then
				LANG.Msg(ply_i, "VENT_ANYONE_ENTER_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
			end
		end
	else
		for _, ply_i in ipairs(player.GetAll()) do
			if ply_i:GetSubRole() == ROLE_TRAPPER and ply:SteamID64() == ply_i:SteamID64() then
				LANG.Msg(ply_i, "VENT_ANYONE_EXIT_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
			end
		end
	end
end

function IMPOSTOR_DATA.CanUseVentNetwork(ply)
	if ply:IsTerror() and ply:Alive() and (ply:GetSubRole() == ROLE_IMPOSTOR or (GetConVar("ttt2_impostor_traitor_team_can_use_vents"):GetBool() and ply:GetTeam() == TEAM_TRAITOR) or TrapperCanVent(ply) or GetConVar("ttt2_impostor_jesters_can_vent"):GetBool()) then
		return true
	end
	return false
end

function IMPOSTOR_DATA.RevealVent(vent)
	if IsValid(vent) then
		print("BMF RevealVent: Revealing vent with index " .. vent:EntIndex())
		vent:SetNoDraw(false)
	end
	
	if SERVER then
		net.Start("TTT2ImpostorRevealVentUpdate")
		net.WriteInt(vent:EntIndex(), 16)
		net.Broadcast()
	end
end

function IMPOSTOR_DATA.MovePlayerToVent(ply, vent)
	--BMF
	local server_client_str = "SERVER"
	if CLIENT then
		server_client_str = "CLIENT"
	end
	local creation_id_str = "nil"
	if vent and SERVER then
		creation_id_str = vent:GetCreationID()
	end
	local ent_id_str = vent:EntIndex()
	print("BMF MovePlayerToVent " .. server_client_str .. " Creation ID = " .. creation_id_str .. ", Ent ID = " .. ent_id_str)
	--BMF
	ply:SetPos(vent:GetPos())
	ply:SetEyeAngles(vent:GetAngles())
	ply.impo_in_vent = vent
end

function IMPOSTOR_DATA.EnterVent(ply, vent)
	if IsValid(ply.impo_in_vent) or not IsValid(vent) or not IMPOSTOR_DATA.CanUseVentNetwork(ply) then
		return
	end
	
	--Effectively remove the player from existence by refusing to draw them, removing their collision box, and freezing them in place. May not be perfect!
	--Could also try spectating here, but not sure if TTT2 will handle that properly (ex. may assume the player has died and break certain mods)
	ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) --Vents really are vehicles, if you think about it.
	--Don't just make the player invisible, but their weapons as well
	ply:SetNoDraw(true)
	for _, wep in ipairs(ply:GetWeapons()) do
		wep:SetNoDraw(true)
	end
	
	--Prevent others from being able to aim at the player.
	ply:RemoveFlags(FL_AIMTARGET)
	--FL_ATCONTROLS ==> Player can move mouse but cannot move themselves.
	--FL_NOTARGET ==> Prevent AI from targeting the player.
	ply:AddFlags(bit.bor(FL_ATCONTROLS, FL_NOTARGET))
	
	IMPOSTOR_DATA.MovePlayerToVent(ply, vent)
	
	if SERVER then
		--Save the player's current weapon.
		ply.impo_in_vent_prev_wep = ply:GetActiveWeapon():GetClass()
		
		--Switch player's weapon to holstered.
		ply:SelectWeapon("weapon_ttt_unarmed")
		
		--Pause the Impostor's kill timer if possible.
		if ply.impo_can_insta_kill == false and timer.Exists("ImpostorKillTimer_Server_" .. ply:SteamID64()) then
			timer.Pause("ImpostorKillTimer_Server_" .. ply:SteamID64())
		end
		
		--In addition, sync the client by having them call this same function
		net.Start("TTT2ImpostorEnterVentUpdate")
		net.WriteInt(vent:EntIndex(), 16)
		net.Send(ply)
		
		--In addition, reveal the vent to everyone since it was entered from
		IMPOSTOR_DATA.RevealVent(vent)
		
		InformTrappers(ply, true)
	elseif CLIENT then
		--Keep track of when the Impostor last entered/switched/exited a vent to prevent accidental key presses booting them out of a vent immediately upon entering it.
		ply.impo_last_move_time = CurTime()
		
		if not ply.impo_can_insta_kill and timer.Exists("ImpostorKillTimer_Client_" .. ply:SteamID64()) then
			timer.Pause("ImpostorKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	HandleTrapperVenting(ply, true)
end

function IMPOSTOR_DATA.ExitVent(ply)
	--This is especially needed in case somehow both the vent and the player are removed and destroyed simultaneously, which would trigger this function twice.
	if not IsValid(ply) or not ply:IsPlayer() or not IsValid(ply.impo_in_vent) then
		return
	end
	
	--Correct player's position to be in a safe place
	ply:SetPos(ply.impo_in_vent.exit_pos)
	
	--Bring the player back into existence by undoing everything done in EnterVent
	ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	ply:SetNoDraw(false)
	for _, wep in ipairs(ply:GetWeapons()) do
		wep:SetNoDraw(false)
	end
	ply:AddFlags(FL_AIMTARGET)
	ply:RemoveFlags(bit.bor(FL_ATCONTROLS, FL_NOTARGET))
	
	--UnPause the Impostor's kill timer if possible.
	if SERVER then
		if ply.impo_can_insta_kill == false and timer.Exists("ImpostorKillTimer_Server_" .. ply:SteamID64()) then
			timer.UnPause("ImpostorKillTimer_Server_" .. ply:SteamID64())
		end
		
		--In addition, reveal the vent if it has been exited from for the first time.
		IMPOSTOR_DATA.RevealVent(ply.impo_in_vent)
		
		InformTrappers(ply, false)
	elseif CLIENT then
		if not ply.impo_can_insta_kill and timer.Exists("ImpostorKillTimer_Client_" .. ply:SteamID64()) then
			timer.UnPause("ImpostorKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	HandleTrapperVenting(ply, false)
	
	ply.impo_in_vent = nil
	
	if SERVER then
		--Make the player switch back to their previous weapon if possible.
		--This is called after impo_in_vent is set to nil to prevent situation where they are auto-switched back to holstered.
		if ply.impo_in_vent_prev_wep ~= nil then
			ply:SelectWeapon(ply.impo_in_vent_prev_wep)
			ply.impo_in_vent_prev_wep = nil
		end
	end
end

function IMPOSTOR_DATA.MovePlayerFromVentTo(ply, ent_idx)
	if not IsValid(ply.impo_in_vent) then
		return
	end
	
	local new_vent = GetVentFromIndex(ent_idx)
	
	print("BMF MovePlayerFromVentTo: from_ent_idx=" .. ply.impo_in_vent:EntIndex() .. ", to_ent_idx=" .. ent_idx)
	
	if IsValid(new_vent) then
		IMPOSTOR_DATA.MovePlayerToVent(ply, new_vent)
	else
		IMPOSTOR_DATA.ExitVent(ply)
	end
	
	if CLIENT then
		--Send request to server to call this function
		net.Start("TTT2ImpostorMoveFromVentUpdate")
		net.WriteInt(ent_idx, 16)
		net.SendToServer()
	end
end

function IMPOSTOR_DATA.ForceExitFromVent(ply)
	--Unlike MovePlayerFromVentTo, which is called by the client to request a change in vent status,
	--this function is used in the Server to force the player out.
	if not IsValid(ply.impo_in_vent) then
		return
	end
	
	IMPOSTOR_DATA.ExitVent(ply)
	
	if SERVER then
		--Send request to client to call this function
		net.Start("TTT2ImpostorForceExitFromVentUpdate")
		net.Send(ply)
	end
end

function IMPOSTOR_DATA.DetermineVentExitPos(vent_pos, vent_normal, vent_placement_range, ply_pos)
	local PLY_IS_CLOSE_TO_VENT = 10000 --100^2
	print("BMF DetermineVentExitPos: DistToSqr=" .. vent_pos:DistToSqr(ply_pos))
	if GetConVar("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit"):GetBool() and vent_pos:DistToSqr(ply_pos) <= PLY_IS_CLOSE_TO_VENT then
		--Player is relatively close to the would-be vent. Their own position can therefore be used.
		return ply_pos
	else
		--Server is configured to place vents from extreme distances.
		--Let exit_pos be close to the vent, while also not being inside the thing.
		return vent_pos + vent_normal * 50
	end
end

function IMPOSTOR_DATA.AddVentToNetwork(vent, owner)
	--Record player position and find good camera angle for vent exit handling.
	vent.exit_pos = IMPOSTOR_DATA.DetermineVentExitPos(vent:GetPos(), vent:GetAngles():Forward(), GetConVar("ttt2_impostor_vent_placement_range"):GetInt(), owner:GetPos())
	
	--BMF
	print("BMF AddVentToNetwork Vent ID = " .. vent:EntIndex() .. ", Exit Angle = ")
	print(vent:GetAngles())
	--print(tr.HitNormal:Angle()) --Absolutely the only way to print this thing from what I can tell...
	--BMF
	
	IMPOSTOR_DATA.VENT_NETWORK[#IMPOSTOR_DATA.VENT_NETWORK + 1] = vent
	
	--BMF
	if SERVER then
		print("BMF AddVentToNetwork: There are now " .. #IMPOSTOR_DATA.VENT_NETWORK .. " vents on the Server")
	elseif CLIENT then
		print("BMF AddVentToNetwork: There are now " .. #IMPOSTOR_DATA.VENT_NETWORK .. " vents on the Client")
	end
end

if SERVER then
	net.Receive("TTT2ImpostorMoveFromVentUpdate", function(len, ply)
			local ent_idx = net.ReadInt(16)
			
			IMPOSTOR_DATA.MovePlayerFromVentTo(ply, ent_idx)
	end)

	hook.Add("PlayerSwitchWeapon", "ImpostorDataPlayerSwitchWeapon", function(ply, old, new)
		if not IsValid(ply) or not ply:IsPlayer() or not IsValid(ply.impo_in_vent) then
			return
		end
		
		--Always force Impostor to use holstered. No attacking from the vents!
		--BMF
		print(new:GetClass())
		if new:GetClass() == "weapon_ttt_unarmed" then
			print("Player will become holstered!")
		end
		--BMF
		if new:GetClass() ~= "weapon_ttt_unarmed" then
			--The player will switch to the new weapon at the end of the function regardless.
			--The timer here is a hack to force the player to holstered after the end of this function.
			timer.Simple(0.2, function()
				--Verify the player's existence, in case they are dropped from the Server.
				if IsValid(ply) and ply:IsPlayer() and IsValid(ply.impo_in_vent) then
					ply:SelectWeapon("weapon_ttt_unarmed")
				end
			end)
		end
	end)
end

if CLIENT then
	net.Receive("TTT2ImpostorEnterVentUpdate", function()
		local client = LocalPlayer()
		local new_vent_idx = net.ReadInt(16)
		
		local new_vent = GetVentFromIndex(new_vent_idx)
		
		--client is entering the vent from real space. Put them into vent space.
		IMPOSTOR_DATA.EnterVent(client, new_vent)
	end)
	
	net.Receive("TTT2ImpostorForceExitFromVentUpdate", function()
		local client = LocalPlayer()
		
		IMPOSTOR_DATA.ForceExitFromVent(client)
	end)
	
	net.Receive("TTT2ImpostorRevealVentUpdate", function()
		local client = LocalPlayer()
		local new_vent_idx = net.ReadInt(16)
		
		IMPOSTOR_DATA.RevealVent(GetVentFromIndex(new_vent_idx))
	end)
	
	hook.Add("PreDrawOutlines", "PreDrawOutlinesImpostorVent", function()
		local client = LocalPlayer()
		
		--Outline vents for impostors and traitor team (They will be able to see it regardless of where they are)
		--Special roles such as Trappers and Jesters have to work for their access.
		if (client:GetSubRole() == ROLE_IMPOSTOR or client:GetTeam() == TEAM_TRAITOR) and #IMPOSTOR_DATA.VENT_NETWORK > 0 and not IsValid(client.impo_in_vent) then
			outline.Add(IMPOSTOR_DATA.VENT_NETWORK, IMPOSTOR.color, OUTLINE_MODE_VISIBLE)
		end
	end)
end