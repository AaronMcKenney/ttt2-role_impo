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

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

function ENT:Initialize()
	self:SetModel(self.Model)
	
	--Station is immovable, but has no collision (to prevent impostors from both using it to trap people and using it like some sort of shield.
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	--Set up fingerprints
	self.fingerprints = {}
	
	self:CallOnRemove("SaboStationCallOnRemove", function(ent)
		IMPO_SABO_DATA.ForceEndSabotage()
		IMPO_SABO_DATA.ACTIVE_SABO_ENT = nil
	end)
	
	IMPO_SABO_DATA.ACTIVE_SABO_ENT = self
end

--Called on the Server to check if the sabotage can end prematurely.
--Called on the Client to visually indicate sabotage progress. 
function ENT:Think()
	if IsValid(IMPO_SABO_DATA.ACTIVE_SABO_ENT) then
		local radius = GetConVar("ttt2_impostor_station_radius"):GetInt()
		local hold_time = GetConVar("ttt2_impostor_station_hold_time"):GetInt()
		local radius_sqrd = radius * radius
		local num_plys_in_range = 0
		local ply_count = 0
		
		for _, ply in ipairs(player.GetAll()) do
			--Do not count players who have joined in the middle of a round.
			if not (ply:IsSpec() and ply:Alive()) then
				ply_count = ply_count + 1
			end
			
			if ply:IsTerror() and ply:Alive() and not IsInSpecDM(ply) and ply:GetPos():DistToSqr(IMPO_SABO_DATA.ACTIVE_SABO_ENT:GetPos()) <= radius_sqrd then
				num_plys_in_range = num_plys_in_range + 1
			end
		end
		
		local threshold = math.ceil(ply_count * GetConVar("ttt2_impostor_stop_station_ply_prop"):GetFloat())
		
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