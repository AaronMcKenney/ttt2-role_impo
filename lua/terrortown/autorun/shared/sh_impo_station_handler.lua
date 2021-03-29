if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2ImpostorSendEntireStationNetwork")
	util.AddNetworkString("TTT2ImpostorAddStationToNetwork")
end

IMPO_SABO_DATA = {}
IMPO_SABO_DATA.STATION_NETWORK = {}
IMPO_SABO_DATA.ACTIVE_SABO_ENT = nil

local function SafePosCanBeAdded(new_pos)
	local min_dist = GetConVar("ttt2_impostor_min_station_dist"):GetInt()
	local min_dist_sqrd = min_dist * min_dist
	local can_be_added = true
	
	--Don't add spawns that are too close to previously added spawns
	for _, stat_spawn in ipairs(IMPO_SABO_DATA.STATION_NETWORK) do
		if stat_spawn.pos:DistToSqr(new_pos) <= min_dist_sqrd then
			can_be_added = false
			break
		end
	end
	
	return can_be_added
end

function IMPO_SABO_DATA.SelectedStationIsValid(selected_station)
	if selected_station == nil or selected_station < 1 or selected_station > #IMPO_SABO_DATA.STATION_NETWORK then
		return false
	end
	
	return true
end

function IMPO_SABO_DATA.StationHasBeenUsed(selected_station)
	if not IMPO_SABO_DATA.SelectedStationIsValid(selected_station) or not IMPO_SABO_DATA.STATION_NETWORK[selected_station].used then
		return false
	end
	
	return true
end

function IMPO_SABO_DATA.MarkStationAsUsed(selected_station)
	if not IMPO_SABO_DATA.SelectedStationIsValid(selected_station) then
		return
	end
	
	IMPO_SABO_DATA.STATION_NETWORK[selected_station].used = true
	
	--If all stations have been used, unmark all of them except for the one that was just used.
	local num_used = 0
	for _, stat_spawn in ipairs(IMPO_SABO_DATA.STATION_NETWORK) do
		if stat_spawn.used then
			num_used = num_used + 1
		end
	end
	
	if num_used >= #IMPO_SABO_DATA.STATION_NETWORK then
		for i, stat_spawn in ipairs(IMPO_SABO_DATA.STATION_NETWORK) do
			if i ~= selected_station then
				stat_spawn.used = false
			end
		end
	end
end

function IMPO_SABO_DATA.MaybeGetNewStationSpawnPos(ply)
	--If the player is looking at a valid spawn point, return that position. Otherwise return nil
	local maybe_spawn_pos = nil
	
	if not ply:IsPlayer() or ply:GetSubRole() ~= ROLE_IMPOSTOR or not ply:IsActive() then
		return maybe_spawn_pos
	end
	
	--Determine if the impostor is looking at a potential station spawn position.
	--To be a station spawn position, it must be accessible by non-Traitors who can't worm their way into a traitor room,
	--musn't be too close to existing spawn positions, and must be in a safe location.
	local trace = ply:GetEyeTrace(MASK_SHOT_HULL)
	local dist = trace.StartPos:Distance(trace.HitPos)
	local tgt = trace.Entity
	if IsValid(tgt) and tgt:IsPlayer() and tgt:GetTeam() ~= TEAM_TRAITOR and not ply:GetSubRoleData().traitorButton and SafePosCanBeAdded(tgt:GetPos()) then
		if SERVER then
			if spawn.IsSpawnPointSafe(ply, tgt:GetPos(), false, player.GetAll()) then
				maybe_spawn_pos = tgt:GetPos()
			end
		elseif CLIENT then
			--Only server can check if the spawn point is safe. Client will just assume that it is, and leave Server to actually check this.
			maybe_spawn_pos = tgt:GetPos()
		end
	end
	
	return maybe_spawn_pos
end

function IMPO_SABO_DATA.ForceEndSabotage()
	if SERVER then
		timer.Adjust("ImpostorSaboLightsTimer_Server", 0, nil, nil)
		timer.Adjust("ImpostorSaboCommsTimer_Server", 0, nil, nil)
		timer.Adjust("ImpostorSaboO2Timer_Server", 0, nil, nil)
	elseif CLIENT then
		timer.Adjust("ImpostorSaboLightsTimer_Client", 0, nil, nil)
		timer.Adjust("ImpostorSaboCommsTimer_Client", 0, nil, nil)
		timer.Adjust("ImpostorSaboO2Timer_Client", 0, nil, nil)
	end
	
	IMPO_SABO_DATA.ACTIVE_SABO_ENT = nil
