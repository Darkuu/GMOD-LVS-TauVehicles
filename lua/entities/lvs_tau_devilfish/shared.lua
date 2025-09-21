ENT.Base = "lvs_base_fakehover"

ENT.PrintName = "TY7 Devilfish"
ENT.Author = "Darku"
ENT.Information = "A armoured troop carrier, is the primary anti-gravitic skimmer transport utilised by T'au"
ENT.Category = "[LVS] - Tau"

ENT.VehicleCategory = "Tau"
ENT.VehicleSubCategory = "Transport"

ENT.Spawnable = true
ENT.AdminSpawnable = false

ENT.MDL = "models/tau/Devilfish/devilfish.mdl"

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

ENT.MaxVelocityX = 480
ENT.MaxVelocityY = 480

ENT.MaxTurnRate = 0.5

ENT.BoostAddVelocityX = 220
ENT.BoostAddVelocityY = 220

ENT.GroundTraceHitWater = true
ENT.GroundTraceLength = 150
ENT.GroundTraceHull = 150


function ENT:OnSetupDataTables()
    self:AddDT("Bool", "BTLFire")
    self:AddDT("Bool", "IsCarried")
    self:AddDT("Entity", "GunnerSeat")

    if SERVER then
        self:NetworkVarNotify("IsCarried", self.OnIsCarried)
    end
end

-- Helper to get gunner pod
function ENT:GetGunnerSeat()
    return self:GetDTEntity(2) -- corrected index for GunnerSeat
end

-- Smoothly update pose parameters for muzzle based on gunner aim angles
function ENT:SetPoseParameterBTL(weapon)
    if not weapon then return end

    if self:GetIsCarried() then
        -- Reset pose parameters for single cannon
        self:SetPoseParameter("cannon_pitch", 0)
        self:SetPoseParameter("cannon_yaw", 0)
        return
    end

    local driver = weapon:GetDriver()
    if not IsValid(driver) then return end

    -- Get the aim angles from gunner's eye trace
    local trace = driver:GetEyeTrace()
    local muzzlePos = self:LocalToWorld(Vector(5000, 0, 0)) -- single center muzzle

    -- Calculate aim angles relative to muzzle position
    local aimAngles = self:WorldToLocalAngles((trace.HitPos - muzzlePos):GetNormalized():Angle())

    -- Clamp angles for natural aiming limits
    local clampPitchMin, clampPitchMax = -10, 10
    local clampYawMin, clampYawMax = -10, 10

    aimAngles.p = math.Clamp(aimAngles.p, clampPitchMin, clampPitchMax)
    aimAngles.y = math.Clamp(aimAngles.y, clampYawMin, clampYawMax)

    -- Smooth interpolation helper
    local function SmoothPose(param, target)
        local current = self:GetPoseParameter(param) or 0
        return Lerp(0.3, current, target)
    end

    self:SetPoseParameter("cannon_pitch", SmoothPose("cannon_pitch", aimAngles.p))
    self:SetPoseParameter("cannon_yaw", SmoothPose("cannon_yaw", aimAngles.y))
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

    local AimAngles = self:WorldToLocalAngles((trace.HitPos - self:LocalToWorld(Vector(3.5, 0, 0.9))):GetNormalized():Angle())

    local clampPitchMin, clampPitchMax = -10, 10
    local clampYawMin, clampYawMax = -10, 10

    AimAngles.p = math.Clamp(AimAngles.p, clampPitchMin, clampPitchMax)
    AimAngles.y = math.Clamp(AimAngles.y, clampYawMin, clampYawMax)

    return AimAngles
end

function ENT:WeaponsInRange()
    if self:GetIsCarried() then return false end

    local AimAngles = self:GetAimAngles()

    return not (
        (AimAngles.p >= 10) or
        (AimAngles.p <= -25) or
        (math.abs(AimAngles.y) >= 30)
    )
end

