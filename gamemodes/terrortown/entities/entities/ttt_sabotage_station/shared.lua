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
local threshold = 0

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

hook.Add("TTTBeginRound", "ImpostorSabotatgeStationBeginRound", function()
	local ply_count = 0
	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsSpec() and not IsInSpecDM(ply) then
			ply_count = ply_count + 1
		end
	end
	
	threshold = math.ceil(ply_count * GetConVar("ttt2_impostor_stop_station_ply_prop"):GetFloat())
end)

function ENT:Initialize()
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

--Called on the Server to check if the sabotage can end prematurely.
--Called on the Client to visually indicate sabotage progress. 
function ENT:Think()
	if IsValid(IMPO_SABO_DATA.ACTIVE_STAT_ENT) then
		local radius = GetConVar("ttt2_impostor_station_radius"):GetInt()
		local hold_time = GetConVar("ttt2_impostor_station_hold_time"):GetInt()
		local radius_sqrd = radius * radius
		local new_num_plys_in_range = 0
		
		for _, ply in ipairs(player.GetAll()) do
			if ply:IsTerror() and ply:Alive() and not IsInSpecDM(ply) and ply:GetPos():DistToSqr(IMPO_SABO_DATA.ACTIVE_STAT_ENT:GetPos()) <= radius_sqrd then
				new_num_plys_in_range = new_num_plys_in_range + 1
			end
		end
		
		num_plys_in_range = new_num_plys_in_range
		if num_plys_in_range >= threshold then
			if not timer.Exists("ImpostorSaboStationEndProtocolInProgress") then
				timer.Create("ImpostorSaboStationEndProtocolInProgress", hold_time, 1, function()
					if SERVER then
						IMPO_SABO_DATA.DestroyStation()
					end
				end)
			end
		else
			timer.Remove("ImpostorSaboStationEndProtocolInProgress")
		end
	end
end

if CLIENT then
	--Note: This is a pretty crappy material to use. Probably should find and use a crisper version.
	local sabo_station_floor_mat = Material("sprites/sent_ball")
	
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
	
	function ENT:Draw()
		self:DrawModel()
		
		--Info
		local text_size = 100
		local time_left = GetTimeLeftFromSaboClient()
		
		--Info box's size is mostly hardcoded to be just enough to hold the text.
		local info_box_width = 300
		local info_box_height = 400
		
		--Create three screens that display the same info, all surrounding the sabotage station.
		for i = 1, 3 do
			local ang = self:GetAngles()
			--Makes the screen's text face "forward"
			ang:RotateAroundAxis(self:GetAngles():Right(), 90)
			ang:RotateAroundAxis(self:GetAngles():Forward(), 90)
			--Tilts the screen down toward the players.
			ang:RotateAroundAxis(self:GetAngles():Right(), 45)
			--Allows for each screen to face a different direction.
			ang:RotateAroundAxis(self:GetAngles():Up(), 120 * (i - 1))
			
			--Calculating the exact position of each screen is annoying.
			local info_box_pos = self:GetPos()
			local min_bound_vec, max_bound_vec = self:GetCollisionBounds()
			--Larger z addition higher the screen is.
			info_box_pos.z = info_box_pos.z + 150
			--Align the x/y position in the dead middle of the entity.
			info_box_pos.x = info_box_pos.x + (max_bound_vec.x - min_bound_vec.x) / 2
			info_box_pos.y = info_box_pos.y - (max_bound_vec.y - min_bound_vec.y) / 2
			--Make the screen "protude" out of the dead middle of the entity.
			local protude_vec = ang:Right()
			protude_vec.z = 0
			info_box_pos = info_box_pos - 60 * protude_vec
			--Move the screen slightly to the "left"
			local left_vec = ang:Forward()
			left_vec.z = 0
			info_box_pos = info_box_pos - 15 * left_vec
			
			--Draw a screen
			cam.Start3D2D(info_box_pos, ang, 0.1)
				draw.RoundedBox(0, 0, 0, info_box_width, info_box_height, IMPOSTOR.color)
				draw.SimpleText(time_left, "ImpostorSabotageStationFont", info_box_width / 2, (info_box_height - text_size) / 2, COLOR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(num_plys_in_range .. "/" .. threshold, "ImpostorSabotageStationFont", info_box_width / 2, (info_box_height + text_size) / 2, COLOR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			cam.End3D2D()
		end
	end
	
	hook.Add("PostDrawTranslucentRenderables", "PostDrawTranslucentRenderablesSabotageStation", function()
		if IsValid(IMPO_SABO_DATA.ACTIVE_STAT_ENT) then
			--Draw a rotating circle under the sabotage station, to indicate its range
			local diameter = GetConVar("ttt2_impostor_station_radius"):GetInt() * 2
			local cur_time = CurTime()
			local sabo_station_pos = IMPO_SABO_DATA.ACTIVE_STAT_ENT:GetPos()
			local sabo_station_color = COLOR_RED
			if timer.Exists("ImpostorSaboStationEndProtocolInProgress") then
				sabo_station_color = COLOR_GREEN
			end
			-- 177- is invisible, 178+ is visible. 178 is partially transparent. Not sure why.
			sabo_station_color.a = 178
			
			render.SetMaterial(sabo_station_floor_mat)
			render.DrawQuadEasy(sabo_station_pos + Vector(0, 0, 1), Vector(0, 0, 1), diameter, diameter, sabo_station_color, (cur_time * 50) % 360)
		end
	end)
end