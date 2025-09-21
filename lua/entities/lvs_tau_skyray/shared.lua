ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "TX78 Sky Ray"
ENT.Author = "Darku"
ENT.Information = "A edicated missile platform that is used by the T'au Fire Caste"
ENT.Category = "[LVS] - Tau"

ENT.VehicleCategory = "Tau"
ENT.VehicleSubCategory = "Hover Tank"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/tau/skyray/skyray.mdl"
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

ENT.MaxVelocityX = 580
ENT.MaxVelocityY = 580

ENT.MaxTurnRate = 0.5

ENT.BoostAddVelocityX = 220
ENT.BoostAddVelocityY = 220

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
	-- Laser Cannon weapon
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 600
	weapon.Delay = 0.2
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.25
	weapon.Attack = function(ent)
		if not ent:WeaponsInRange() then return true end

		ent.MirrorPrimary = not ent.MirrorPrimary

		-- Fixed local positions for left and right laser cannons
		local LeftPosLocal = Vector(-100, 160, 145)
		local RightPosLocal = Vector(-100, -160, 145)

		local PosLocal = ent.MirrorPrimary and LeftPosLocal or RightPosLocal
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

		ent:TakeAmmo()
		ent.PrimarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )


		if ent.MirrorPrimary then
			if IsValid(ent.SNDLeft) then ent.SNDLeft:PlayOnce() end
		else
			if IsValid(ent.SNDRight) then ent.SNDRight:PlayOnce() end
		end
	end

	weapon.OnSelect = function(ent)
		ent:EmitSound("physics/metal/weapon_impact_soft3.wav")
	end
	weapon.OnOverheat = function(ent) ent:EmitSound("lvs/overheat.wav") end
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
	
    weapon.OnOverheat = function(ent)
		ent:EmitSound("lvs/vehicles/general/overheat.mp3")
	end
	self:AddWeapon(weapon)

	-- Missile weapon
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/missile.png")
	weapon.Ammo = 60
	weapon.Delay = 1
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0.2
	weapon.Attack = function(ent)
		if not ent:WeaponsInRange() then return true end

		local Driver = ent:GetDriver()

		-- Define local positions for missile launchers (left and right pairs)
		local MissilePositions = {
			{left = Vector(100, 80, -50), right = Vector(100, -80, -50)},
			{left = Vector(100, 80, -50), right = Vector(100, -80, -50)},
			{left = Vector(100, 80, -50), right = Vector(100, -80, -50)},
		}

		for i = 1, 3 do
			timer.Simple((i / 5) * 0.75, function()
				if not IsValid(ent) then return end

				if ent:GetAmmo() <= 0 then ent:SetHeat(1) return end

				local MuzzleLPos = ent:LocalToWorld(MissilePositions[i].left)
				local MuzzleRPos = ent:LocalToWorld(MissilePositions[i].right)

				local swap = false

				for j = 1, 2 do
					local Pos = swap and MuzzleLPos or MuzzleRPos
					local Start = Pos + ent:GetForward() * 50
					local Dir = (ent:GetEyeTrace().HitPos - Start):GetNormalized()
					if not ent:WeaponsInRange() then
						Dir = swap and ent:GetAngles():Up() or ent:GetAngles():Up()
					end

					local projectile = ents.Create("lvs_missile")
					projectile:SetPos(Start)
					projectile:SetAngles(Dir:Angle())
					projectile:SetParent(ent)
					projectile:Spawn()
					projectile:Activate()
					projectile.GetTarget = function(missile) return missile end
					projectile.GetTargetPos = function(missile)
						return missile:LocalToWorld(Vector(150, 0, 0) + VectorRand() * math.random(-10, 10))
					end
					projectile:SetAttacker(IsValid(Driver) and Driver or ent)
					projectile:SetEntityFilter(ent:GetCrosshairFilterEnts())
					projectile:SetDamage(300)
					projectile:SetRadius(150)
					projectile:Enable()
					projectile:EmitSound("LVS.AAT.FIRE_MISSILE")

					ent:TakeAmmo(1)

					swap = not swap
				end
			end)
		end

		ent:SetHeat(1)
		ent:SetOverheated(true)
	end
	weapon.OnSelect = function(ent)
		ent:EmitSound("weapons/shotgun/shotgun_cock.wav")
	end
	
    weapon.OnOverheat = function(ent)
		ent:EmitSound("lvs/vehicles/general/overheat.mp3")
	end

	self:AddWeapon(weapon)


