AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 100

function ENT:OnSpawn( PObj )
    PObj:SetMass( 1000 )

    self:AddDriverSeat( Vector(110,25,40), Angle(0,-90,0) ).HidePlayer = true

    self:AddEngine( Vector(-70,0,10) )
    self:AddEngineSound( Vector(-0,0,0) )

    local totalSeats = 40
    local baseX = 10
    local baseZ = 10
    local exitX = -300  
    local exitZ = 36

    for i = 0, totalSeats - 1 do
        local X = baseX - i * 35
        local Y = 0  
        local seat = self:AddPassengerSeat( Vector(X, Y, baseZ), Angle(0,0,0) )
        
        -- Spread Exit positions on Y to left and right alternately to avoid clumping
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
