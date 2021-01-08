if SERVER then
	AddCSLuaFile()
end

--Author information
ENT.Author = "BlackMagicFine"
ENT.Contact = "https://steamcommunity.com/profiles/76561198025772353/"

--BMF TryTranslation is not recognized here!
----Name
--ENT.PrintName = LANG.TryTranslation("VENT_NAME_" .. IMPOSTOR.name)
--ENT.Icon = "vgui/ttt/icon_vent"

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_assault/wall_vent.mdl")--"models/weapons/w_slam.mdl") --BMF TODO
ENT.CanHavePrints = true
ENT.CanUseKey = true

--BMF
--AccessorFunc(ENT, "Placer", "Placer") -- using Placer instead of Owner, so everyone can damage the SLAM

hook.Add("TTTPrepareRound", "ClearAllVentEntities", function()
	--If the vents persisted after round end, remove them here.
	for _, vent in pairs(ents.FindByClass("ttt_vent")) do
		vent:Remove()
	end
end)

function ENT:SetupDataTables()
	--BMF TODO
	--self:NetworkVar("Bool", 0, "Defusable") -- same as active on C4, just for defuser compatibility
end

function ENT:Initialize()
	self:SetModel(self.Model)
	
	--Vent is immovable
	--BMF--if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
	--BMF--end
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(false)
	end
	
	if SERVER then
		--SIMPLE_USE ==> ENTITY:Use hook is called once when a player presses the "use" key
		self:SetUseType(SIMPLE_USE)
	end
	
	--Set up fingerprints
	self.fingerprints = {}
	
	if CLIENT then
		local client = LocalPlayer()
		
		if client:GetTeam() ~= TEAM_TRAITOR then
			--Vent starts out as invisible until an impostor interacts with it (so that they can place it in common areas without immediate consequences)
			vent:SetNoDraw(true)
		end
	end
end

--ENT:Use is only called for SERVER. This function does not execute on the CLIENT side.
function ENT:Use(activator, caller, type, value)
	if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() or activator:GetSubRole() ~= ROLE_IMPOSTOR or IsValid(activator.impo_in_vent) then
		return
	end
	
	IMPOSTOR_DATA.EnterVent(activator, self)
end