-- Missile weapon Top (progressive lock + burst fire instead of blind salvo)
local weapon = {}
weapon.Icon = Material("lvs/weapons/missile.png")
weapon.Ammo = 30
weapon.Delay = 0
weapon.HeatRateUp = -0.5
weapon.HeatRateDown = 0.25

-- While holding MB1
weapon.Attack = function(ent)
	if not ent:WeaponsInRange() then return true end
	local T = CurTime()

	-- Initialize tracking table if needed
	if not istable(ent._SkyRayTopMissiles) then
		ent._SkyRayTopMissiles = {}
		ent._nextMissileLock = T
		ent._missilesLocked = 0
	end

	-- Add new missile every 0.2s until we have 6
	if T >= (ent._nextMissileLock or 0) and ent._missilesLocked < 6 then
		ent._nextMissileLock = T + 0.5
		ent._missilesLocked = ent._missilesLocked + 1

		local Driver = ent:GetDriver()

		-- Define local positions (3 pairs = 6 total)
		local MissilePositions = {
			Vector(-400,  40, 150),
			Vector(-380, -40, 150),
			Vector(-300,  40, 150),
			Vector(-280, -40, 150),
			Vector(-200,  40, 150),
			Vector(-180, -40, 150),
		}

		local Pos = ent:LocalToWorld(MissilePositions[ent._missilesLocked])
		local Dir = ent:GetForward()

		local missile = ents.Create("lvs_missile")
		missile:SetPos(Pos)
		missile:SetAngles(Dir:Angle())
		missile:SetParent(ent)
		missile:Spawn()
		missile:Activate()
		missile:SetAttacker(IsValid(Driver) and Driver or ent)
		missile:SetEntityFilter(ent:GetCrosshairFilterEnts())
		missile:SetDamage(500)
		missile:SetRadius(350)

		table.insert(ent._SkyRayTopMissiles, missile)
	end

	-- Keep tracking targets for locked missiles
	if (ent._nextMissileTracking or 0) > T then return end
	ent._nextMissileTracking = T + 0.1

	for _, missile in ipairs(ent._SkyRayTopMissiles) do
		if IsValid(missile) then
			missile:FindTarget(ent:GetPos(), ent:GetForward(), 50, 00)
		end
	end
end

-- On release: fire all locked missiles in burst
weapon.FinishAttack = function(ent)
	if not istable(ent._SkyRayTopMissiles) then return end

	local delay = 0
	for _, missile in ipairs(ent._SkyRayTopMissiles) do
		if IsValid(missile) then
			timer.Simple(delay, function()
				if not IsValid(missile) or not IsValid(ent) then return end
				missile:Enable()
				missile:EmitSound("LVS.AAT.FIRE_MISSILE")
				ent:TakeAmmo(1)
			end)
			delay = delay + 0.2
		end
	end

	-- Clear table for next use
	ent._SkyRayTopMissiles = nil
	ent._missilesLocked = 0

	-- Heat penalty
	local NewHeat = ent:GetHeat() + 0.75
	ent:SetHeat(NewHeat)
	if NewHeat >= 1 then
		ent:SetOverheated(true)
	end
end

weapon.OnSelect = function(ent)
	ent:EmitSound("weapons/shotgun/shotgun_cock.wav")
end
weapon.OnOverheat = function(ent)
	ent:EmitSound("lvs/vehicles/general/overheat.mp3")
end

self:AddWeapon(weapon)



end

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/skyray/loop.wav",
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
		sound = "lvs/vehicles/skyray/loop_hi.wav",
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
		sound = "^lvs/vehicles/skyray/dist.wav",
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
