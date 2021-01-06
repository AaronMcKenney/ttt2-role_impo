if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2ImpostorAddVentUpdate")
	util.AddNetworkString("TTT2ImpostorEnterVentUpdate")
	util.AddNetworkString("TTT2ImpostorSwitchVentUpdate")
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

function IMPOSTOR_DATA.RevealVent(vent)
	if vent then
		vent:SetNoDraw(false)
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
	ply:SetEyeAngles(vent.exit_ang)
	ply.impo_in_vent = vent
end

function IMPOSTOR_DATA.EnterVent(ply, vent)
	if IsValid(ply.impo_in_vent) or not IsValid(vent) then
		return
	end
	
	--Effectively remove the player from existence by refusing to draw them, removing their collision box, and freezing them in place. May not be perfect!
	--Could also try spectating here, but not sure if TTT2 will handle that properly (ex. may assume the player has died and break certain mods)
	ply:SetCollisionGroup(COLLISION_GROUP_VEHICLE) --Vents really are vehicles, if you think about it.
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
		if ply.impo_can_insta_kill == false and timer.Exists("ImposterKillTimer_Server_" .. ply:SteamID64()) then
			timer.Pause("ImposterKillTimer_Server_" .. ply:SteamID64())
		end
		
		--In addition, sync the client by having them call this same function
		net.Start("TTT2ImpostorEnterVentUpdate")
		net.WriteInt(vent:EntIndex(), 16)
		net.Send(ply)
	elseif CLIENT then
		if not ply.impo_can_insta_kill and timer.Exists("ImposterKillTimer_Client_" .. ply:SteamID64()) then
			timer.Pause("ImposterKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	IMPOSTOR_DATA.RevealVent(vent)
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
		if ply.impo_can_insta_kill == false and timer.Exists("ImposterKillTimer_Server_" .. ply:SteamID64()) then
			timer.UnPause("ImposterKillTimer_Server_" .. ply:SteamID64())
		end
	elseif CLIENT then
		if not ply.impo_can_insta_kill and timer.Exists("ImposterKillTimer_Client_" .. ply:SteamID64()) then
			timer.UnPause("ImposterKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	IMPOSTOR_DATA.RevealVent(ply.impo_in_vent)
	ply.impo_in_vent = nil
end

function IMPOSTOR_DATA.SwitchVents(ply, ent_idx)
	if not IsValid(ply.impo_in_vent) then
		return
	end
	
	local new_vent = GetVentFromIndex(ent_idx)
	
	print("BMF SwitchVents: ent_idx=" .. ent_idx)
	
	if IsValid(new_vent) then
		IMPOSTOR_DATA.MovePlayerToVent(ply, new_vent)
	else
		IMPOSTOR_DATA.ExitVent(ply)
	end
	
	if CLIENT then
		--Send request to server to call this function
		net.Start("TTT2ImpostorSwitchVentUpdate")
		net.WriteInt(ent_idx, 16)
		net.SendToServer()
	end
end

if SERVER then
	net.Receive("TTT2ImpostorSwitchVentUpdate", function(len, ply)
			local ent_idx = net.ReadInt(16)
			
			IMPOSTOR_DATA.SwitchVents(ply, ent_idx)
	end)
	
	function IMPOSTOR_DATA.AddVentToNetwork(vent, ply, tr)
		--Record player position and find good camera angle for vent exit handling.
		vent.exit_pos = ply:GetPos()
		vent.exit_ang = tr.HitNormal:Angle()
		
		if GetConVar("ttt2_impostor_vent_placement_range"):GetInt() > 100 then
			--Server is configured to place vents from extreme distances.
			--Modify exit_pos to be closer to the vent, while also not being inside the thing.
			vent.exit_pos = tr.HitPos + tr.HitNormal * 100
		end
		
		--BMF
		print("BMF AddVentToNetwork Vent ID = " .. vent:GetCreationID() .. ", Exit Angle = ")
		print(tr.HitNormal:Angle()) --Absolutely the only way to print this thing from what I can tell...
		--BMF
		
		IMPOSTOR_DATA.VENT_NETWORK[#IMPOSTOR_DATA.VENT_NETWORK + 1] = vent
		
		--Inform clients that a new vent has been placed so that they can make note of it.
		--Unfortunately, this means that a modded client will be able to easily sus out impostors.
		--TODO: May be better to send EntID instead of the entire entity (i.e. impo_in_vent is a simplified table instead of an entity)...
		net.Start("TTT2ImpostorAddVentUpdate")
		net.WriteEntity(vent)
		net.WriteVector(vent.exit_pos)
		net.WriteAngle(vent.exit_ang)
		net.Broadcast()
	end

	hook.Add("PlayerSwitchWeapon", "ImpostorDataPlayerSwitchWeapon", function(ply, old, new)
		if not IsValid(ply) or ply:GetSubRole() ~= ROLE_IMPOSTOR or not IsValid(ply.impo_in_vent) then
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
	net.Receive("TTT2ImpostorAddVentUpdate", function()
			local client = LocalPlayer()
			local new_vent = net.ReadEntity()
			local exit_pos = net.ReadVector()
			local exit_ang = net.ReadAngle()
			
			--Have to re-add any extra bits of info here as they are not sent in ReadEntity
			new_vent.exit_pos = exit_pos
			new_vent.exit_ang = exit_ang
			
			IMPOSTOR_DATA.VENT_NETWORK[#IMPOSTOR_DATA.VENT_NETWORK + 1] = new_vent
	end)
	
	net.Receive("TTT2ImpostorEnterVentUpdate", function()
		local client = LocalPlayer()
		local new_vent_idx = net.ReadInt(16)
		
		local new_vent = GetVentFromIndex(new_vent_idx)
		
		--client is entering the vent from real space. Put them into vent space.
		IMPOSTOR_DATA.EnterVent(client, new_vent)
	end)
	
	hook.Add("PreDrawOutlines", "PreDrawOutlinesImpostorVent", function()
		local client = LocalPlayer()
		
		--Outline vents for traitor team (They will be able to see it regardless of where they are)
		if client:GetTeam() == TEAM_TRAITOR and #IMPOSTOR_DATA.VENT_NETWORK > 0 and not IsValid(client.impo_in_vent) then
			outline.Add(IMPOSTOR_DATA.VENT_NETWORK, IMPOSTOR.color, OUTLINE_MODE_VISIBLE)
		end
	end)
end