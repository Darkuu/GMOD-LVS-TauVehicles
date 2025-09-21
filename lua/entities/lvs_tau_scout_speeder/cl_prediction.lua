function ENT:PredictPoseParamaters()
    local pod = self:GetGunnerSeat()
    if not IsValid(pod) then return end

    local ply = pod:GetDriver()
    if not IsValid(ply) then return end

    local plyL = LocalPlayer()
    if ply ~= plyL then return end

    local aimVec = ply:GetAimVector()
    local targetPos = ply:GetShootPos() + aimVec * 10000
    local localPos = pod:WorldToLocal(targetPos)
    local aimAng = localPos:Angle()
    aimAng:Normalize()

    local pitch = math.Approach(self:GetPoseParameter("turret_pitch") or 0, aimAng.p, FrameTime() * 200)
    local yaw = math.Approach(self:GetPoseParameter("turret_yaw") or 0, aimAng.y, FrameTime() * 200)

    self:SetPoseParameter("turret_pitch", pitch)
    self:SetPoseParameter("turret_yaw", yaw)

    self:InvalidateBoneCache()
end
