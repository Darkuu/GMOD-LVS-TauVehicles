AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_prediction.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 150

function ENT:OnSpawn( PObj )

	PObj:SetMass( 100 )
	local DriverSeat = self:AddDriverSeat( Vector(-30,0,43), Angle(0,-90,0) )
	DriverSeat.HidePlayer = true

	local WheelMass = 25
	local WheelRadius = 14

	local WheelPos = {
		Vector(0, -100, -90),     
		Vector(95, -120, -90),   
		Vector(-120, -140, -110),  
		Vector(0, 100, -90),    
		Vector(95, 120, -90),    
		Vector(-120, 140, -110), 
		}

	for _, Pos in pairs( WheelPos ) do
		self:AddWheel( Pos, WheelRadius, WheelMass, 10 )
	end

	self:AddEngineSound( Vector(0,0,30) )
	
	self.PrimarySND = self:AddSoundEmitter( Vector(60,0,8), "lvs/vehicles/devilfish/fire_wing.wav", "lvs/vehicles/devilfish/fire_wing.wav" )
	self.PrimarySND:SetSoundLevel( 110 )

	self.SecondarySND = self:AddSoundEmitter( Vector(30,0,6.5), "lvs/vehicles/devilfish/fire.mp3", "lvs/vehicles/devilfish/fire.mp3" )
	self.SecondarySND:SetSoundLevel( 110 )

	self:AddArmor( Vector(30,0,25), Angle(20,0,0), Vector(-45,-40,-20), Vector(40,40,10), 750, 4000 )
	self:AddArmor( Vector(-60,0,35), Angle(0,0,0), Vector(0,-40,-30), Vector(50,40,30), 250, 2500 )
	self:AddArmor( Vector(-60,0,35), Angle(0,0,0), Vector(-40,-40,-30), Vector(0,40,30), 10, 500 )
	self:AddArmor( Vector(0,60,10), Angle(0,0,-15), Vector(-120,-25,-10), Vector(130,25,10), 50, 1000 )
	self:AddArmor( Vector(0,-60,10), Angle(0,0,15), Vector(-120,-25,-10), Vector(130,25,10), 50, 1000 )

	
    local totalSeats = 12
    local baseX = 10
    local baseZ = 10
    local exitX = -500  
    local exitZ = 0

	for i = 0, totalSeats - 1 do
        local X = baseX - i * 35
        local Y = 0  
        local seat = self:AddPassengerSeat( Vector(X, Y, baseZ), Angle(0,0,0) )
        local exitY = 20 * ((i % 10) - 5) 
        seat.ExitPos = Vector(exitX, exitY, exitZ)
        seat.HidePlayer = true
    end
end

function ENT:OnEngineActiveChanged( Active )
    if Active then
        self:EmitSound( "lvs/vehicles/general/start.wav" )
    else
        self:EmitSound( "lvs/vehicles/general/stop.wav" )
    end
end


function ENT:OnCollision( data, physobj )
	if self:WorldToLocal( data.HitPos ).z < 0 then return true end
	return false
end



