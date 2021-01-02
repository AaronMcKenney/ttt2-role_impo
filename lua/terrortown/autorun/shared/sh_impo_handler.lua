if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2ImpostorAddVentUpdate")
end

IMPOSTOR_DATA = {}
IMPOSTOR_DATA.VENT_NETWORK = {}

function IMPOSTOR_DATA.AddVentToNetwork(vent, ply, tr)
	--Record player position and find good camera angle for vent exit handling.
	vent.exit_pos = ply:GetPos()
	vent.exit_ang = tr.HitNormal:Angle()
	
	--BMF
	--local vent_exit_ang_p = "nil"
	--local vent_exit_ang_y = "nil"
	--local vent_exit_ang_r = "nil"
	--if vent.exit_ang then
	--	local vent_exit_ang_p = vent.exit_ang.p
	--	local vent_exit_ang_y = vent.exit_ang.y
	--	local vent_exit_ang_r = vent.exit_ang.r
	--end
	--print("BMF AddVentToNetwork Vent ID = " .. vent:GetCreationID() .. ", Exit Angle = (" .. vent_exit_ang_p .. ", " .. vent_exit_ang_y .. ", " .. vent_exit_ang_r .. ")")
	print("BMF AddVentToNetwork Vent ID = " .. vent:GetCreationID() .. ", Exit Angle = ")
	print(tr.HitNormal:Angle()) --Absolutely the only way to print this thing from what I can tell...
	--BMF
	
	IMPOSTOR_DATA.VENT_NETWORK[#IMPOSTOR_DATA.VENT_NETWORK + 1] = vent
	
	if SERVER then
		--Inform clients that a new vent has been placed so that they can make note of it.
		--Unfortunately, this means that a modded client will be able to easily sus out impostors.
		--TODO: May be better to send EntID instead of the entire entity (i.e. impo_in_vent is a simplified table instead of an entity)...
		net.Start("TTT2ImpostorAddVentUpdate")
		net.WriteEntity(vent)
		net.Broadcast()
	end
end

net.Receive("TTT2ImpostorAddVentUpdate", function()
		local client = LocalPlayer()
		local new_vent = net.ReadEntity()
		
		IMPOSTOR_DATA.VENT_NETWORK[#IMPOSTOR_DATA.VENT_NETWORK + 1] = new_vent
end)

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
	
	if SERVER then
		--Inform client of which vent they are now in.
		--TODO: May be better to send EntID instead of the entire entity...
		net.Start("TTT2ImpostorEnterVentUpdate")
		net.WriteEntity(vent)
		net.WriteVector(vent.exit_pos)
		net.WriteAngle(vent.exit_ang)
		net.Send(ply)
	end
end

function IMPOSTOR_DATA.EnterVent(ply, vent)
	--TODO:
	--Remove player from existence (if they aren't already removed. Spectating may not work!)
	--Move them to vent's exit position and have their camera pointing at a given angle.
	--Create "vent buttons" for all vents that the player isn't in (if they aren't already there).
	--Make "vent buttons" grow in size if the player is hovering their cursor near them.
	--Add functionality in role's shared page to enter vents if they enter the use key on a "vent button"
	--Add functionality in role's shared page to exit current vent if they enter use key on anything else.
	
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
	elseif CLIENT then
		if not ply.impo_can_insta_kill and timer.Exists("ImposterKillTimer_Client_" .. ply:SteamID64()) then
			timer.Pause("ImposterKillTimer_Client_" .. ply:SteamID64())
		end
	end
	
	IMPOSTOR_DATA.RevealVent(vent)
end

if SERVER then
	hook.Add("PlayerSwitchWeapon", "ImpostorDataPlayerSwitchWeapon", function(ply, old, new)
		if not IsValid(ply) or ply:GetSubRole() ~= ROLE_IMPOSTOR or not ply.impo_in_vent then
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

function IMPOSTOR_DATA.ExitVent(ply)
	--TODO:
	--Bring player back into existence.
	--Deactivate "vent buttons" if needed.
	
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