end

if SERVER then
	hook.Add("TTTPrepareRound", "ImpostorSaboDataPrepareRoundForServer", function()
		local min_dist = GetConVar("ttt2_impostor_min_station_dist"):GetInt()
		local min_dist_sqrd = min_dist * min_dist
		local all_ply_spawn_pos = spawn.GetPlayerSpawnPointTable()
		
		IMPO_SABO_DATA.STATION_NETWORK = {}
		
		print("BMF ImpostorSaboDataPrepareRoundForServer: All Player Spawn Points")
		for _, ply_spawn_pos in ipairs(all_ply_spawn_pos) do
			print(ply_spawn_pos) --BMF
			if SafePosCanBeAdded(ply_spawn_pos) then
				print("  Adding spawn point") --BMF
				local stat_spawn = {}
				stat_spawn.pos = ply_spawn_pos
				stat_spawn.used = false
				
				IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
			end
		end
		
		print("BMF ImpostorSaboDataPrepareRoundForServer: Station Network has " .. #IMPO_SABO_DATA.STATION_NETWORK .. " entries.")
	end)
	
	function IMPO_SABO_DATA.SendStationNetwork(ply)
		net.Start("TTT2ImpostorSendEntireStationNetwork")
		--Note: Don't use WriteTable because it can overflow and might be read out of order.
		net.WriteInt(#IMPO_SABO_DATA.STATION_NETWORK, 16)
		for _, stat_spawn in ipairs(IMPO_SABO_DATA.STATION_NETWORK) do
			net.WriteVector(stat_spawn.pos)
			net.WriteBool(stat_spawn.used)
		end
		
		net.Send(ply)
	end
	
	function IMPO_SABO_DATA.BroadcastStationNetwork()
		if #IMPO_SABO_DATA.STATION_NETWORK > 0 then
			for _, ply in ipairs(player.GetAll()) do
				if ply:GetSubRole() == ROLE_IMPOSTOR then
					IMPO_SABO_DATA.SendStationNetwork(ply)
				end
			end
		end
	end
	
	function IMPO_SABO_DATA.MaybeAddNewStationSpawn(ply)
		local maybe_spawn_pos = IMPO_SABO_DATA.MaybeGetNewStationSpawnPos(ply)
		
		if maybe_spawn_pos ~= nil then
			local stat_spawn = {}
			stat_spawn.pos = maybe_spawn_pos
			stat_spawn.used = false
			
			IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
			
			for _, ply in ipairs(player.GetAll()) do
				if ply:GetSubRole() == ROLE_IMPOSTOR then
					net.Start("TTT2ImpostorAddStationToNetwork")
					net.WriteVector(stat_spawn.pos)
					net.WriteBool(stat_spawn.used)
					net.Send(ply)
				end
			end
		end
	end
	
	function IMPO_SABO_DATA.CreateStation(ply, selected_station)
		local dissuade_station_reuse = GetConVar("ttt2_impostor_dissuade_station_reuse"):GetBool()
		if dissuade_station_reuse and IMPO_SABO_DATA.STATION_NETWORK[selected_station].used then
			--Can't spawn stations in a location that has already been used.
			return false
		end
		
		local station_pos = IMPO_SABO_DATA.STATION_NETWORK[selected_station].pos
		local sabo_station = ents.Create("ttt_sabotage_station")
		if IsValid(sabo_station) then
			sabo_station:SetPos(station_pos)
			sabo_station:SetOwner(ply)
			sabo_station:Spawn()
		else
			LANG.Msg(ply, "SABO_CANNOT_PLACE_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
			return false
		end
		
		--Mark station as used
		IMPO_SABO_DATA.MarkStationAsUsed(selected_station)
		
		return true
	end
	
	function IMPO_SABO_DATA.DestroyStation()
		if IsValid(IMPO_SABO_DATA.ACTIVE_SABO_ENT) then
			IMPO_SABO_DATA.ACTIVE_SABO_ENT:Remove()
		end
	end
end

if CLIENT then
	hook.Add("TTTPrepareRound", "ImpostorSaboDataPrepareRoundForClient", function()
		IMPO_SABO_DATA.STATION_NETWORK = {}
	end)
	
	net.Receive("TTT2ImpostorSendEntireStationNetwork", function()
		local client = LocalPlayer()
		local network_size = net.ReadInt(16)
		
		IMPO_SABO_DATA.STATION_NETWORK = {}
		
		print("BMF TTT2ImpostorSendEntireStationNetwork: Reading station network of size " .. network_size)
		
		for i = 1, network_size do
			local stat_spawn = {}
			stat_spawn.pos = net.ReadVector()
			stat_spawn.used = net.ReadBool()
			
			IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
			
			print("  stat_spawn[" .. i .. "].pos = <" .. stat_spawn.pos.x .. ", " .. stat_spawn.pos.y .. ", " .. stat_spawn.pos.z .. ">")
		end
		
		--Reset impo_selected_station if needed (Recall that Lua is 1-indexed, not 0-indexed!).
		if client.impo_selected_station == nil then
			client.impo_selected_station = 1
		end
	end)
	
	net.Receive("TTT2ImpostorAddStationToNetwork", function()
		local stat_spawn = {}
		stat_spawn.pos = net.ReadVector()
		stat_spawn.used = net.ReadBool()
		
		IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
	end)
	
	function IMPO_SABO_DATA.CycleSelectedSabotageStation()
		local client = LocalPlayer()
		local dissuade_station_reuse = GetConVar("ttt2_impostor_dissuade_station_reuse"):GetBool()
		local station_count = #IMPO_SABO_DATA.STATION_NETWORK
		
		--BMF
		local station_network_str = "[ "
		for i = 1, #IMPO_SABO_DATA.STATION_NETWORK do
			if IMPO_SABO_DATA.STATION_NETWORK[i].used then
				station_network_str = station_network_str .. "true "
			else
				station_network_str = station_network_str .. "false "
			end
		end
		station_network_str = station_network_str .. "]"
		print("BMF CycleSelectedSabotageStation: impo_selected_station = " .. client.impo_selected_station .. ", # stations = " .. #IMPO_SABO_DATA.STATION_NETWORK .. ", station use = " .. station_network_str)
		--BMF
		
		--Safeguard
		if not IMPO_SABO_DATA.SelectedStationIsValid(client.impo_selected_station) then
			client.impo_selected_station = 1
			return
		end
		
		--Perform one full loop. Return back to original (valid) value of impo_selected_station if all are marked as used.
		--Recall that Lua 1-indexed, not 0-indexed!
		while station_count > 0 do
			if not IMPO_SABO_DATA.SelectedStationIsValid(client.impo_selected_station + 1) then
				client.impo_selected_station = 1
			else
				client.impo_selected_station = client.impo_selected_station + 1
			end
			
			print("  impo_selected_station = " .. client.impo_selected_station)
			if not dissuade_station_reuse or not IMPO_SABO_DATA.STATION_NETWORK[client.impo_selected_station].used then
				break
			end
			
			station_count = station_count - 1
		end
	end
	
	function IMPO_SABO_DATA.MarkAndCycleSelectedSabotageStation()
		local client = LocalPlayer()
		local dissuade_station_reuse = GetConVar("ttt2_impostor_dissuade_station_reuse"):GetBool()
		
		IMPO_SABO_DATA.MarkStationAsUsed(client.impo_selected_station)
		--If dissuade_station_reuse is disabled, then the impostor probably won't bother using other sabotage stations.
		if dissuade_station_reuse then
			IMPO_SABO_DATA.CycleSelectedSabotageStation()
		end
	end
	
	hook.Add("PreDrawOutlines", "ImpostorSaboDataPreDrawOutlines", function()
		--Outline station for all to see.
		if IsValid(IMPO_SABO_DATA.ACTIVE_SABO_ENT) then
			outline.Add(IMPO_SABO_DATA.ACTIVE_SABO_ENT, IMPOSTOR.color, OUTLINE_MODE_BOTH)
		end
	end)
end