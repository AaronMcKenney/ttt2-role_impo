if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2ImpostorSabotageUpdate")
	util.AddNetworkString("TTT2ImpostorSendEntireStationNetwork")
	util.AddNetworkString("TTT2ImpostorAddStationToNetwork")
	util.AddNetworkString("TTT2ImpostorSetStrangeGame")
end

IMPO_SABO_DATA = {}
IMPO_SABO_DATA.STATION_NETWORK = {}
IMPO_SABO_DATA.ACTIVE_STAT_ENT = nil
IMPO_SABO_DATA.THRESHOLD = 0
IMPO_SABO_DATA.STRANGE_GAME = false

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

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

function IMPO_SABO_DATA.SelectedStationIsUsable(selected_station)
	local dissuade_station_reuse = GetConVar("ttt2_impostor_dissuade_station_reuse"):GetBool()
	if not IMPO_SABO_DATA.SelectedStationIsValid(selected_station) or (dissuade_station_reuse and IMPO_SABO_DATA.STATION_NETWORK[selected_station].used) then
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

if SERVER then
	IMPO_SABO_DATA.ON_COOLDOWN = false
	
	hook.Add("TTTPrepareRound", "ImpostorSaboDataPrepareRoundForServer", function()
		local min_dist = GetConVar("ttt2_impostor_min_station_dist"):GetInt()
		local min_dist_sqrd = min_dist * min_dist
		local all_ply_spawn_points = plyspawn.GetPlayerSpawnPoints()
		
		IMPO_SABO_DATA.STATION_NETWORK = {}
		IMPO_SABO_DATA.ACTIVE_STAT_ENT = nil
		IMPO_SABO_DATA.THRESHOLD = 0
		IMPO_SABO_DATA.ON_COOLDOWN = false
		IMPO_SABO_DATA.STRANGE_GAME = false
		IMPO_SABO_DATA.FORCE_END_OCCURRED = nil
		IMPO_SABO_DATA.SABOTAGER = nil
		
		--print("IMPO_DEBUG ImpostorSaboDataPrepareRoundForServer: All Player Spawn Points")
		--PrintTable(all_ply_spawn_points) --IMPO_DEBUG
		for _, ply_spawn_point in ipairs(all_ply_spawn_points) do
			--PrintTable(ply_spawn_point) --IMPO_DEBUG
			if SafePosCanBeAdded(ply_spawn_point.pos) then
				--print("  Adding spawn point") --IMPO_DEBUG
				local stat_spawn = {}
				stat_spawn.pos = ply_spawn_point.pos
				stat_spawn.used = false
				
				IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
			end
		end
		
		--print("IMPO_DEBUG ImpostorSaboDataPrepareRoundForServer: Station Network has " .. #IMPO_SABO_DATA.STATION_NETWORK .. " entries.")
	end)
	
	function IMPO_SABO_DATA.CurrentSabotageInProgress()
		if timer.Exists("ImpostorSaboLightsTimer_Server") then
			return SABO_MODE.LIGHTS
		elseif timer.Exists("ImpostorSaboCommsTimer_Server") then
			return SABO_MODE.COMMS
		elseif timer.Exists("ImpostorSaboO2Timer_Server") then
			return SABO_MODE.O2
		elseif timer.Exists("ImpostorSaboReactTimer_Server") then
			return SABO_MODE.REACT
		end
		
		return SABO_MODE.NONE
	end
	
	function IMPO_SABO_DATA.SendSabotageUpdateToClients(sabo_cooldown)
		net.Start("TTT2ImpostorSabotageUpdate")
		net.WriteInt(sabo_cooldown, 16)
		net.Broadcast()
	end
	
	function IMPO_SABO_DATA.PutSabotageOnCooldown(sabo_cooldown)
		--print("IMPO_DEBUG PutSabotageOnCooldown")
		--Handle case where admin wants impostor to be overpowered trash.
		if sabo_cooldown <= 0 then
			IMPO_SABO_DATA.ON_COOLDOWN = false
			IMPO_SABO_DATA.SendSabotageUpdateToClients(0)
			return
		end
		
		--Put Sabotages on cooldown
		IMPO_SABO_DATA.ON_COOLDOWN = true
		IMPO_SABO_DATA.SendSabotageUpdateToClients(sabo_cooldown)
		
		--Create a timer that enables sabotages after the cooldown ends.
		timer.Create("ImpostorSaboTimer_Server", sabo_cooldown, 1, function()
			IMPO_SABO_DATA.ON_COOLDOWN = false
			IMPO_SABO_DATA.SendSabotageUpdateToClients(0)
		end)
	end
	
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
	
	local function IsSpy(ply)
		if SPY and ply:GetSubRole() == ROLE_SPY then
			return true
		else
			return false
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
		if IsValid(tgt) and tgt:IsPlayer() then
			--Doppel support: Dop!Impostors shouldn't be able to create spawn points from either traitors or their teammates.
			--Spy support: Treat spies like traitors, as otherwise the station manager would be an easy spy detector.
			if tgt:GetTeam() ~= TEAM_TRAITOR and ply:GetTeam() ~= tgt:GetTeam() and not IsSpy(tgt) then
				if SafePosCanBeAdded(tgt:GetPos()) then
					if plyspawn.IsSpawnPointSafe(ply, tgt:GetPos(), false, player.GetAll()) then
						maybe_spawn_pos = tgt:GetPos()
					else
						LANG.Msg(ply, "SABO_MNGR_UNSAFE_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
					end
				else
					LANG.Msg(ply, "SABO_MNGR_TOO_CLOSE_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
				end
			else
				LANG.Msg(ply, "SABO_MNGR_BAD_PLY_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
			end
		end
		
		return maybe_spawn_pos
	end
	
	function IMPO_SABO_DATA.MaybeAddNewStationSpawn(ply)
		local maybe_spawn_pos = IMPO_SABO_DATA.MaybeGetNewStationSpawnPos(ply)
		
		if maybe_spawn_pos ~= nil then
			local stat_spawn = {}
			stat_spawn.pos = maybe_spawn_pos
			stat_spawn.used = false
			
			IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
			
			for _, ply_i in ipairs(player.GetAll()) do
				if ply_i:GetSubRole() == ROLE_IMPOSTOR then
					--Inform all Impostors of the new station
					net.Start("TTT2ImpostorAddStationToNetwork")
					net.WriteVector(stat_spawn.pos)
					net.WriteBool(stat_spawn.used)
					
					--Force the requesting player to update their selected station spawn to their requested position.
					--...It's probably what they expect to happen.
					if ply:SteamID64() == ply_i:SteamID64() then
						net.WriteBool(true)
					else
						net.WriteBool(false)
					end
					net.Send(ply_i)
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
		if IsValid(IMPO_SABO_DATA.ACTIVE_STAT_ENT) then
			IMPO_SABO_DATA.ACTIVE_STAT_ENT:Remove()
		end
	end
	
	function IMPO_SABO_DATA.CreateExplosion(pos, mag)
		local explosion = ents.Create("env_explosion")
		explosion:SetPos(pos)
		explosion:Spawn()
		--IMagnitude is the amount of damage done by the explosion, as well as the radius.
		explosion:SetKeyValue("IMagnitude", mag)
		explosion:Fire("Explode")
	end
	
	function IMPO_SABO_DATA.RecursiveExplosions()
		timer.Simple(0.3, function()
			if GetRoundState() == ROUND_POST then
				local plys = player.GetAll()
				local victim = plys[math.random(#plys)]
				
				if IsValid(victim) then
					pos = victim:GetPos()
					pos.x = pos.x + math.random(-300, 300)
					pos.y = pos.y + math.random(-300, 300)
					pos.z = pos.z + math.random(-300, 300)
					IMPO_SABO_DATA.CreateExplosion(pos, 100)
				end
				IMPO_SABO_DATA.RecursiveExplosions()
			end
		end)
	end
end

function IMPO_SABO_DATA.SetStrangeGame()
	IMPO_SABO_DATA.STRANGE_GAME = true
	
	if SERVER then
		net.Start("TTT2ImpostorSetStrangeGame")
		net.Broadcast()
		
		local dmg_info = DamageInfo()
		dmg_info:SetDamage(30)
		dmg_info:SetAttacker(IMPO_SABO_DATA.ACTIVE_STAT_ENT)
		dmg_info:SetDamageType(DMG_RADIATION)
		
		for _, ply in ipairs(player.GetAll()) do
			ply:ScreenFade(SCREENFADE.IN, COLOR_WHITE, 1.0, 0.5)
			ply:TakeDamageInfo(dmg_info)
		end
		
		--Destroy the station via giant explosion
		IMPO_SABO_DATA.CreateExplosion(IMPO_SABO_DATA.ACTIVE_STAT_ENT:GetPos(), 500)
		IMPO_SABO_DATA.DestroyStation()
		
		timer.Simple(1.5, function()
			--Plummet civilization into an unending age of explosions
			IMPO_SABO_DATA.RecursiveExplosions()
		end)
	elseif CLIENT then
		local client = LocalPlayer()
		client:ScreenFade(SCREENFADE.IN, COLOR_WHITE, 1.0, 0.5)
	end
end

function IMPO_SABO_DATA.ForceEndSabotage()
	if SERVER then
		timer.Adjust("ImpostorSaboLightsTimer_Server", 0, nil, nil)
		timer.Adjust("ImpostorSaboCommsTimer_Server", 0, nil, nil)
		timer.Adjust("ImpostorSaboO2Timer_Server", 0, nil, nil)
		if timer.Exists("ImpostorSaboReactTimer_Server") then
			timer.Remove("ImpostorSaboReactTimer_Server")
			--Put the sabotage on cooldown here since the usual method (the timer) can't be used without ending the game.
			IMPO_SABO_DATA.DestroyStation()
			IMPO_SABO_DATA.PutSabotageOnCooldown(GetConVar("ttt2_impostor_sabo_react_cooldown"):GetInt())
			
			--Event handling
			events.Trigger(EVENT_IMPO_SABO_SUCCESS, IMPO_SABO_DATA.SABOTAGER, SABO_MODE.REACT)
			IMPO_SABO_DATA.FORCE_END_OCCURRED = nil
			IMPO_SABO_DATA.SABOTAGER = nil
		end
	elseif CLIENT then
		timer.Adjust("ImpostorSaboLightsTimer_Client", 0, nil, nil)
		timer.Adjust("ImpostorSaboCommsTimer_Client", 0, nil, nil)
		timer.Adjust("ImpostorSaboO2Timer_Client", 0, nil, nil)
		if timer.Exists("ImpostorSaboReactTimer_Client") then
			timer.Remove("ImpostorSaboReactTimer_Client")
			LANG.Msg("SABO_REACT_PASS_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
		end
	end
	
	IMPO_SABO_DATA.ACTIVE_STAT_ENT = nil
end

hook.Add("TTTBeginRound", "ImpostorSaboDataBeginRound", function()
	local ply_count = 0
	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsSpec() and not IsInSpecDM(ply) then
			ply_count = ply_count + 1
		end
	end
	
	IMPO_SABO_DATA.THRESHOLD = math.ceil(ply_count * GetConVar("ttt2_impostor_stop_station_ply_prop"):GetFloat())
end)

hook.Add("TTTEndRound", "ImpostorSaboDataEndRound", function()
	--End any existing sabotages, as they may not end during the end round phase, causing issues in the next round.
	--Such as lighting being disabled permanently.
	if SERVER then
		IMPO_SABO_DATA.DestroyStation()
	else
		IMPO_SABO_DATA.ForceEndSabotage()
	end
end)

if CLIENT then
	hook.Add("TTTPrepareRound", "ImpostorSaboDataPrepareRoundForClient", function()
		IMPO_SABO_DATA.STATION_NETWORK = {}
		IMPO_SABO_DATA.ACTIVE_STAT_ENT = nil
		IMPO_SABO_DATA.THRESHOLD = 0
		IMPO_SABO_DATA.STRANGE_GAME = false
	end)
	
	net.Receive("TTT2ImpostorSabotageUpdate", function()
		local sabo_cooldown = net.ReadInt(16)
		
		--print("IMPO_DEBUG TTT2ImpostorSabotageUpdate: sabo_cooldown=" .. sabo_cooldown)
		
		if sabo_cooldown > 0 then
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
	
	net.Receive("TTT2ImpostorSendEntireStationNetwork", function()
		local client = LocalPlayer()
		local network_size = net.ReadInt(16)
		
		--First clear out the network in case it contains stale data.
		IMPO_SABO_DATA.STATION_NETWORK = {}
		
		--print("IMPO_DEBUG TTT2ImpostorSendEntireStationNetwork: Reading station network of size " .. network_size)
		
		for i = 1, network_size do
			local stat_spawn = {}
			stat_spawn.pos = net.ReadVector()
			stat_spawn.used = net.ReadBool()
			
			IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
			
			--print("  stat_spawn[" .. i .. "].pos = <" .. stat_spawn.pos.x .. ", " .. stat_spawn.pos.y .. ", " .. stat_spawn.pos.z .. ">")
		end
		
		--Reset impo_selected_station if needed (Recall that Lua is 1-indexed, not 0-indexed!).
		if client.impo_selected_station == nil then
			client.impo_selected_station = 1
		end
	end)
	
	net.Receive("TTT2ImpostorAddStationToNetwork", function()
		local client = LocalPlayer()
		local stat_spawn = {}
		stat_spawn.pos = net.ReadVector()
		stat_spawn.used = net.ReadBool()
		local was_requesting_ply = net.ReadBool()
		
		IMPO_SABO_DATA.STATION_NETWORK[#IMPO_SABO_DATA.STATION_NETWORK + 1] = stat_spawn
		
		--If the client's selected station is stale (ex. due to only one station spawn being present prior), move to this new one.
		if was_requesting_ply or (not stat_spawn.used and IMPO_SABO_DATA.STATION_NETWORK[client.impo_selected_station].used) then
			client.impo_selected_station = #IMPO_SABO_DATA.STATION_NETWORK
		end
		
		LANG.Msg("SABO_MNGR_CREATE_PASS_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
	end)
	
	net.Receive("TTT2ImpostorSetStrangeGame", function()
		IMPO_SABO_DATA.SetStrangeGame()
	end)
	
	function IMPO_SABO_DATA.CurrentSabotageInProgress()
		if timer.Exists("ImpostorSaboLightsTimer_Client") then
			return SABO_MODE.LIGHTS
		elseif timer.Exists("ImpostorSaboCommsTimer_Client") then
			return SABO_MODE.COMMS
		elseif timer.Exists("ImpostorSaboO2Timer_Client") then
			return SABO_MODE.O2
		elseif timer.Exists("ImpostorSaboReactTimer_Client") then
			return SABO_MODE.REACT
		end
		
		return SABO_MODE.NONE
	end
	
	function IMPO_SABO_DATA.CycleSelectedSabotageStation()
		local client = LocalPlayer()
		local dissuade_station_reuse = GetConVar("ttt2_impostor_dissuade_station_reuse"):GetBool()
		local station_count = #IMPO_SABO_DATA.STATION_NETWORK
		
		--local station_network_str = "[ "
		--for i = 1, #IMPO_SABO_DATA.STATION_NETWORK do
		--	if IMPO_SABO_DATA.STATION_NETWORK[i].used then
		--		station_network_str = station_network_str .. "true "
		--	else
		--		station_network_str = station_network_str .. "false "
		--	end
		--end
		--station_network_str = station_network_str .. "]"
		--print("IMPO_DEBUG CycleSelectedSabotageStation: impo_selected_station = " .. client.impo_selected_station .. ", # stations = " .. #IMPO_SABO_DATA.STATION_NETWORK .. ", station use = " .. station_network_str)
		
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
			
			--print("  impo_selected_station = " .. client.impo_selected_station)
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
		if IsValid(IMPO_SABO_DATA.ACTIVE_STAT_ENT) then
			outline.Add(IMPO_SABO_DATA.ACTIVE_STAT_ENT, IMPOSTOR.color, OUTLINE_MODE_BOTH)
		end
	end)
end