if SERVER then
	AddCSLuaFile()
end

--Author information
ENT.Author = "BlackMagicFine"
ENT.Contact = "https://steamcommunity.com/profiles/76561198025772353/"

ENT.Type = "anim"
ENT.Model = Model("models/props_combine/CombineThumper002.mdl")
ENT.CanHavePrints = true
ENT.CanUseKey = true

--How many players currently in range of stopping the sabotage.
--Used both for calculations and for visual presentation.
local num_plys_in_range = 0

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

function ENT:Initialize()
	self.removal_in_progress = false
	
	self:SetModel(self.Model)
	local model_scale = 0.75
	self:SetModelScale(self:GetModelScale() * model_scale)
	local min_bound_vec, max_bound_vec = self:GetCollisionBounds()
	self:SetCollisionBounds(model_scale * min_bound_vec, model_scale * max_bound_vec)
	local color = self:GetColor()
	color.a = 178
	self:SetColor(color)
	--Needed in order to make the station transparent.
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	
	--Station is immovable, but has no collision (to prevent impostors from both using it to trap people and using it like some sort of shield.
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	--Set up fingerprints
	self.fingerprints = {}
	
	self:CallOnRemove("SaboStationCallOnRemove", function(ent)
		IMPO_SABO_DATA.ForceEndSabotage()
		IMPO_SABO_DATA.ACTIVE_STAT_ENT = nil
	end)
	
	IMPO_SABO_DATA.ACTIVE_STAT_ENT = self
end

function ENT:GetCenter()
	local center = self:GetPos() + self:OBBCenter()
	center.z = self:GetPos().z + 5
	
	return center
end

--Called on the Server to check if the sabotage can end prematurely.
--Called on the Client to visually indicate sabotage progress. 
function ENT:Think()
	local radius = GetConVar("ttt2_impostor_station_radius"):GetInt()
	local hold_time = GetConVar("ttt2_impostor_station_hold_time"):GetInt()
	local radius_sqrd = radius * radius
	local new_num_plys_in_range = 0
	local center = self:GetCenter()
	
	for _, ply in ipairs(player.GetAll()) do
		local ply_pos = ply:GetPos() + ply:OBBCenter()
		if ply:IsTerror() and ply:Alive() and not IsInSpecDM(ply) and ply_pos:DistToSqr(center) <= radius_sqrd then
			new_num_plys_in_range = new_num_plys_in_range + 1
		end
	end
	
	num_plys_in_range = new_num_plys_in_range
	if num_plys_in_range >= IMPO_SABO_DATA.THRESHOLD then
		if not timer.Exists("ImpostorSaboStationEndProtocolInProgress") then
			timer.Create("ImpostorSaboStationEndProtocolInProgress", hold_time, 1, function()
				self.removal_in_progress = true
				if SERVER then
					IMPO_SABO_DATA.DestroyStation()
				end
			end)
		end
	else
		timer.Remove("ImpostorSaboStationEndProtocolInProgress")
	end
	
	--This technically works, but only if the map's lighting isn't fully disabled.
	--Even setting the LightStyle to "b" will dimish SabotageLight's already underpowered effect.
	--So this shall be commented for now.
	--if CLIENT and IMPO_SABO_DATA.CurrentSabotageInProgress() == SABO_MODE.LIGHTS then
	--	--Create dynamic light
	--	local dlight = DynamicLight(self:EntIndex())
	--	--Beacon's color
	--	dlight.r = 255
	--	dlight.g = 255
	--	dlight.b = 153
	--	
	--	dlight.brightness = 10
	--	dlight.Decay = 1000
	--	dlight.Size = 200
	--	dlight.DieTime = CurTime() + 0.1
	--	dlight.Pos = self:GetPos() + Vector(0, 0, 120)
	--end
end

if CLIENT then
	local sabo_station_floor_mat = Material("vgui/ttt/circle")
	local sabo_station_arrow_mat = Material("vgui/ttt/arrow")
	
	surface.CreateFont("ImpostorSabotageStationFont", {
		font = "Arial",
		size = 100,
		weight = 1000,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false
	})
	
	local function GetTimeLeftFromSaboClient()
		local time_left = 0
		
		if timer.Exists("ImpostorSaboLightsTimer_Client") then
			time_left = math.ceil(math.abs(timer.TimeLeft("ImpostorSaboLightsTimer_Client")))
		elseif timer.Exists("ImpostorSaboCommsTimer_Client") then
			time_left = math.ceil(math.abs(timer.TimeLeft("ImpostorSaboCommsTimer_Client")))
		elseif timer.Exists("ImpostorSaboO2Timer_Client") then
			time_left = math.ceil(math.abs(timer.TimeLeft("ImpostorSaboO2Timer_Client")))
		elseif timer.Exists("ImpostorSaboReactTimer_Client") then
			time_left = math.ceil(math.abs(timer.TimeLeft("ImpostorSaboReactTimer_Client")))
		end
		
		return time_left
	end
	
	function ENT:Draw()
		local client = LocalPlayer()
		self:DrawModel()
		
		--Info
		local time_left = GetTimeLeftFromSaboClient()
		
		--Info box's size is mostly hardcoded to be just enough to hold the text.
		local info_box_width = 250
		local info_box_height = 200
		
		--Create a screen that follows the player, which displays the time left.
		--Make the angle face in the opposite direction the client is looking
		local dist_vec = client:GetPos() - self:GetPos()
		local ang = dist_vec:Angle()
		--We only care about the yaw that's changed from the above function, which spins the screen on a lazy susan.
		--Roll and pitch must be constant values to prevent the screen from completely mirroring the player's camera.
		--Set to 0 for now to make info box position less of a pain to calculate
		ang.r = 0
		ang.p = 0
		
		--Screen position is hardcoded mostly due to the lack of radial symmetry in the model.
		local info_box_pos = self:GetPos() + self:OBBCenter()
		--Center the info_box across the XY-plane through arduous hardcoding.
		--Top-left point of info_box (seen as a dot on the base of the model) prior to centering is illustrated below
		-- ___    x-axis is positive to the right, y-axis is positive up.
		--/.  \
		--_____
		info_box_pos.x = info_box_pos.x + 4
		info_box_pos.y = info_box_pos.y - 6
		--Larger z addition to put the screen near the top of the model.
		info_box_pos.z = info_box_pos.z + 110
		--Now that it is properly centered, we can move the screen "left" from the player's perspective, to align it with the model.
		info_box_pos = info_box_pos + 12 * ang:Right()
		--Make the screen protude outwards from the model.
		info_box_pos = info_box_pos + 25 * ang:Forward()
		
		--Modify the yaw post position calculation because the screen is otherwise drawn along the dist_vec axis.
		ang.y = ang.y + 90
		--Set roll such that the screen faces downwards at a tilt.
		ang.r = 120
		
		--Draw a screen
		cam.Start3D2D(info_box_pos, ang, 0.1)
			draw.RoundedBox(0, 0, 0, info_box_width, info_box_height, IMPOSTOR.color)
			draw.SimpleText(time_left, "ImpostorSabotageStationFont", info_box_width / 2, info_box_height / 2, COLOR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
	
	hook.Add("PostDrawTranslucentRenderables", "PostDrawTranslucentRenderablesSabotageStation", function()
		if IsValid(IMPO_SABO_DATA.ACTIVE_STAT_ENT) then
			--Draw a rotating circle under the sabotage station, to indicate its range
			local diameter = GetConVar("ttt2_impostor_station_radius"):GetInt() * 2
			local cur_time = CurTime()
			local center = IMPO_SABO_DATA.ACTIVE_STAT_ENT:GetCenter()
			--Create new color here. Using COLOR_RED will make a shallow copy and change it.
			--Alpha value of 177- is invisible, 178+ is visible. 178 is partially transparent. Not sure why.
			local sabo_station_color = Color(255, 0, 0, 178)
			if IMPO_SABO_DATA.ACTIVE_STAT_ENT.removal_in_progress then
				sabo_station_color = Color(113, 188, 120, 178) --Fern green. Hopefully different enough for colorblined.
			elseif timer.Exists("ImpostorSaboStationEndProtocolInProgress") then
				--Interpolation from red to green.
				local success_color = Color(113, 188, 120, 178)
				local hold_time = GetConVar("ttt2_impostor_station_hold_time"):GetInt()
				local time_left = timer.TimeLeft("ImpostorSaboStationEndProtocolInProgress")
				local fract = (hold_time - time_left) / hold_time
				sabo_station_color.r = sabo_station_color.r + fract * (success_color.r - sabo_station_color.r)
				sabo_station_color.g = sabo_station_color.g + fract * (success_color.g - sabo_station_color.g)
				sabo_station_color.b = sabo_station_color.b + fract * (success_color.b - sabo_station_color.b)
			end
			
			render.SetMaterial(sabo_station_floor_mat)
			render.DrawQuadEasy(center, Vector(0, 0, 1), diameter, diameter, sabo_station_color, 0)
			
			--Draw an arrow for each player needed. Color the arrows based on how many are in range.
			render.SetMaterial(sabo_station_arrow_mat)
			for i = 1, IMPO_SABO_DATA.THRESHOLD do
				local arrow_color = Color(255, 0, 0, 178)
				if i <= num_plys_in_range then
					arrow_color = Color(113, 188, 120, 178)
				end
				
				local arrow_rot = (50 * cur_time + (360 * i) / IMPO_SABO_DATA.THRESHOLD) % 360
				render.DrawQuadEasy(center, Vector(0, 0, 1), diameter, diameter, arrow_color, arrow_rot)
			end
		end
	end)
end