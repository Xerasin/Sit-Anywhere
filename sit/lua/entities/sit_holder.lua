--easylua.StartEntity("sit_holder")
ENT.Type = "anim"
ENT.PrintName = "Sit Holder"
ENT.Model = "models/sprops/rectangles_superthin/size_2_5/rect_18x18.mdl"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

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
        if CLIENT and IsValid(seat) and self:GetActivated() and not seat.RenderOverride then
            local holder = self
            seat.RenderOverride = function(sSeat)
                if not IsValid(holder) then sSeat:Draw() return end
                local ent = self:GetTargetPlayer()
                if not IsValid(ent) then sSeat:Draw() return end

                local tPos, tAng = LocalToWorld(holder:GetTargetLocalPos(), holder:GetTargetLocalAng(), ent:GetRenderOrigin(), ent:GetRenderAngles())
                sSeat:SetRenderOrigin(tPos)
                sSeat:SetRenderAngles(tAng)
                sSeat:Draw()
            end
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
        tPos, tAng = LocalToWorld(self:GetTargetLocalPos(), self:GetTargetLocalAng(), ent:GetPos(), ent:GetRenderAngles())
    end
    phys:Wake()

    self.PhysShadowControl.pos = tPos
    self.PhysShadowControl.angle = tAng
    self.PhysShadowControl.deltatime = deltatime

    return phys:ComputeShadowControl(self.PhysShadowControl)
end

if CLIENT then
    function ENT:Draw()

    end
end
--easylua.EndEntity()

--[[if SERVER then
	if OldFollow then
		SafeRemoveEntity(OldFollow)
		SafeRemoveEntity(OldFollow.veh)
		return
	end

	local tPos, tAng = me:GetShootPos() + Vector(0, 0, 4), me:EyeAngles()
	OldFollow = ents.Create("sit_holder")
	OldFollow:SetPos(tPos)
	OldFollow:SetAngles(tAng)
	OldFollow:Spawn()

	local vehicle = ents.Create("prop_vehicle_prisoner_pod")
	vehicle:SetModel("models/nova/airboat_seat.mdl") -- DO NOT CHANGE OR CRASHES WILL HAPPEN

	vehicle:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
	vehicle:SetKeyValue("limitview","0")

	vehicle:SetAngles(tAng)
	vehicle:SetPos(tPos)
	vehicle:Spawn()
	vehicle:Activate()

	local phys = vehicle:GetPhysicsObject()
	vehicle:SetCollisionGroup(COLLISION_GROUP_WORLD)
	OldFollow.veh = vehicle
	vehicle:SetParent(OldFollow)
	OldFollow:SetTargetEnt(me, vehicle, tPos, tAng)
end
]]