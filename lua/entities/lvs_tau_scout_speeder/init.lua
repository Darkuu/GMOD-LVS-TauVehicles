AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_prediction.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 50

function ENT:OnSpawn( PObj )

	PObj:SetMass( 2500 )

	local DriverSeat = self:AddDriverSeat( Vector(0,0,75), Angle(0,-90,0) )
	DriverSeat.HidePlayer = false 
	

	local GunnerSeat = self:AddPassengerSeat( Vector(-80,0,65), Angle(0,-90,0) )
	GunnerSeat.HidePlayer = false
	self:SetGunnerSeat( GunnerSeat )

	local ID = self:LookupAttachment( "gunner" )
	local Attachment = self:GetAttachment( ID )

	if Attachment then
		local Pos,Ang = LocalToWorld( Vector(0,-15,0), Angle(180,0,-90), Attachment.Pos, Attachment.Ang )

		GunnerSeat:SetParent( NULL )
		GunnerSeat:SetPos( Pos )
		GunnerSeat:SetAngles( Ang )
		GunnerSeat:SetParent( self )

		self.sndBTL:SetParent( NULL )
		self.sndBTL:SetPos( Pos )
		self.sndBTL:SetAngles( Ang )
		self.sndBTL:SetParent( self )
	end

	local WheelMass = 25
	local WheelRadius = 14
	local WheelPos = {
		Vector(-85,-70,-12),
		Vector(-5,-70,-11),
		Vector(80,-70,-12),
		Vector(-85,70,-12),
		Vector(-5,70,-11),
		Vector(80,70,-12),
	}

	for _, Pos in pairs( WheelPos ) do
		self:AddWheel( Pos, WheelRadius, WheelMass, 10 )
	end

	self:AddEngineSound( Vector(0,0,30) )

	-- Safe muzzle left attachment
	local IDLeft = self:LookupAttachment( "muzzle_left" )
	local MuzzleLeft = nil
	if IDLeft > 0 then
		MuzzleLeft = self:GetAttachment( IDLeft )
	end

	if MuzzleLeft then
		self.SNDLeft = self:AddSoundEmitter( self:WorldToLocal( MuzzleLeft.Pos ), "lvs/vehicles/tetra/fire.mp3", "lvs/vehicles/tetra/fire.mp3" )
		self.SNDLeft:SetParent( self, IDLeft )
	else
		local muzzleLeftPos = Vector(3.5, -0.4, 0.9)
		self.SNDLeft = self:AddSoundEmitter( muzzleLeftPos, "lvs/vehicles/tetra/fire.mp3", "lvs/vehicles/tetra/fire.mp3" )
		self.SNDLeft:SetParent( self )
	end
	self.SNDLeft:SetSoundLevel( 110 )

	-- Safe muzzle right attachment
	local IDRight = self:LookupAttachment( "muzzle_right" )
	local MuzzleRight = nil
	if IDRight > 0 then
		MuzzleRight = self:GetAttachment( IDRight )
	end

	if MuzzleRight then
		self.SNDRight = self:AddSoundEmitter( self:WorldToLocal( MuzzleRight.Pos ), "lvs/vehicles/tetra/fire.mp3", "lvs/vehicles/tetra/fire.mp3" )
		self.SNDRight:SetParent( self, IDRight )
	else
		local muzzleRightPos = Vector(3.5, 0.45, 0.9)
		self.SNDRight = self:AddSoundEmitter( muzzleRightPos, "lvs/vehicles/tetra/fire.mp3", "lvs/vehicles/tetra/fire.mp3" )
		self.SNDRight:SetParent( self )
	end
	self.SNDRight:SetSoundLevel( 110 )

	self:AddArmor( Vector(30,0,25), Angle(20,0,0), Vector(-45,-40,-20), Vector(40,40,10), 750, 4000 )
	self:AddArmor( Vector(-60,0,35), Angle(0,0,0), Vector(0,-40,-30), Vector(50,40,30), 250, 2500 )
	self:AddArmor( Vector(-60,0,35), Angle(0,0,0), Vector(-40,-40,-30), Vector(0,40,30), 10, 500 )
	self:AddArmor( Vector(0,60,10), Angle(0,0,-15), Vector(-120,-25,-10), Vector(130,25,10), 50, 1000 )
	self:AddArmor( Vector(0,-60,10), Angle(0,0,15), Vector(-120,-25,-10), Vector(130,25,10), 50, 1000 )
end

function ENT:OnCollision( data, physobj )
	if self:WorldToLocal( data.HitPos ).z < 0 then return true end 

	return false
end

