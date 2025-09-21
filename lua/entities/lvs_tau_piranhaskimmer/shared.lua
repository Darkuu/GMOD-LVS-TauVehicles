ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "TX4 Piranha Skimmer "
ENT.Author = "Darku"
ENT.Information = "A type of lightly armoured combat scout skimmer used by the Tau Fire Caste"
ENT.Category = "[LVS] - Tau"

ENT.VehicleCategory = "Tau"
ENT.VehicleSubCategory = "Hover Speeder"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/tau/piranhaskimmer/piranhaskimmer.mdl"
ENT.GibModels = {
	"models/gibs/helicopter_brokenpiece_01.mdl",
	"models/gibs/helicopter_brokenpiece_02.mdl",
	"models/gibs/helicopter_brokenpiece_03.mdl",
	"models/combine_apc_destroyed_gib02.mdl",
	"models/combine_apc_destroyed_gib04.mdl",
	"models/combine_apc_destroyed_gib05.mdl",
	"models/props_c17/trappropeller_engine.mdl",
	"models/gibs/airboat_broken_engine.mdl",
}

ENT.AITEAM = 1

ENT.MaxHealth = 2000

ENT.ForceAngleMultiplier = 2
ENT.ForceAngleDampingMultiplier = 1

ENT.ForceLinearMultiplier = 1
ENT.ForceLinearRate = 0.25

ENT.MaxVelocityX = 1080
ENT.MaxVelocityY = 1080

ENT.MaxTurnRate = 2

ENT.BoostAddVelocityX = 520
ENT.BoostAddVelocityY = 520

ENT.GroundTraceHitWater = true
ENT.GroundTraceLength = 150
ENT.GroundTraceHull = 150


function ENT:OnSetupDataTables()
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Entity", "GunnerSeat" )
end

function ENT:SetTurretPitch( num )
	self._turretPitch = num
end

function ENT:SetTurretYaw( num )
	self._turretYaw = num
end

function ENT:GetTurretPitch()
	return (self._turretPitch or 0)
end

function ENT:GetTurretYaw()
	return (self._turretYaw or 0)
end

function ENT:GetAimAngles()
	local trace = self:GetEyeTrace()

	local AimAnglesR = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(10,-60,81) ) ):GetNormalized():Angle() )
	local AimAnglesL = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(10,60,81) ) ):GetNormalized():Angle() )

	return AimAnglesR, AimAnglesL
end

function ENT:WeaponsInRange()
	if self:GetIsCarried() then return false end

	local AimAnglesR, AimAnglesL = self:GetAimAngles()

	return not ((AimAnglesR.p >= 10 and AimAnglesL.p >= 10) or (AimAnglesR.p <= -10 and AimAnglesL.p <= -10) or (math.abs(AimAnglesL.y) + math.abs(AimAnglesL.y)) >= 90)
end


