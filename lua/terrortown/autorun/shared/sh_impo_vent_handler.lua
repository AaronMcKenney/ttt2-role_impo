if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2ImpostorEnterVentUpdate")
	util.AddNetworkString("TTT2ImpostorMoveFromVentUpdate")
	util.AddNetworkString("TTT2ImpostorForceExitFromVentUpdate")
	util.AddNetworkString("TTT2ImpostorRevealVentUpdate")
end

IMPO_VENT_DATA = {}
IMPO_VENT_DATA.VENT_NETWORK = {}

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

function IMPO_VENT_DATA.RemoveVentFromNetwork(vent_idx)
	for i, v in ipairs(IMPO_VENT_DATA.VENT_NETWORK) do
		if v:EntIndex() == vent_idx then
			table.remove(IMPO_VENT_DATA.VENT_NETWORK, i)
			
			--if SERVER then
			--	print("IMPO_DEBUG RemoveVentFromNetwork: There are now " .. #IMPO_VENT_DATA.VENT_NETWORK .. " vents on the Server.")
			--elseif CLIENT then
			--	print("IMPO_DEBUG RemoveVentFromNetwork: There are now " .. #IMPO_VENT_DATA.VENT_NETWORK .. " vents on the Client.")
			--end
			break
		end
	end
end

function IMPO_VENT_DATA.ResetVentNetwork()
	IMPO_VENT_DATA.VENT_NETWORK = {}
	
	--print("IMPO_DEBUG ResetVentNetwork: Number of vents is now " .. #IMPO_VENT_DATA.VENT_NETWORK)
end
hook.Add("TTTPrepareRound", "ImpostorVentDataPrepareRound", IMPO_VENT_DATA.ResetVentNetwork)
hook.Add("TTTBeginRound", "ImpostorVentDataPrepareRound", IMPO_VENT_DATA.ResetVentNetwork)

function GetVentFromIndex(new_vent_idx)
	for _, vent in ipairs(IMPO_VENT_DATA.VENT_NETWORK) do
		if vent:EntIndex() == new_vent_idx then
			return vent
		end
	end
	
	return nil
end

local function TrapperCanVent(ply)
	local total_trapper_time_allowed = GetConVar("ttt2_impostor_trapper_venting_time"):GetInt()
	if TRAPPER and ply:GetSubRole() == ROLE_TRAPPER and total_trapper_time_allowed > 0 and not ply.impo_vent_timer_expired then
		return true
	end
	
	return false
end

local function DisguisedAsTraitor(ply)
	if ply:GetTeam() ~= TEAM_TRAITOR and ply:GetBaseRole() == ROLE_TRAITOR then
		return true
	end
	
	return false
end

local function JesterCanVent(ply)
	if JESTER and GetConVar("ttt2_impostor_jesters_can_vent"):GetBool() and ply:GetSubRole() == ROLE_JESTER then
		return true
	end
	
	return false
end

local function HandleSpecialRoleVenting(ply, is_entering_vent, was_role)
	local role_has_special_handling = false
	local role_str = ""
	local total_time_allowed = 0
	local treat_like_traitor = false
	if TRAPPER and (TrapperCanVent(ply) or was_role == ROLE_TRAPPER) then
		role_has_special_handling = true
		role_str = "Trapper"
		total_time_allowed = GetConVar("ttt2_impostor_trapper_venting_time"):GetInt()
	elseif DisguisedAsTraitor(ply) or was_role == -1 then
		role_has_special_handling = true
		role_str = "DopTraitor"
		total_time_allowed = -1
		treat_like_traitor = true
	elseif JESTER and (JesterCanVent(ply) or was_role == ROLE_JESTER) then
		role_has_special_handling = true
		role_str = "Jester"
		total_time_allowed = -1
	end
	
	if not role_has_special_handling then
		return role_str
	end
	
	if total_time_allowed > 0 and not ply.impo_vent_timer_expired then
		local server_client_str = "SERVER_"
		if CLIENT then
			server_client_str = "CLIENT_"
		end
		local vent_timer_str = "Impostor" .. role_str .. "Vent_" .. server_client_str .. ply:SteamID64()
		
		if not timer.Exists(vent_timer_str) then
			timer.Create(vent_timer_str, total_time_allowed, 1, function()
				--Verify the player's existence, in case they are dropped from the Server.
				if IsValid(ply) and ply:IsPlayer() then
					--Currently only the trapper has a timer.
					ply.impo_vent_timer_expired = true
					if IsValid(ply.impo_in_vent) then
						IMPO_VENT_DATA.ExitVent(ply)
					end
						
					if CLIENT then
						LANG.Msg("VENT_TIME_UP_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
					end
				end
			end)
		end
		
		if CLIENT then
			local time_left = math.ceil(math.abs(timer.TimeLeft(vent_timer_str)))
			LANG.Msg("VENT_TIME_LEFT_" .. IMPOSTOR.name, {t = time_left}, MSG_MSTACK_WARN)
		end
		
		--Timer should only run while the player is in a vent.
		--Could use timer.Toggle here, but decided that this is safer.
		if is_entering_vent then
			timer.UnPause(vent_timer_str)
		else
			timer.Pause(vent_timer_str)
		end
	end
	
	--Inform traitors when a non-Traitor role enters/exits a vent.
	--Explicitly treats doppelgangers like traitors
	if SERVER and GetConVar("ttt2_impostor_inform_about_non_traitors_venting"):GetBool() and not treat_like_traitor then
		if is_entering_vent then
			for _, ply_i in ipairs(player.GetAll()) do
				if ply_i:GetSubRole() == ROLE_IMPOSTOR or ply_i:GetTeam() == TEAM_TRAITOR or DisguisedAsTraitor(ply_i) then
					LANG.Msg(ply_i, "VENT_FOREIGNER_ENTER_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
				end
			end
		else
			for _, ply_i in ipairs(player.GetAll()) do
				if ply_i:GetSubRole() == ROLE_IMPOSTOR or ply_i:GetTeam() == TEAM_TRAITOR or DisguisedAsTraitor(ply_i) then
					LANG.Msg(ply_i, "VENT_FOREIGNER_EXIT_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
				end
			end
		end
	end
	
	return role_str
end

local function InformTrappers(ply, is_entering_vent)
	if not SERVER or not TRAPPER or not GetConVar("ttt2_impostor_inform_trappers_about_venting"):GetBool() then
		return
	end
	
	if is_entering_vent then
		for _, ply_i in ipairs(player.GetAll()) do
			if ply_i:GetSubRole() == ROLE_TRAPPER and ply:SteamID64() ~= ply_i:SteamID64() then
				LANG.Msg(ply_i, "VENT_ANYONE_ENTER_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
			end
		end
	else
		for _, ply_i in ipairs(player.GetAll()) do
			if ply_i:GetSubRole() == ROLE_TRAPPER and ply:SteamID64() ~= ply_i:SteamID64() then
				LANG.Msg(ply_i, "VENT_ANYONE_EXIT_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
			end
		end
	end
end

local function UpdateVentStatus(ply, vent_role_str, is_exiting_vent)
	--Always remove the status first, as we might switch from a normal status to a timed status or vice-versa.
	STATUS:RemoveStatus(ply, "ttt2_impo_in_vent")
	
	if is_exiting_vent then
		return
	end
	
	local server_client_str = "SERVER_"
	if CLIENT then
		server_client_str = "CLIENT_"
	end
	local vent_timer_str = "Impostor" .. vent_role_str .. "Vent_" .. server_client_str .. ply:SteamID64()
	if not timer.Exists(vent_timer_str) then
		STATUS:AddStatus(ply, "ttt2_impo_in_vent")
	else
		STATUS:AddTimedStatus(ply, "ttt2_impo_in_vent", math.ceil(math.abs(timer.TimeLeft(vent_timer_str))), true)
	end
end

function IMPO_VENT_DATA.CanUseVentNetwork(ply)
	if ply:IsTerror() and ply:Alive() and not IsInSpecDM(ply) and (ply:GetSubRole() == ROLE_IMPOSTOR or (GetConVar("ttt2_impostor_traitor_team_can_use_vents"):GetBool() and (ply:GetTeam() == TEAM_TRAITOR or DisguisedAsTraitor(ply))) or TrapperCanVent(ply) or JesterCanVent(ply)) then
		return true
	end
	
	return false
end

function IMPO_VENT_DATA.RevealVent(vent)
	if IsValid(vent) then
		--print("IMPO_DEBUG RevealVent: Revealing vent with index " .. vent:EntIndex())
		vent:SetNoDraw(false)
	end
	
	if SERVER then
		net.Start("TTT2ImpostorRevealVentUpdate")
		net.WriteInt(vent:EntIndex(), 16)
		net.Broadcast()
	end
end

function IMPO_VENT_DATA.MovePlayerToVent(ply, vent)
	--local server_client_str = "SERVER"
	--if CLIENT then
	--	server_client_str = "CLIENT"
	--end
	--local creation_id_str = "nil"
	--if vent and SERVER then
	--	creation_id_str = vent:GetCreationID()
	--end
	--local ent_id_str = vent:EntIndex()
	--print("IMPO_DEBUG MovePlayerToVent " .. server_client_str .. " Creation ID = " .. creation_id_str .. ", Ent ID = " .. ent_id_str)
	ply:SetPos(vent:GetPos())
	ply:SetEyeAngles(vent:GetAngles())
	ply.impo_in_vent = vent
end

function IMPO_VENT_DATA.EnterVent(ply, vent)
	if IsValid(ply.impo_in_vent) or not IsValid(vent) or not IMPO_VENT_DATA.CanUseVentNetwork(ply) then
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
	
	IMPO_VENT_DATA.MovePlayerToVent(ply, vent)
	
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
		IMPO_VENT_DATA.RevealVent(vent)
		
		InformTrappers(ply, true)
	elseif CLIENT then
		--Keep track of when the Impostor last entered/switched/exited a vent to prevent accidental key presses booting them out of a vent immediately upon entering it.
		ply.impo_last_move_time = CurTime()
		
		if not ply.impo_can_insta_kill and timer.Exists("ImpostorKillTimer_Client_" .. ply:SteamID64()) then
			timer.Pause("ImpostorKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	local vent_role_str = HandleSpecialRoleVenting(ply, true, nil)
	UpdateVentStatus(ply, vent_role_str, false)
end

function IMPO_VENT_DATA.ExitVent(ply)
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
		IMPO_VENT_DATA.RevealVent(ply.impo_in_vent)
		
		InformTrappers(ply, false)
	elseif CLIENT then
		if not ply.impo_can_insta_kill and timer.Exists("ImpostorKillTimer_Client_" .. ply:SteamID64()) then
			timer.UnPause("ImpostorKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	HandleSpecialRoleVenting(ply, false, nil)
	
	ply.impo_in_vent = nil
	
	if SERVER then
		--Make the player switch back to their previous weapon if possible.
		--This is called after impo_in_vent is set to nil to prevent situation where they are auto-switched back to holstered.
		if ply.impo_in_vent_prev_wep ~= nil then
			ply:SelectWeapon(ply.impo_in_vent_prev_wep)
			ply.impo_in_vent_prev_wep = nil
		end
	else --CLIENT
		ply.impo_last_move_time = CurTime()
	end
	
	STATUS:RemoveStatus(ply, "ttt2_impo_in_vent")
end

function IMPO_VENT_DATA.MovePlayerFromVentTo(ply, ent_idx)
	if not IsValid(ply.impo_in_vent) then
		--print("IMPO_DEBUG MovePlayerFromVentTo: Trying to move from an invalid vent! ent_idx=" .. tostring(ent_idx))
		
		if SERVER then
			--Safety check: if the server receives a request from the client to move from a vent that does not exist,
			--assume that the client believes that they are in a vent when they shouldn't be and force them out.
			IMPO_VENT_DATA.ForceExitFromVent(ply)
		end
		
		return
	end
	
	local new_vent = GetVentFromIndex(ent_idx)
	
	--print("IMPO_DEBUG MovePlayerFromVentTo: from_ent_idx=" .. ply.impo_in_vent:EntIndex() .. ", to_ent_idx=" .. ent_idx)
	
	if IsValid(new_vent) then
		IMPO_VENT_DATA.MovePlayerToVent(ply, new_vent)
		
		if CLIENT then
			--Separate from the MovePlayerToVent call as EnterVent also calls that function, and also sets impo_last_move_time later on.
			ply.impo_last_move_time = CurTime()
		end
	else
		IMPO_VENT_DATA.ExitVent(ply)
	end
	
	if SERVER then
		--Send request to server to call this function
		net.Start("TTT2ImpostorMoveFromVentUpdate")
		net.WriteInt(ent_idx, 16)
		net.Send(ply)
	end
end

function IMPO_VENT_DATA.ForceExitFromVent(ply)
	--Unlike MovePlayerFromVentTo, which is called by the client to request a change in vent status,
	--this function is used in the Server to force the player out.
	IMPO_VENT_DATA.ExitVent(ply)
	
	if SERVER then
		--Send request to client to call this function
		net.Start("TTT2ImpostorForceExitFromVentUpdate")
		net.Send(ply)
	end
end

function IMPO_VENT_DATA.DetermineVentExitPos(vent_pos, vent_normal, vent_placement_range, ply_pos)
	local PLY_IS_CLOSE_TO_VENT = 10000 --100^2
	--print("IMPO_DEBUG DetermineVentExitPos: DistToSqr=" .. vent_pos:DistToSqr(ply_pos))
	if GetConVar("ttt2_impostor_nearby_new_vents_use_ply_pos_as_exit"):GetBool() and vent_pos:DistToSqr(ply_pos) <= PLY_IS_CLOSE_TO_VENT then
		--Player is relatively close to the would-be vent. Their own position can therefore be used.
		return ply_pos
	else
		--Server is configured to place vents from extreme distances.
		--Let exit_pos be close to the vent, while also not being inside the thing.
		return vent_pos + vent_normal * 50
	end
end

function IMPO_VENT_DATA.AddVentToNetwork(vent, owner)
	--Record player position and find good camera angle for vent exit handling.
	vent.exit_pos = IMPO_VENT_DATA.DetermineVentExitPos(vent:GetPos(), vent:GetAngles():Forward(), GetConVar("ttt2_impostor_vent_placement_range"):GetInt(), owner:GetPos())
	
	--print("IMPO_DEBUG AddVentToNetwork Vent ID = " .. vent:EntIndex() .. ", Exit Angle = ")
	--print(vent:GetAngles())
	
	IMPO_VENT_DATA.VENT_NETWORK[#IMPO_VENT_DATA.VENT_NETWORK + 1] = vent
	
	--if SERVER then
	--	print("IMPO_DEBUG AddVentToNetwork: There are now " .. #IMPO_VENT_DATA.VENT_NETWORK .. " vents on the Server")
	--elseif CLIENT then
	--	print("IMPO_DEBUG AddVentToNetwork: There are now " .. #IMPO_VENT_DATA.VENT_NETWORK .. " vents on the Client")
	--end
end

local function VentSecurityCheck(ply)
	if not IsValid(ply.impo_in_vent) then
		return false
	end
	
	if not IMPO_VENT_DATA.CanUseVentNetwork(ply) then
		IMPO_VENT_DATA.ExitVent(ply)
		return false
	end
	
	return true
end
hook.Add("TTT2UpdateTeam", "ImpostorUpdateTeam", function(ply, oldTeam, team)
	if not VentSecurityCheck(ply) or oldTeam == team then
		return
	end
	
	if oldTeam ~= TEAM_TRAITOR then
		--Special case: If we have a player who was once a non-Traitor in the vents, inform others that they're now gone or whatever.
		HandleSpecialRoleVenting(ply, false, -1)
	end
end)
hook.Add("TTT2UpdateSubrole", "ImpostorUpdateSubrole", function(ply, oldSubrole, subrole)
	if not VentSecurityCheck(ply) or oldSubrole == subrole then
		return
	end
	
	if oldSubrole == ROLE_TRAPPER or oldSubrole == ROLE_JESTER then
		--Special case: If we have a Trapper who has become anything else we need to stop the timer.
		--They have now "exited" the vent.
		--Can't really handle Doppelgangers here since we don't have access to their old team.
		--It's hacky I know.
		local vent_role_str = HandleSpecialRoleVenting(ply, false, oldSubrole)
		UpdateVentStatus(ply, vent_role_str, false)
	end
	
	--Needed for Trappers, whose timer needs to start/unpause.
	--Also informs Traitors that a foreigner has "entered" the vent.
	--(Note: There is a weird case in which a Trapper becomes a Jester, both of whom are given the ability to vent. This leads to two quick messages, one saying that a foreigner has exited the vents and another saying that they have entered the vents.)
	local vent_role_str = HandleSpecialRoleVenting(ply, true, nil)
	UpdateVentStatus(ply, vent_role_str, false)
end)

if SERVER then
	net.Receive("TTT2ImpostorMoveFromVentUpdate", function(len, ply)
		local ent_idx = net.ReadInt(16)
		
		IMPO_VENT_DATA.MovePlayerFromVentTo(ply, ent_idx)
	end)

	hook.Add("PlayerSwitchWeapon", "ImpostorVentDataPlayerSwitchWeapon", function(ply, old, new)
		if not IsValid(ply) or not ply:IsPlayer() or not IsValid(ply.impo_in_vent) then
			return
		end
		
		--Always force Impostor to use holstered. No attacking from the vents!
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
	hook.Add("Initialize", "InitializeUndecided", function()
		STATUS:RegisterStatus("ttt2_impo_in_vent", {
			hud = Material("vgui/ttt/icon_vent"),
			type = "good"
		})
	end)
	
	net.Receive("TTT2ImpostorEnterVentUpdate", function()
		local client = LocalPlayer()
		local new_vent_idx = net.ReadInt(16)
		
		local new_vent = GetVentFromIndex(new_vent_idx)
		
		--client is entering the vent from real space. Put them into vent space.
		IMPO_VENT_DATA.EnterVent(client, new_vent)
	end)
	
	net.Receive("TTT2ImpostorMoveFromVentUpdate", function()
		local client = LocalPlayer()
		local ent_idx = net.ReadInt(16)
		
		IMPO_VENT_DATA.MovePlayerFromVentTo(client, ent_idx)
	end)
	
	net.Receive("TTT2ImpostorForceExitFromVentUpdate", function()
		local client = LocalPlayer()
		
		IMPO_VENT_DATA.ForceExitFromVent(client)
	end)
	
	net.Receive("TTT2ImpostorRevealVentUpdate", function()
		local client = LocalPlayer()
		local new_vent_idx = net.ReadInt(16)
		
		IMPO_VENT_DATA.RevealVent(GetVentFromIndex(new_vent_idx))
	end)
	
	hook.Add("PreDrawOutlines", "ImpostorVentDataPreDrawOutlines", function()
		local client = LocalPlayer()
		
		--Outline vents for impostors and traitor team (They will be able to see it regardless of where they are)
		--Special roles such as Trappers and Jesters have to work for their access.
		--Could use OUTLINE_MODE_VISIBLE to only outline vents that aren't blocked, but that code is finicky and doesn't work on all surfaces. Perhaps it doesn't like vents that are partially in a surface?
		if (client:GetSubRole() == ROLE_IMPOSTOR or client:GetTeam() == TEAM_TRAITOR or DisguisedAsTraitor(client)) and not IsInSpecDM(client) and #IMPO_VENT_DATA.VENT_NETWORK > 0 and not IsValid(client.impo_in_vent) then
			outline.Add(IMPO_VENT_DATA.VENT_NETWORK, IMPOSTOR.color, OUTLINE_MODE_BOTH)
		end
	end)
	
	function IMPO_VENT_DATA.RequestVentMove(ent_idx)
		net.Start("TTT2ImpostorMoveFromVentUpdate")
		net.WriteInt(ent_idx, 16)
		net.SendToServer()
	end
end