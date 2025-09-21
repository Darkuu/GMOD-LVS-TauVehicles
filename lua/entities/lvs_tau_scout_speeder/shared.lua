ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "Tetra Scout Speeder"
ENT.Author = "Darku"
ENT.Information = "A lightweight, fast, anti-gravitic scout speeder used by the T'au Empire"
ENT.Category = "[LVS] - Tau"

ENT.VehicleCategory = "Tau"
ENT.VehicleSubCategory = "Hover Speeder"

ENT.Spawnable = true
ENT.AdminSpawnable = false

ENT.MDL = "models/tau/tetra/tetrascoutspeeder.mdl"

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

ENT.MaxHealth = 2001

ENT.ForceAngleMultiplier = 2
ENT.ForceAngleDampingMultiplier = 1

ENT.ForceLinearMultiplier = 1
ENT.ForceLinearRate = 0.25

ENT.MaxVelocityX = 1080
ENT.MaxVelocityY = 1080

ENT.MaxTurnRate = 1.5

ENT.BoostAddVelocityX = 500
ENT.BoostAddVelocityY = 500

ENT.GroundTraceHitWater = true
ENT.GroundTraceLength = 50
ENT.GroundTraceHull = 100

function ENT:OnSetupDataTables()
	self:AddDT("Bool", "BTLFire")
	self:AddDT("Bool", "IsCarried")
	self:AddDT("Entity", "GunnerSeat")

	if SERVER then
		self:NetworkVarNotify("IsCarried", self.OnIsCarried)
	end
end

function ENT:GetGunnerSeat()
	return self:GetDTEntity(1) 
end


function ENT:SetPoseParameterBTL(weapon)
	if not weapon then return end

	local driver = weapon:GetDriver()
	if not IsValid(driver) then return end

	local trace = driver:GetEyeTrace()
	local muzzlePos = self:LocalToWorld(Vector(5, 0, 2))

	local aimAngles = self:WorldToLocalAngles((trace.HitPos - muzzlePos):GetNormalized():Angle())

	self:SetPoseParameter("cannon_right_pitch", SmoothPose("cannon_right_pitch", aimAngles.p))
	self:SetPoseParameter("cannon_right_yaw", SmoothPose("cannon_right_yaw", aimAngles.y))
end

function ENT:PredictPoseParamaters()
	local pod = self:GetGunnerSeat()
	if not IsValid(pod) then return end

	local plyL = LocalPlayer()
	local ply = pod:GetDriver()
	if ply ~= plyL then return end

	if self.SetPoseParameterBTL then
		self:SetPoseParameterBTL(pod:lvsGetWeapon())
	end

	self:InvalidateBoneCache()
end

function ENT:GetAimAngles()
	local trace = self:GetEyeTrace()
	if not trace or not trace.HitPos then return Angle(0, 0, 0) end

	local muzzlePos = self:LocalToWorld(Vector(5, 0, 2))

	local aimAngles = self:WorldToLocalAngles((trace.HitPos - muzzlePos):GetNormalized():Angle())

	local clampPitchMin, clampPitchMax = -10, 10
	local clampYawMin, clampYawMax = -10, 10

	aimAngles.p = math.Clamp(aimAngles.p, clampPitchMin, clampPitchMax)
	aimAngles.y = math.Clamp(aimAngles.y, clampYawMin, clampYawMax)

	return aimAngles
end

function ENT:WeaponsInRange()
	if self:GetIsCarried() then return false end
	local aimAngles = self:GetAimAngles()
	return not ((aimAngles.p >= 10) or (aimAngles.p <= -25) or (math.abs(aimAngles.y) >= 30))
end


function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 600
	weapon.Delay = 0.2
	weapon.HeatRateUp = 0.25
	weapon.HeatRateDown = 0.25

	weapon.Attack = function(ent)
		if not ent:WeaponsInRange() then return true end
		local Pos = ent:LocalToWorld(Vector(60, 0 , 40))
		local Dir
		local rawDir = (ent:GetEyeTrace().HitPos - Pos):GetNormalized()
		local localAngles = ent:WorldToLocalAngles(rawDir:Angle())
		local clampPitchMin, clampPitchMax = -10, 10
		local clampYawMin, clampYawMax = -10, 10
		localAngles.p = math.Clamp(localAngles.p, clampPitchMin, clampPitchMax)
		localAngles.y = math.Clamp(localAngles.y, clampYawMin, clampYawMax)
		Dir = ent:LocalToWorldAngles(localAngles):Forward()
		
		local bullet = {}
		bullet.Src = Pos
		bullet.Dir = Dir
		bullet.Spread = Vector(0.01, 0.01, 0)
		bullet.TracerName = "lvs_laser_blue_long"
		bullet.Force = 10000
		bullet.HullSize = 1
		bullet.Damage = 25
		bullet.Velocity = 40000
		bullet.Attacker = ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
			effectdata:SetStart(Vector(50, 50, 255))
			effectdata:SetOrigin(tr.HitPos)
			effectdata:SetNormal(tr.HitNormal)
			util.Effect("lvs_laser_impact", effectdata)
		end
		ent:LVSFireBullet(bullet)

		local effectdata = EffectData()
		effectdata:SetStart(Vector(50, 50, 255))
		effectdata:SetOrigin(bullet.Src)
		effectdata:SetNormal(Dir)
		effectdata:SetEntity(ent)
		util.Effect("lvs_muzzle_colorable", effectdata)
		ent:TakeAmmo()

		if IsValid(ent.SNDRight) then
			ent.SNDRight:PlayOnce(100 + math.cos(CurTime() + ent:EntIndex() * 15) * 15)
		end
	end

	weapon.HudPaint = function(ent, X, Y, ply)
		if ent:GetIsCarried() then return end
		local Pos2D = ent:GetEyeTrace().HitPos:ToScreen()
		ent:PaintCrosshairCenter(Pos2D, color_white)
		ent:PaintCrosshairOuter(Pos2D, color_white)
		ent:LVSPaintHitMarker(Pos2D)
	end

	weapon.OnOverheat = function(ent)
	    ent:EmitSound("lvs/vehicles/general/overheat.mp3")
	end

	self:AddWeapon(weapon, 1)
	
end

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/tetra/loop.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
	{
		sound = "^lvs/vehicles/tetra/dist.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 100,
	},
}
