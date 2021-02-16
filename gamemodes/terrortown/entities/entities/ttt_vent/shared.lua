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
	
	self:CallOnRemove("VentCallOnRemove", function(vent)
		ent_idx = vent:EntIndex()
		
		--BMF
		print("VentCallOnRemove: Handling destruction of vent with index " .. ent_idx)
		--BMF
		
		--This vent-to-be-destroyed is occupied. Force all players in it out and kill them!
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply.impo_in_vent) and ply.impo_in_vent:EntIndex() == ent_idx then
				IMPO_VENT_DATA.ExitVent(ply)
				if SERVER then
					ply:Kill()
				end
			end
		end
		
		--Remove vent from existence.
		IMPO_VENT_DATA.RemoveVentFromNetwork(ent_idx)
	end)
	
	--Now that the vent has been created, add it to the network so that it may be used.
	IMPO_VENT_DATA.AddVentToNetwork(self, self:GetOwner())
end

--ENT:Use is only called for SERVER. This function does not execute on the CLIENT side.
function ENT:Use(activator, caller, type, value)
	if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then
		return
	end
	
	IMPO_VENT_DATA.EnterVent(activator, self)
end
