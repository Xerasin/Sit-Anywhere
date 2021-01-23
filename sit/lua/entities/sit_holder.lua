--easylua.StartEntity("sit_holder")

ENT.Type = "anim"
ENT.PrintName = "Sit Holder"
ENT.Model = "models/props_junk/PopCan01a.mdl"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

if SERVER then AddCSLuaFile() end

ENT.PhysShadowControl = {
    secondstoarrive = 0.1,
    pos = Vector(0, 0, 0),
    angle = Angle(0, 0, 0),
    maxspeed = 1000000,
    maxangular = 5000,
    maxspeeddamp = 1000000,
    maxangulardamp = 10000,
    dampfactor = 0.8,
    teleportdistance = 5,
    deltatime = 0
}

function ENT:Initialize()
    self:SetModel(self.Model)

    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    self:AddEFlags(EFL_NO_DISSOLVE)

    if SERVER then
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
            phys:SetMaterial("gmod_ice")
            phys:SetMass(10)
            phys:EnableGravity(false)
        end

        self:SetActivated(false)
    else
        local pyo = self:GetPhysicsObject()
        if IsValid(pyo) then
            self:AddToMotionController(pyo)
            pyo:Wake()
        end
    end
    self:StartMotionController()
end

local activated = false
function ENT:Think()
    if CLIENT then
        local pyo = self:GetPhysicsObject()
        if not activated and IsValid(pyo) then
            self:AddToMotionController(pyo)
            pyo:Wake()
        end
    end

    if self:GetActivated() then
        if SERVER and (not IsValid(self:GetSeat()) or not IsValid(self:GetTargetPlayer())) then
            SafeRemoveEntity(self)
        end
        local seat = self:GetSeat()
        if CLIENT and IsValid(seat)  then
            local holder, targetPly = self, self:GetTargetPlayer()
            --[[if not seat.RenderOverride then
                seat.RenderOverride = function(sSeat)
                    if not sSeat.Draw then return end
                    if not IsValid(holder) or not IsValid(targetPly) then sSeat:Draw() return end
                    local tPos, tAng = LocalToWorld(holder:GetTargetLocalPos(), holder:GetTargetLocalAng(), targetPly:GetRenderOrigin(), targetPly:GetRenderAngles())

                    sSeat:SetRenderOrigin(tPos)
                    sSeat:SetRenderAngles(tAng)
                    sSeat:Draw()
                end
            end]]
            local function drawChildren(seatToCheck, depth)
                depth = (depth or 0) + 1
                for k,v in pairs(seatToCheck:GetChildren()) do
                    if v:GetClass() == "prop_vehicle_prisoner_pod" and v:GetNWBool("SitPose", false) and depth <= 128 then
                        local pos, ang = v:GetNWVector("SitPosePos"), v:GetNWAngle("SitPoseAng")
                        local tPos, tAng = LocalToWorld(pos, ang, seatToCheck:GetPos(), seatToCheck:GetRenderAngles())
                        v:SetRenderOrigin(tPos)
                        v:SetRenderAngles(tAng)
                        drawChildren(v, depth)
                    end
                end
            end
            if not IsValid(holder) or not IsValid(targetPly) then return end
            local tPos, tAng = LocalToWorld(holder:GetTargetLocalPos(), holder:GetTargetLocalAng(), targetPly:GetPos(), targetPly:GetRenderAngles() or targetPly:GetAngles() or Angle())
            seat:SetRenderOrigin(tPos)
            seat:SetRenderAngles(tAng)

            drawChildren(seat)


        end
    end
end

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "TargetPlayer")
    self:NetworkVar( "Entity", 1, "Seat")

    self:NetworkVar( "Vector", 0, "TargetLocalPos")
    self:NetworkVar( "Angle", 0, "TargetLocalAng")
    self:NetworkVar( "Bool", 0, "Activated")
end

function ENT:SetTargetEnt(ent, vehicle, pos, ang)
    local lPos, lAng = WorldToLocal(pos, ang, ent:GetPos(), ent:GetAngles())
    self:SetTargetPlayer(ent)
    self:SetSeat(vehicle)
    self:SetTargetLocalPos(lPos)
    self:SetTargetLocalAng(lAng)
    self:SetActivated(true)

    self.PhysShadowControl.pos = pos
    self.PhysShadowControl.angle = ang
end

function ENT:PhysicsSimulate(phys, deltatime)
    local tPos, tAng = self:GetPos(), self:GetAngles()

    local ent = self:GetTargetPlayer()
    if self:GetActivated() and IsValid(ent) and IsValid(self:GetSeat()) then
        local targetAng = (ent.GetRenderAngles and ent:GetRenderAngles() or ent:GetAngles())
        tPos, tAng = LocalToWorld(self:GetTargetLocalPos(), self:GetTargetLocalAng(), ent.GetRenderOrigin and ent:GetRenderOrigin() or ent:GetPos(), targetAng or Angle())
    end

    phys:Wake()

    self.PhysShadowControl.pos = tPos
    self.PhysShadowControl.angle = tAng
    self.PhysShadowControl.deltatime = deltatime

    return phys:ComputeShadowControl(self.PhysShadowControl)
end
function ENT:CanTool() return false end

if CLIENT then
    function ENT:Draw()

    end
end
--easylua.EndEntity()

if SERVER then
    local function disallow(ent)
        if IsValid(ent) and ent:GetClass() == "sit_holder" then return false end
    end
    hook.Add("GravGunPickupAllowed", "SitAnywhereHolder", function(_, ent) return disallow(ent) end)
    hook.Add("PhysgunPickup", "SitAnywhereHolder", function(_, ent) return disallow(ent) end)
end