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
ENT.Model = Model("models/props/cs_assault/wall_vent.mdl")
ENT.CanHavePrints = true
ENT.CanUseKey = true

hook.Add("TTTPrepareRound", "ClearAllVentEntities", function()
	--If the vents persisted after round end, remove them here.
	for _, vent in pairs(ents.FindByClass("ttt_vent")) do
		vent:Remove()
	end
end)

function ENT:Initialize()
	self:SetModel(self.Model)
	
	--Vent is immovable
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
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
	
	if GetConVar("ttt2_impostor_hide_unused_vents"):GetBool() then
		--Vent starts out as invisible until an impostor interacts with it (so that they can place it in common areas without immediate consequences)
		self:SetNoDraw(true)
	end
	
	--Now that the vent has been created, add it to the network so that it may be used.
	IMPOSTOR_DATA.AddVentToNetwork(self, self:GetOwner())
end

--ENT:Use is only called for SERVER. This function does not execute on the CLIENT side.
function ENT:Use(activator, caller, type, value)
	if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then
		return
	end
	
	IMPOSTOR_DATA.EnterVent(activator, self)
end
