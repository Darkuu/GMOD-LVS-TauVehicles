
ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "Orca Transport"
ENT.Author = "Darku"
ENT.Information = "Dedicated armoured orbital transport shuttle for ferrying Tau troops"
ENT.Category = "[LVS] - Tau"

ENT.VehicleCategory = "Tau"
ENT.VehicleSubCategory = "Transport"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/tau/Orca/orca.mdl"

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

ENT.MaxVelocity = 2150
ENT.MaxThrust = 2150

ENT.ThrustVtol = 55
ENT.ThrustRateVtol = 3

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 0.5

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 2500


sound.Add( {
	name = "LVS.ORCA.FLYBY",
	sound = {"lvs/vehicles/orca/flyby.wav","lvs/vehicles/orca/flyby_a.wav","lvs/vehicles/orca/flyby_b.wav","lvs/vehicles/orca/flyby_c.wav"}
} )

ENT.FlyByAdvance = 0
ENT.FlyBySound = "LVS.ORCA.FLYBY" 

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/orca/loop.wav",
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
		sound = "lvs/vehicles/orca/dist.wav",
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