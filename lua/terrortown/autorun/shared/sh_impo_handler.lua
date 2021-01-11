if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2ImpostorEnterVentUpdate")
	util.AddNetworkString("TTT2ImpostorMoveFromVentUpdate")
	util.AddNetworkString("TTT2ImpostorRevealVentUpdate")
end

IMPOSTOR_DATA = {}
IMPOSTOR_DATA.VENT_NETWORK = {}

function IMPOSTOR_DATA.RemoveVentFromNetwork(vent)
	if not vent then
		return
	end
	
	for i, v in ipairs(IMPOSTOR_DATA.VENT_NETWORK) do
		if v:GetCreationID() == vent:GetCreationID() then
			IMPOSTOR_DATA.VENT_NETWORK[i] = nil
			break
		end
	end
end

function IMPOSTOR_DATA.ResetVentNetwork()
	IMPOSTOR_DATA.VENT_NETWORK = {}
end
hook.Add("TTTEndRound", "ImpostorDataEndRound", IMPOSTOR_DATA.ResetVentNetwork())

function GetVentFromIndex(new_vent_idx)
	for _, vent in ipairs(IMPOSTOR_DATA.VENT_NETWORK) do
		if vent:EntIndex() == new_vent_idx then
			return vent
		end
	end
	
	return nil
end

function IMPOSTOR_DATA.CanUseVentNetwork(ply)
	if ply:GetSubRole() == ROLE_IMPOSTOR or (GetConVar("ttt2_impostor_traitor_team_can_use_vents"):GetBool() and ply:GetTeam() == TEAM_TRAITOR) then
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
	--FL_GODMODE ==> Prevent damage while in vent.
	--FL_NOTARGET ==> Prevent AI from targeting the player.
	ply:AddFlags(bit.bor(FL_ATCONTROLS, FL_GODMODE, FL_NOTARGET))
	
	IMPOSTOR_DATA.MovePlayerToVent(ply, vent)
	
	if SERVER then
		--Switch player's weapon to holstered.
		ply:SelectWeapon("weapon_ttt_unarmed")
	end
	
	--Pause the Impostor's kill timer if possible.
	if SERVER then
		if ply.impo_can_insta_kill == false and timer.Exists("ImpostorKillTimer_Server_" .. ply:SteamID64()) then
			timer.Pause("ImpostorKillTimer_Server_" .. ply:SteamID64())
		end
		
		--In addition, sync the client by having them call this same function
		net.Start("TTT2ImpostorEnterVentUpdate")
		net.WriteInt(vent:EntIndex(), 16)
		net.Send(ply)
		
		--In addition, reveal the vent to everyone since it was entered from
		IMPOSTOR_DATA.RevealVent(vent)
	elseif CLIENT then
		if not ply.impo_can_insta_kill and timer.Exists("ImpostorKillTimer_Client_" .. ply:SteamID64()) then
			timer.Pause("ImpostorKillTimer_Client_" .. ply:SteamID64())
		end
	end
end

function IMPOSTOR_DATA.ExitVent(ply)
	--Correct player's position to be in a safe place
	ply:SetPos(ply.impo_in_vent.exit_pos)
	
	--Bring the player back into existence by undoing everything done in EnterVent
	ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	ply:SetNoDraw(false)
	for _, wep in ipairs(ply:GetWeapons()) do
		wep:SetNoDraw(false)
	end
	ply:AddFlags(FL_AIMTARGET)
	ply:RemoveFlags(bit.bor(FL_ATCONTROLS, FL_GODMODE, FL_NOTARGET))
	
	--UnPause the Impostor's kill timer if possible.
	if SERVER then
		if ply.impo_can_insta_kill == false and timer.Exists("ImpostorKillTimer_Server_" .. ply:SteamID64()) then
			timer.UnPause("ImpostorKillTimer_Server_" .. ply:SteamID64())
		end
		
		--In addition, reveal the vent if it has been exited from for the first time.
		IMPOSTOR_DATA.RevealVent(ply.impo_in_vent)
	elseif CLIENT then
		if not ply.impo_can_insta_kill and timer.Exists("ImpostorKillTimer_Client_" .. ply:SteamID64()) then
			timer.UnPause("ImpostorKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	ply.impo_in_vent = nil
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

function IMPOSTOR_DATA.DetermineVentExitPos(vent_pos, vent_normal, vent_placement_range, ply_pos)
	local PLY_IS_CLOSE_TO_VENT = 10000 --100^2
	print("BMF DetermineVentExitPos: DistToSqr=" .. vent_pos:DistToSqr(ply_pos))
	if vent_pos:DistToSqr(ply_pos) <= PLY_IS_CLOSE_TO_VENT then
		--Player is relatively close to the would-be vent. Their own position can therefore be used.
		return ply_pos
	else
		--Server is configured to place vents from extreme distances.
		--Let exit_pos be close to the vent, while also not being inside the thing.
		return vent_pos + vent_normal * 100
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
	
	print("BMF AddVentToNetwork: There are now " .. #IMPOSTOR_DATA.VENT_NETWORK .. " vents on the Server")
end

if SERVER then
	net.Receive("TTT2ImpostorMoveFromVentUpdate", function(len, ply)
			local ent_idx = net.ReadInt(16)
			
			IMPOSTOR_DATA.MovePlayerFromVentTo(ply, ent_idx)
	end)

	hook.Add("PlayerSwitchWeapon", "ImpostorDataPlayerSwitchWeapon", function(ply, old, new)
		if not IsValid(ply) or not IsValid(ply.impo_in_vent) then
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
			timer.Create("ImpostorDataSwitchWeapon", 0, 1, function()
				ply:SelectWeapon("weapon_ttt_unarmed")
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
	
	net.Receive("TTT2ImpostorRevealVentUpdate", function()
		local client = LocalPlayer()
		local new_vent_idx = net.ReadInt(16)
		
		IMPOSTOR_DATA.RevealVent(GetVentFromIndex(new_vent_idx))
	end)
	
	hook.Add("PreDrawOutlines", "PreDrawOutlinesImpostorVent", function()
		local client = LocalPlayer()
		
		--Outline vents for traitor team (They will be able to see it regardless of where they are)
		if client:GetTeam() == TEAM_TRAITOR and #IMPOSTOR_DATA.VENT_NETWORK > 0 and not IsValid(client.impo_in_vent) then
			outline.Add(IMPOSTOR_DATA.VENT_NETWORK, IMPOSTOR.color, OUTLINE_MODE_VISIBLE)
		end
	end)
end