function ENT:InitWeapons()
-- Gun Drones (Dual-Barrel per side)
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 600
	weapon.Delay = 0.2
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.25
	weapon.Attack = function(ent)
		if not ent:WeaponsInRange() then return true end

		-- Define two barrels per side
		local LeftBarrels = {
			Vector(-75, 155, 0),  -- Outer left
			Vector(-75, 125, 0),  -- Inner left
		}
		local RightBarrels = {
			Vector(-75, -155, 0), -- Outer right
			Vector(-75, -125, 0), -- Inner right
		}

		local function FireBarrel(PosLocal)
			local Pos = ent:LocalToWorld(PosLocal)
			local Trace = ent:GetEyeTrace()
			local Dir = (Trace.HitPos - Pos):GetNormalized()

			local bullet = {}
			bullet.Src = Pos
			bullet.Dir = Dir
			bullet.Spread = Vector(0.01, 0.01, 0)
			bullet.TracerName = "lvs_laser_blue_short"
			bullet.Force = 11000
			bullet.HullSize = 1
			bullet.Damage = 25
			bullet.Velocity = 12000
			bullet.Attacker = ent:GetDriver()
			bullet.Callback = function(att, tr, dmginfo)
				local effectdata = EffectData()
				effectdata:SetStart(Vector(255, 50, 50))
				effectdata:SetOrigin(tr.HitPos)
				effectdata:SetNormal(tr.HitNormal)
				util.Effect("lvs_laser_impact", effectdata)
			end

			ent:LVSFireBullet(bullet)

			local effectdata = EffectData()
			effectdata:SetStart(Vector(255, 50, 50))
			effectdata:SetOrigin(bullet.Src)
			effectdata:SetNormal(Dir)
			effectdata:SetEntity(ent)
			util.Effect("lvs_muzzle_colorable", effectdata)
		end

		-- Fire all barrels
		for _, pos in ipairs(LeftBarrels) do
			FireBarrel(pos)
		end

		for _, pos in ipairs(RightBarrels) do
			FireBarrel(pos)
		end

		ent:TakeAmmo()

		-- Play main sound once per side
		ent.PrimarySND:PlayOnce(100 + math.cos(CurTime() + ent:EntIndex() * 1337) * 5 + math.Rand(-1, 1), 1)

		if IsValid(ent.SNDLeft) then ent.SNDLeft:PlayOnce() end
		if IsValid(ent.SNDRight) then ent.SNDRight:PlayOnce() end
	end

	weapon.OnSelect = function(ent)
		ent:EmitSound("physics/metal/weapon_impact_soft3.wav")
	end

	weapon.OnOverheat = function(ent)
		ent:EmitSound("lvs/vehicles/general/overheat.mp3")
	end

	weapon.OnThink = function(ent, active)
		if ent:GetIsCarried() then
			ent:SetPoseParameter("cannon_right_pitch", 0)
			ent:SetPoseParameter("cannon_right_yaw", 0)
			ent:SetPoseParameter("cannon_left_pitch", 0)
			ent:SetPoseParameter("cannon_left_yaw", 0)
			return
		end

		local AimAnglesR, AimAnglesL = ent:GetAimAngles()
		ent:SetPoseParameter("cannon_right_pitch", AimAnglesR.p)
		ent:SetPoseParameter("cannon_right_yaw", AimAnglesR.y)
		ent:SetPoseParameter("cannon_left_pitch", AimAnglesL.p)
		ent:SetPoseParameter("cannon_left_yaw", AimAnglesL.y)
	end

	self:AddWeapon(weapon)

	-- Fusion Blaster 
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 100               
	weapon.Delay = 1.5              
	weapon.HeatRateUp = 0.5
	weapon.HeatRateDown = 0.2

	weapon.Attack = function(ent)
		if not ent:WeaponsInRange() then return true end

		local BarrelPosLocal = Vector(0, 0, 0)
		local Pos = ent:LocalToWorld(BarrelPosLocal)

		local Trace = ent:GetEyeTrace()
		local Dir = (Trace.HitPos - Pos):GetNormalized()

		local bullet = {}
		bullet.Src = Pos
		bullet.Dir = Dir
		bullet.Spread = Vector(0.01, 0.01, 0)
		bullet.TracerName = "lvs_laser_blue_long"
		bullet.Force = 11000
		bullet.HullSize = 10
		bullet.Damage = 500
		bullet.Velocity = 7000
		bullet.Attacker = ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
			effectdata:SetStart(Vector(100, 200, 255)) 
			effectdata:SetOrigin(tr.HitPos)
			effectdata:SetNormal(tr.HitNormal)
			util.Effect("lvs_laser_impact", effectdata)

			util.Decal("FadingScorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
		end

		ent:LVSFireBullet(bullet)

		local effectdata = EffectData()
		effectdata:SetStart(Vector(100, 200, 255))
		effectdata:SetOrigin(Pos)
		effectdata:SetNormal(Dir)
		effectdata:SetEntity(ent)
		util.Effect("lvs_muzzle_colorable", effectdata)

		ent:TakeAmmo()
		ent.PrimarySND:PlayOnce(90 + math.Rand(-2, 2), 1)
	end

	weapon.OnSelect = function(ent)
		ent:EmitSound("physics/metal/weapon_impact_hard3.wav")
	end

	weapon.OnOverheat = function(ent)
		ent:EmitSound("ambient/energy/zap9.wav")
	end

	weapon.OnThink = function(ent, active)
		if ent:GetIsCarried() then
			ent:SetPoseParameter("cannon_pitch", 0)
			ent:SetPoseParameter("cannon_yaw", 0)
			return
		end
		local AimAngles = ent:GetAimAngles()
		ent:SetPoseParameter("cannon_pitch", AimAngles.p)
		ent:SetPoseParameter("cannon_yaw", AimAngles.y)
	end
	self:AddWeapon(weapon)
end


ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/piranha/loop.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 85,
	},
	{
		sound = "lvs/vehicles/piranha/loop_hi.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 85,
	},
	{
		sound = "^lvs/vehicles/piranha/dist.wav",
		Pitch = 70,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 30,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		SoundLevel = 90,
	},
}

