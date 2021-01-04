if SERVER then
	AddCSLuaFile()
end

if CLIENT then
	SWEP.PrintName = LANG.TryTranslation("VENT_NAME_" .. IMPOSTOR.name)
	SWEP.Icon = "vgui/ttt/icon_vent"
	
	SWEP.UseHands = true
	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 10
	SWEP.DrawCrosshair = false
	
	--Equipment menu information is only needed on the client
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = LANG.TryTranslation("VENT_DESC_" .. IMPOSTOR.name)
	}
end

--Author information
SWEP.Author = "BlackMagicFine"
SWEP.Contact = "https://steamcommunity.com/profiles/76561198025772353/"

--Always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

--Default GMod values
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.25
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = GetConVar("ttt2_impostor_num_starting_vents"):GetInt()
SWEP.Primary.ClipSize = GetConVar("ttt2_impostor_num_starting_vents"):GetInt()
SWEP.Secondary.Delay = 0.5
SWEP.FiresUnderwater = false

--Model settings
SWEP.HoldType = "slam"
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props_lab/reciever01b.mdl"

--[[TTT config values]]--

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EXTRA

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2,
-- then this gun can be spawned as a random weapon.
SWEP.AutoSpawnable = false

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = "none"

--CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
--a role is in this table, those players can buy this.
--nil means no one can buy this.
SWEP.CanBuy = nil

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = true

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = false

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = true

function SWEP:SetupDataTables()
	--This function can be used to set up network data. It is called upon an entity's creation.
	self:NetworkVar("Vector", 0, "PlayerSpawnShift")
	
	--BMF
	--if SERVER then
	--	local ply = self:GetOwner()
	--	--BMF TODO: Spawn shift is the difference between the player's position and the ENTITTY's position!
	--	--Below fails due to self referring to the weapon and not the entity.
	--	--self:SetPlayerSpawnShift(ply:GetPos() - self:GetPos())
	--end
end

function SWEP:Initialize()
	--No initializing
end

function SWEP:PrimaryAttack()
	if self:CanPrimaryAttack() and self:GetNextPrimaryFire() <= CurTime() then
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
		
		if SERVER then
			self:StickVent()
		end
	end
end

if SERVER then
	function SWEP:PlacedVent()
		--Reduce ammo count now that the vent has been placed.
		self:TakePrimaryAmmo(1)
		
		--Remove the vent weapon if there's no more vents to be placed.
		if not self:CanPrimaryAttack() then
			self:Remove()
		end
	end
	
	function SWEP:TraceLineForVent()
		local tr = nil
		
		if (IsValid(self)) then
			local ply = self:GetOwner()
			
			if (IsValid(ply)) then
				local CheckFilter = function(ent)
					--Can't place vent on invalid entities and players
					if not IsValid(ent) or ent:IsPlayer() then
						return false
					end
					
					--Can't place vent on itself
					if ent == self then
						return false
					end
					
					--Can't place vent on entities that players can walk through.
					if ent:HasPassableCollisionGrup() then
						return false
					end
					
					return true
				end
				local spos = ply:GetShootPos()
				--Arbitrary magic number for how far we can place the vent from ourselves.
				local vent_placement_range = 84
				local epos = spos + ply:GetAimVector() * vent_placement_range
				tr = util.TraceLine({
					start = spos,
					endpos = epos,
					filter = CheckFilter,
					mask = MASK_SOLID
				})
			end
		end
		
		return tr
	end

	function SWEP:StickVent()
		local ply = self:GetOwner()
		if not IsValid(ply) then
			return
		end
		
		local tr = self:TraceLineForVent()
		--Explicitly check if the player's current position is safe for exiting from this potential vent.
		local is_spawn_point_safe = spawn.IsSpawnPointSafe(ply, ply:GetPos(), false, player.GetAll())
		local vent_was_placed = false
		
		if tr.HitWorld and is_spawn_point_safe then
			local vent = ents.Create("ttt_vent")
			if IsValid(vent) then
				--Make the vent point away from the surface
				vent:SetPos(tr.HitPos)
				vent:SetAngles(tr.HitNormal:Angle())
				vent:SetOwner(ply)
				vent:Spawn()
				
				vent.fingerprints = self.fingerprints
				
				IMPOSTOR_DATA.AddVentToNetwork(vent, ply, tr)
				
				self:PlacedVent()
				vent_was_placed = true
				return
			end
		end
		
		LANG.Msg(ply, "VENT_CANNOT_PLACE_" .. IMPOSTOR.name, nil, MSG_MSTACK_WARN)
	end
end

--Called when the player has switched to this weapon
function SWEP:Deploy()
	--Do not draw the view model.
	self:GetOwner():DrawViewModel(false)
	
	return true
end

function SWEP:DrawWorldModel()
	--Do not draw the world model if the owner exists.
	if IsValid(self:GetOwner()) then
		return
	end
	
	self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
end

function SWEP:Reload()
	--Reload does nothing
end

--Can't drop weapon, so this ought to do nothing.
--But if for some reason a drop is attempted, remove the vents as a sanity check.
--Vents are supposed to be used for setup only, and the potential benefit of a fellow impostor picking
--up unused vents is outweighed by potential edge cases involving other roles picking up the vents.
function SWEP:OnDrop()
	self:Remove()
end

if CLIENT then
	function SWEP:Initialize()
		self:AddTTT2HUDHelp("VENT_PRIMARY_DESC_" .. IMPOSTOR.name)

		return self.BaseClass.Initialize(self)
	end
	
	function SWEP:OnRemove()
		local ply = self:GetOwner()
		if not IsValid(ply) or ply ~= LocalPlayer() or not ply:Alive() then
			return
		end
		
		--Makes the player switch to the previous weapon they were using.
		RunConsoleCommand("lastinv")
	end
end