function ENT:InitWeapons()
    -- Primary Rotary Gun (single centered muzzle)
    local primaryWeapon = {}
    primaryWeapon.Icon = Material("lvs/weapons/hmg.png")
    primaryWeapon.Ammo = 5000
    primaryWeapon.Delay = 0.05
    primaryWeapon.HeatRateUp = 0.1
    primaryWeapon.HeatRateDown = 0.2

    primaryWeapon.Attack = function(ent)
        if not ent:WeaponsInRange() then return true end

        local Pos = ent:LocalToWorld(Vector(350, 0, -25))
        local rawDir = (ent:GetEyeTrace().HitPos - Pos):GetNormalized()

        local localAngles = ent:WorldToLocalAngles(rawDir:Angle())

        local clampPitchMin, clampPitchMax = -10, 10
        local clampYawMin, clampYawMax = -10, 10

        localAngles.p = math.Clamp(localAngles.p, clampPitchMin, clampPitchMax)
        localAngles.y = math.Clamp(localAngles.y, clampYawMin, clampYawMax)

        local Dir = ent:LocalToWorldAngles(localAngles):Forward()

        local bullet = {}
        bullet.Src = Pos
        bullet.Dir = Dir
        bullet.Spread = Vector(0.05, 0.05, 0)
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
        ent.PrimarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )

    end

    primaryWeapon.OnOverheat = function(ent)
		ent:EmitSound("lvs/vehicles/general/overheat.mp3")
	end

    primaryWeapon.HudPaint = function(ent, X, Y, ply)
        if ent:GetIsCarried() then return end

        local Pos2D = ent:GetEyeTrace().HitPos:ToScreen()

        ent:PaintCrosshairCenter(Pos2D, color_white)
        ent:PaintCrosshairOuter(Pos2D, color_white)
        ent:LVSPaintHitMarker(Pos2D)
    end


    self:AddWeapon(primaryWeapon)

    -- Side Gun Turrets
    local sideweapon = {}
	sideweapon.Icon = Material("lvs/weapons/dual_mg.png")
    sideweapon.Ammo = 5000
    sideweapon.Delay = 0.25
    sideweapon.MirrorPrimary = false

    sideweapon.Attack = function(ent)
        if not ent:WeaponsInRange() then return true end

        ent.MirrorPrimary = not ent.MirrorPrimary

        local muzzlesRight = {
            Vector(3.5, -180, -20),
            Vector(3.5, -140, -20),
        }

        local muzzlesLeft = {
            Vector(3.5, 180, -20),
            Vector(3.5, 140, -20),
        }

        local chosenMuzzles = ent.MirrorPrimary and muzzlesRight or muzzlesLeft

        local clampPitchMin, clampPitchMax = -50, 50
        local clampYawMin, clampYawMax = -180, 180

        for _, muzzlePosLocal in ipairs(chosenMuzzles) do
            local Pos = ent:LocalToWorld(muzzlePosLocal)

            local rawDir = (ent:GetEyeTrace().HitPos - Pos):GetNormalized()

            local localAngles = ent:WorldToLocalAngles(rawDir:Angle())

            localAngles.p = math.Clamp(localAngles.p, clampPitchMin, clampPitchMax)
            localAngles.y = math.Clamp(localAngles.y, clampYawMin, clampYawMax)

            local Dir = ent:LocalToWorldAngles(localAngles):Forward()

            local bullet = {}
            bullet.Src = Pos
            bullet.Dir = Dir
            bullet.Spread = Vector(0.05, 0.05, 0)
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
            effectdata:SetOrigin(Pos)
            effectdata:SetNormal(Dir)
            effectdata:SetEntity(ent)
            util.Effect("lvs_muzzle_colorable", effectdata)
        end

        ent:TakeAmmo()
        ent.SecondarySND:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )
    end

    sideweapon.HudPaint = function(ent, X, Y, ply)
        if ent:GetIsCarried() then return end

        local Pos2D = ent:GetEyeTrace().HitPos:ToScreen()

        ent:PaintCrosshairCenter(Pos2D, color_white)
        ent:PaintCrosshairOuter(Pos2D, color_white)
        ent:LVSPaintHitMarker(Pos2D)
    end

    sideweapon.OnOverheat = function(ent)
	    ent:EmitSound("lvs/vehicles/general/overheat.mp3")
	end

    self:AddWeapon(sideweapon)
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
        VolumeMax = 0.8,
        Channel = CHAN_STATIC,
    },
}

ENT.LVSHoverParams = {
    EnginePower = 500,
    EngineDamping = 400,
    BankForce = 100,
    BankForceDivider = 100,
    MaxBank = 35,
    BankDamp = 7,
    BankReturn = 2,
    PitchForce = 1000,
    PitchDamp = 7,
    PitchReturn = 4,
    YawForce = 1600,
    YawDamp = 9,
    YawReturn = 4,
}


ENT.LVSExhaustPos = {
    Vector(15, 0, 30),
}

ENT.LVSWheelData = {}
