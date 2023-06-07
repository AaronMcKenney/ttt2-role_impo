--BMF: Code taken mostly from the Serial Killer's knife. Some adjustments made...

AddCSLuaFile()

SWEP.HoldType = "knife"

if CLIENT then
	SWEP.PrintName = "knife_name"

	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 54
	SWEP.DrawCrosshair = false

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "knife_desc"
	}

	SWEP.Icon = "vgui/ttt/icon_knife"
	SWEP.IconLetter = "j"
end

SWEP.Base = "weapon_tttbase"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"

SWEP.Primary.Damage = 999999
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 1

SWEP.Primary.Ammo = ''
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1

SWEP.Secondary.Ammo = ''
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.ClipMax = 1
SWEP.Secondary.DefaultClip = 1

SWEP.Kind = WEAPON_SPECIAL
SWEP.CanBuy = nil
SWEP.notBuyable = true
SWEP.AllowDrop = false

SWEP.IsSilent = true

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if not IsValid(self:GetOwner()) then return end

	self:GetOwner():LagCompensation(true)

	local spos = self:GetOwner():GetShootPos()
	local sdest = spos + (self:GetOwner():GetAimVector() * 70)

	local kmins = Vector(1, 1, 1) * -10
	local kmaxs = Vector(1, 1, 1) * 10

	local tr = util.TraceHull({start = spos, endpos = sdest, filter = self:GetOwner(), mask = MASK_SHOT_HULL, mins = kmins, maxs = kmaxs})

	-- Hull might hit environment stuff that line does not hit
	if not IsValid(tr.Entity) then
		tr = util.TraceLine({start = spos, endpos = sdest, filter = self:GetOwner(), mask = MASK_SHOT_HULL})
	end

	local hitEnt = tr.Entity

	-- effects
	if IsValid(hitEnt) then
		self:SendWeaponAnim(ACT_VM_HITCENTER)

		local edata = EffectData()
		edata:SetStart(spos)
		edata:SetOrigin(tr.HitPos)
		edata:SetNormal(tr.Normal)
		edata:SetEntity(hitEnt)

		if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
			self:GetOwner():SetAnimation(PLAYER_ATTACK1)

			self:SendWeaponAnim(ACT_VM_MISSCENTER)

			util.Effect("BloodImpact", edata)
		end
	else
		self:SendWeaponAnim(ACT_VM_MISSCENTER)
	end

	if SERVER then
		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	end

	if SERVER and tr.Hit and tr.HitNonWorld and IsValid(hitEnt) and hitEnt:IsPlayer() then
		-- knife damage is never karma'd, so don't need to take that into
		-- account we do want to avoid rounding error strangeness caused by
		-- other damage scaling, causing a death when we don't expect one, so
		-- when the target's health is close to kill-point we just kill
		self:StabKill(tr, spos, sdest)

		self:GetOwner():LagCompensation(false)
		
		--This must be the last thing we do if the instant kill was successful, as it will remove this weapon.
		TTT2ImpostorPutInstantKillOnCooldown(self:GetOwner())
	else
		self:GetOwner():LagCompensation(false)
	end
end

function SWEP:StabKill(tr, spos, sdest)
	local target = tr.Entity

	local dmg = DamageInfo()
	dmg:SetDamage(self.Primary.Damage)
	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	dmg:SetDamageForce(self:GetOwner():GetAimVector())
	dmg:SetDamagePosition(self:GetOwner():GetPos())
	dmg:SetDamageType(DMG_SLASH)

	-- BMF NOTE: Rest of this code appears to be used to apply physics after the killing blow occurs...
	
	-- now that we use a hull trace, our hitpos is guaranteed to be
	-- terrible, so try to make something of it with a separate trace and
	-- hope our effect_fn trace has more luck

	-- first a straight up line trace to see if we aimed nicely
	local retr = util.TraceLine({start = spos, endpos = sdest, filter = self:GetOwner(), mask = MASK_SHOT_HULL})

	-- if that fails, just trace to worldcenter so we have SOMETHING
	if retr.Entity ~= target then
		local center = target:LocalToWorld(target:OBBCenter())

		retr = util.TraceLine({start = spos, endpos = center, filter = self:GetOwner(), mask = MASK_SHOT_HULL})
	end

	-- create knife effect creation fn
	local bone = retr.PhysicsBone
	local pos = retr.HitPos
	local norm = tr.Normal

	local ang = Angle(-28, 0, 0) + norm:Angle()
	ang:RotateAroundAxis(ang:Right(), -90)

	pos = pos - (ang:Forward() * 7)

	local ignore = self:GetOwner()

	target.effect_fn = function(rag)
		-- we might find a better location
		local rtr = util.TraceLine({start = pos, endpos = pos + norm * 40, filter = ignore, mask = MASK_SHOT_HULL})

		if IsValid(rtr.Entity) and rtr.Entity == rag then
			bone = rtr.PhysicsBone
			pos = rtr.HitPos
			ang = Angle(-28, 0, 0) + rtr.Normal:Angle()
			ang:RotateAroundAxis(ang:Right(), -90)
			pos = pos - (ang:Forward() * 10)
		end

		local knife = ents.Create("prop_physics")
		knife:SetModel("models/weapons/w_knife_t.mdl")
		knife:SetPos(pos)
		knife:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		knife:SetAngles(ang)

		knife.CanPickup = false

		knife:Spawn()

		local phys = knife:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableCollisions(false)
		end

		constraint.Weld(rag, knife, bone, 0, 0, true)

		-- need to close over knife in order to keep a valid ref to it
		rag:CallOnRemove("ttt_knife_cleanup", function()
			SafeRemoveEntity(knife)
		end)
	end

	-- seems the spos and sdest are purely for effects/forces?
	target:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)

	-- target appears to die right there, so we could theoretically get to
	-- the ragdoll in here...
end

function SWEP:SecondaryAttack(worldsnd)
	self:PrimaryAttack()
end

function SWEP:OnDrop()
	self:Remove()
end

if CLIENT then
	function SWEP:Initialize()
		self:AddTTT2HUDHelp("ttt2_role_sk_knife_primary", "ttt2_role_sk_knife_secondary", true)

		return self.BaseClass.Initialize(self)
	end
end