AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_prediction.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 200

function ENT:OnSpawn( PObj )
	PObj:SetMass( 2500 )

	local DriverSeat = self:AddDriverSeat( Vector(20,0,80), Angle(0,-90,0) )
	DriverSeat.HidePlayer = true
	DriverSeat:SetCameraDistance(-0.5)

	-- Wheels
	local WheelMass = 25
	local WheelRadius = 15
	local WheelPos = {
		-- Left side
		Vector(-120, -30, -100),    
		Vector(-60, -90, -100),   
		Vector(60, -70, -100),   
		Vector(120, -40, -100),  

		-- Right side
		Vector(-120, 30, -100),     
		Vector(-60, 90, -100),    
		Vector(60, 70, -100),    
		Vector(120, 40, -100),  
	}
	for _, Pos in pairs( WheelPos ) do
		self:AddWheel( Pos, WheelRadius, WheelMass, 10 )
	end


	-- Audio 
	self:AddEngineSound( Vector(11,0,35) )

	self.PrimarySND = self:AddSoundEmitter( Vector(118.24,0,49.96), "lvs/vehicles/skyray/fire.mp3", "lvs/vehicles/skyray/fire.mp3" )
	self.PrimarySND:SetSoundLevel( 110 )

	self:AddArmor( Vector(60,0,45), Angle(0,0,0), Vector(-30,-28,-30), Vector(30,28,30), 1000, 5000 )
	self:AddArmor( Vector(-30,0,75), Angle(0,0,0), Vector(-80,-28,-15),Vector(80,28,20), 500, 2500 )
	self:AddArmor( Vector(-70,0,100), Angle(0,0,0), Vector(-35,-30,-15),Vector(40,30,15), 500, 12000 )
	self:AddArmor( Vector(11,0,45), Angle(-55,0,0), Vector(-15,-28,-30),Vector(15,28,40), 250, 500 )
	self:AddArmor( Vector(80,0,25), Angle(0,0,0),  Vector(-50,-100,-15),Vector(50,100,15), 2000, 6000 )
	self:AddArmor( Vector(11,40,46), Angle(-55,0,0), Vector(-12,-12,-50),Vector(12,12,50), 25, 2500 )
	self:AddArmor( Vector(11,-40,46), Angle(-55,0,0), Vector(-12,-12,-50),Vector(12,12,50), 25, 2500 )
end


function ENT:OnCollision( data, physobj )
	if self:WorldToLocal( data.HitPos ).z < 15 then return true end 
	return false
end
