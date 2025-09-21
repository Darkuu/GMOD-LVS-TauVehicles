include("shared.lua")

function ENT:OnSpawn()
-- Line trails
	self:RegisterTrail(Vector(-180, 90, 65), 0, 20, 2, 1000, 150)
	self:RegisterTrail(Vector(-180, -90, 65), 0, 20, 2, 1000, 150)
	self:RegisterTrail(Vector(-180, 90, 45), 0, 20, 2, 1000, 150)
	self:RegisterTrail(Vector(-180, -90, 45), 0, 20, 2, 1000, 150)
end

ENT.EngineGlow = Material("sprites/light_glow02_add")
ENT.EngineFXColor = Color(100, 150, 255, 255) 

local function EngineGrid(x, yCenter, zCenter)
	local offset = 5
	local positions = {}

	for dx = -1, 1 do
		for dz = -1, 1 do
			table.insert(positions, Vector(x, yCenter + dx * offset, zCenter + dz * offset))
		end
	end

	return positions
end

ENT.EngineFxPos = {}

local baseZ = 75
local topZ = baseZ + 20

table.Add(ENT.EngineFxPos, EngineGrid(16,  125, baseZ)) -- Front left (base)
table.Add(ENT.EngineFxPos, EngineGrid(16,  125, topZ))  -- Front left (top)

table.Add(ENT.EngineFxPos, EngineGrid(16, -125, baseZ)) -- Front right (base)
table.Add(ENT.EngineFxPos, EngineGrid(16, -125, topZ))  -- Front right (top)

table.Add(ENT.EngineFxPos, EngineGrid(-200,  97, baseZ)) -- Rear left (base)
table.Add(ENT.EngineFxPos, EngineGrid(-200,  97, topZ))  -- Rear left (top)

table.Add(ENT.EngineFxPos, EngineGrid(-200, -97, baseZ)) -- Rear right (base)
table.Add(ENT.EngineFxPos, EngineGrid(-200, -97, topZ))  -- Rear right (top)

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end

	local throttle = self:GetThrottle()
	local boost = self:GetBoost()

	local size = 50 + throttle * 25 + boost * 0.5

	render.SetMaterial(self.EngineGlow)

	for _, localPos in ipairs(self.EngineFxPos) do
		local worldPos = self:LocalToWorld(localPos)
		render.DrawSprite(worldPos, size, size, self.EngineFXColor)
	end
end

function ENT:OnFrame()
	self:DamageFX()
end

function ENT:DamageFX()
	self.nextDFX = self.nextDFX or 0

	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05

		local HP = self:GetHP()
		local MaxHP = self:GetMaxHP()

		if HP > MaxHP * 0.5 then return end

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( Vector(-30,0,43) ) )
			effectdata:SetEntity( self )
		util.Effect( "lvs_engine_blacksmoke", effectdata )

		if HP <= MaxHP * 0.25 then
			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( Vector(-85,65,14) ) )
				effectdata:SetNormal( self:GetUp() )
				effectdata:SetMagnitude( math.Rand(0.5,1.5) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_exhaust_fire", effectdata )

			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( Vector(-85,-65,14) ) )
				effectdata:SetNormal( self:GetUp() )
				effectdata:SetMagnitude( math.Rand(0.5,1.5) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_exhaust_fire", effectdata )
		end
	end
end
