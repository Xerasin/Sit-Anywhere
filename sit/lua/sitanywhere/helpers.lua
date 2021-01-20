SitAnywhere = SitAnywhere or {}
SitAnywhere.NET = {
    ["SitWantedAng"] = 0,
}

SitAnywhere.ClassBlacklist = {
    ["gmod_wire_keyboard"] = true,
    ["prop_combine_ball"] = true
}
SitAnywhere.ModelBlacklist = {
}

local EMETA = FindMetaTable"Entity"
--local PMETA = FindMetaTable"Player"

function SitAnywhere.GetAreaProfile(pos, resolution, simple)
    local filter = player.GetAll()
    local dists = {}
    local distsang = {}
    local ang_smallest_hori = nil
    local smallest_hori = 90000
    local angPerIt = (360 / resolution)
    for I = 0, 360, angPerIt do
        local rad = math.rad(I)
        local dir = Vector(math.cos(rad), math.sin(rad), 0)
        local trace = util.QuickTrace(pos + dir * 20 + Vector(0,0,5), Vector(0,0,-15000), filter)
        trace.HorizontalTrace = util.QuickTrace(pos + Vector(0,0,5), dir * 1000, filter)
        trace.Distance  =  trace.StartPos:Distance(trace.HitPos)
        trace.Distance2 = trace.HorizontalTrace.StartPos:Distance(trace.HorizontalTrace.HitPos)
        trace.ang = I

        if (not trace.Hit or trace.Distance > 14) and (not trace.HorizontalTrace.Hit or trace.Distance2 > 20) then
            if simple then return true end
            table.insert(dists, trace)
        end
        if trace.Distance2 < smallest_hori and (not trace.HorizontalTrace.Hit or trace.Distance2 > 3) then
            smallest_hori = trace.Distance2
            ang_smallest_hori = I
        end
        distsang[I] = trace
    end

    if simple then return false end
    return dists, distsang, ang_smallest_hori, smallest_hori
end

function SitAnywhere.CheckValidAngForSit(pos, surfaceAng, ang)
    local rad = math.rad(ang)
    local dir = Vector(math.cos(rad), math.sin(rad), 0)
    local trace2 = util.TraceLine({
        start = pos - dir * (20 - .5) + surfaceAng:Forward() * 5,
        endpos = pos - dir * (20 - .5) + surfaceAng:Forward() * -160,
        filter = player.GetAll()
    })

    local hor_trace = util.TraceLine({
        start = pos + Vector(0, 0, 5),
        endpos = pos + Vector(0, 0, 5) - dir * 1600,
        filter = player.GetAll()
    })

    return hor_trace.StartPos:Distance(hor_trace.HitPos) > 20 and trace2.StartPos:Distance(trace2.HitPos) > 14
end


local SitOnEntsMode = CreateConVar("sitting_ent_mode","3", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
--[[
	0 - Can't sit on any ents
	1 - Can't sit on any player ents
	2 - Can only sit on your own ents
	3 - Any
]]

local blacklist = SitAnywhere.ClassBlacklist
local model_blacklist = SitAnywhere.ModelBlacklist
function SitAnywhere.ValidSitTrace(ply, EyeTrace)
    if not EyeTrace.Hit then return false end
    if EyeTrace.HitPos:Distance(EyeTrace.StartPos) > 100 then return false end
    local t = hook.Run("CheckValidSit", ply, EyeTrace)

    if t == false or t == true then
        return t
    end

    if not EyeTrace.HitWorld and SitOnEntsMode:GetInt() == 0 then return false end
    if not EyeTrace.HitWorld and blacklist[string.lower(EyeTrace.Entity:GetClass())] then return false end
    if not EyeTrace.HitWorld and EyeTrace.Entity:GetModel() and model_blacklist[string.lower(EyeTrace.Entity:GetModel())] then return false end


    if EMETA.CPPIGetOwner and SitOnEntsMode:GetInt() >= 1 then
        if SitOnEntsMode:GetInt() == 1 then
            if not EyeTrace.HitWorld then
                local owner = EyeTrace.Entity:CPPIGetOwner()
                if type(owner) == "Player" and owner ~= nil and owner:IsValid() and owner:IsPlayer() then
                    return false
                end
            end
        elseif SitOnEntsMode:GetInt() == 2 then
            if not EyeTrace.HitWorld then
                local owner = EyeTrace.Entity:CPPIGetOwner()
                if type(owner) == "Player" and owner ~= nil and owner:IsValid() and owner:IsPlayer() and owner ~= ply then
                    return false
                end
            end
        end
    end
    return true
end
