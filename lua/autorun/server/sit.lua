AddCSLuaFile("lua/autorun/client/sit.lua")
--Oh my god I can sit anywhere! by Xerasin--
local NextUse = setmetatable({},{__mode='k', __index=function() return 0 end})

local SitOnEntsMode = CreateConVar("sitting_ent_mode","3", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
--[[
	0 - Can't sit on any ents
	1 - Can't sit on any player ents
	2 - Can only sit on your own ents
	3 - Any
]]
local SittingOnPlayer = CreateConVar("sitting_can_sit_on_players","1",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local SittingOnPlayer2 = CreateConVar("sitting_can_sit_on_player_ent","1",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local PlayerDamageOnSeats = CreateConVar("sitting_can_damage_players_sitting","0",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local AllowWeaponsInSeat = CreateConVar("sitting_allow_weapons_in_seat","0",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local AdminOnly = CreateConVar("sitting_admin_only","0",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local FixLegBug = CreateConVar("sitting_fix_leg_bug","1",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local AntiPropSurf = CreateConVar("sitting_anti_prop_surf","1",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local AntiToolAbuse = CreateConVar("sitting_anti_tool_abuse","1",{FCVAR_NOTIFY, FCVAR_ARCHIVE})
local META = FindMetaTable("Player")
local EMETA = FindMetaTable("Entity")

local function ShouldAlwaysSit(ply)
	return hook.Run("ShouldAlwaysSit",ply)
end

local function Sit(ply, pos, ang, parent, parentbone,  func, exit)
	ply:ExitVehicle()

	local vehicle = ents.Create("prop_vehicle_prisoner_pod")
	vehicle:SetAngles(ang)
	pos = pos + vehicle:GetUp()*18
	vehicle:SetPos(pos)

	vehicle.playerdynseat=true
	vehicle.oldpos = vehicle:WorldToLocal(ply:GetPos())
	vehicle.oldang = vehicle:WorldToLocalAngles(ply:EyeAngles())

	vehicle:SetModel("models/nova/airboat_seat.mdl") -- DO NOT CHANGE OR CRASHES WILL HAPPEN

	vehicle:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
	vehicle:SetKeyValue("limitview","0")
	vehicle:Spawn()
	vehicle:Activate()
	
	if not IsValid(vehicle) or not IsValid(vehicle:GetPhysicsObject()) then 
		SafeRemoveEntity(vehicle)
		return false 
	end

	local phys = vehicle:GetPhysicsObject()
	-- Let's try not to crash
	vehicle:SetMoveType(MOVETYPE_PUSH)
	phys:Sleep()
	vehicle:SetCollisionGroup(COLLISION_GROUP_WORLD)

	vehicle:SetNotSolid(true)
	phys:Sleep()
	phys:EnableGravity(false)
	phys:EnableMotion(false)
	phys:EnableCollisions(false)
	phys:SetMass(1)

	vehicle:CollisionRulesChanged()

	-- Visibles
	vehicle:DrawShadow(false)
	vehicle:SetColor(Color(0,0,0,0))
	vehicle:SetRenderMode(RENDERMODE_TRANSALPHA)
	vehicle:SetNoDraw(true)

	vehicle.VehicleName = "Airboat Seat"
	vehicle.ClassOverride = "prop_vehicle_prisoner_pod"

	vehicle.PhysgunDisabled = true
	vehicle.m_tblToolsAllowed = {}
	vehicle.customCheck = function() return false end -- DarkRP plz

	if parent and parent:IsValid() then
		local r = math.rad(ang.yaw+90)
		vehicle.plyposhack = vehicle:WorldToLocal(pos + Vector(math.cos(r)*2,math.sin(r)*2,2))

		vehicle:SetParent(parent)
		vehicle.parent=parent
	else
		vehicle.OnWorld = true
	end

	local prev = ply:GetAllowWeaponsInVehicle()
	if prev then
		ply.sitting_allowswep = nil
	elseif AllowWeaponsInSeat:GetBool() then
		ply.sitting_allowswep = prev
		ply:SetAllowWeaponsInVehicle(true)
	end

	timer.Simple(0, function()
		ply:SetFOV(ply:GetFOV(),0) -- FOV Bug Fix.
	end)

	ply:EnterVehicle(vehicle)

	if PlayerDamageOnSeats:GetBool() then
		ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		ply:CollisionRulesChanged()
	end

	vehicle.removeonexit = true
	vehicle.exit = exit
	vehicle.sittingPly = ply
	
	local ang = vehicle:GetAngles()
	ply:SetEyeAngles(Angle(0,90,0))
	if func then
		func(ply)
	end

	return vehicle
end

local d=function(a,b) return math.abs(a-b) end

local SittingOnPlayerPoses =
{

	{
		Pos = Vector(-33,13,7),
		Ang = Angle(0,90,90),
		FindAng = 90,
	},
	{
		Pos = Vector(33,13,7),
		Ang = Angle(0,270,90),
		Func = function(ply)
			if(not ply:LookupBone("ValveBiped.Bip01_R_Thigh")) then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,90,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,90,0))
		end,
		OnExitFunc = function(ply)
			if(not ply:LookupBone("ValveBiped.Bip01_R_Thigh")) then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,0,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,0,0))
		end,
		FindAng = 270,
	},
	{
		Pos = Vector(0, 16, -15),
		Ang = Angle(0, 180, 0),
		Func = function(ply)
			if(not ply:LookupBone("ValveBiped.Bip01_R_Thigh")) then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(45,0,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(-45,0,0))
		end,
		OnExitFunc = function(ply)
			if(not ply:LookupBone("ValveBiped.Bip01_R_Thigh")) then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,0,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,0,0))
		end,
		FindAng = 0,
	},
	{
		Pos = Vector(0, 8, -18),
		Ang = Angle(0, 0, 0),
		FindAng = 180,
	},

}

local lookup={}
for k,v in pairs(SittingOnPlayerPoses) do
	table.insert(lookup,{v.FindAng,v})
	table.insert(lookup,{v.FindAng+360,v})
	table.insert(lookup,{v.FindAng-360,v})
end

local function FindPose(this,me)
	local avec=me:GetAimVector()
		avec.z=0
		avec:Normalize()
	local evec=this:GetRight()
		evec.z=0
		evec:Normalize()
	local derp=avec:Dot(evec)

	local avec=me:GetAimVector()
		avec.z=0
		avec:Normalize()
	local evec=this:GetForward()
		evec.z=0
		evec:Normalize()
	local herp=avec:Dot(evec)
	local v=Vector(derp,herp,0)
	local a=v:Angle()

	local ang=a.y
	assert(ang>=0)
	assert(ang<=360)
	ang=ang+90+180
	ang=ang%360

	table.sort(lookup,function(aa,bb)
		return 	d(ang,aa[1])<d(ang,bb[1])
	end)
	return lookup[1][2]
end


local blacklist = { ["gmod_wire_keyboard"] = true, ["prop_combine_ball"] = true}
local model_blacklist = {  -- I need help finding out why these crash
	--[[["models/props_junk/sawblade001a.mdl"] = true,
	["models/props_c17/furnitureshelf001b.mdl"] = true,
	["models/props_phx/construct/metal_plate1.mdl"] = true,
	["models/props_phx/construct/metal_plate1x2.mdl"] = true,
	["models/props_phx/construct/metal_plate1x2_tri.mdl"] = true,
	["models/props_phx/construct/metal_plate1_tri.mdl"] = true,
	["models/props_phx/construct/metal_plate2x2.mdl"] = true,
	["models/props_phx/construct/metal_plate2x2_tri.mdl"] = true,
	["models/props_phx/construct/metal_plate2x4.mdl"] = true,
	["models/props_phx/construct/metal_plate2x4_tri.mdl"] = true,
	["models/props_phx/construct/metal_plate4x4.mdl"] = true,
	["models/props_phx/construct/metal_plate4x4_tri.mdl"] = true,]]
}

function META.Sit(ply, EyeTrace, ang, parent, parentbone, func, exit)
	if EyeTrace == nil then
		EyeTrace = ply:GetEyeTrace()
	elseif type(EyeTrace)=="Vector" then
		return Sit(ply, EyeTrace, ang or Angle(0,0,0), parent, parentbone or 0, func, exit)
	end

	if not EyeTrace.Hit then return end
	if EyeTrace.HitPos:Distance(EyeTrace.StartPos) > 100 then return end

	local sitting_disallow_on_me = ply:GetInfoNum("sitting_disallow_on_me",0)==1
	if SittingOnPlayer:GetBool() then
		for k,v in pairs(ents.FindInSphere(EyeTrace.HitPos, 5)) do
			local safe=256
			while IsValid(v.SittingOnMe) and safe>0 do
				safe=safe - 1
				v=v.SittingOnMe
			end
			if(v:GetClass() == "prop_vehicle_prisoner_pod"
			and v:GetModel() ~= "models/vehicles/prisoner_pod_inner.mdl"
			and v:GetDriver()
			and v:GetDriver():IsValid()
			and not v.PlayerSitOnPlayer
			) then
				if v:GetDriver():GetInfoNum("sitting_disallow_on_me",0)~=0 then
					ply:ChatPrint(v:GetDriver():Name()..' has disabled sitting!')
					return
				end

				if sitting_disallow_on_me then
					ply:ChatPrint("You've disabled sitting on players!")
					return
				end

				local pose = FindPose(v,ply) -- SittingOnPlayerPoses[math.random(1, #SittingOnPlayerPoses)]
				local pos = v:GetDriver():GetPos()
				if(v.plyposhack) then
					pos = v:LocalToWorld(v.plyposhack)
				end
				local vec,ang = LocalToWorld(pose.Pos, pose.Ang, pos, v:GetAngles())
				if v:GetParent() == ply then return end
				local ent = Sit(ply, vec, ang, v, 0, pose.Func, pose.OnExitFunc)
				if ent and IsValid(ent) then
					ent.PlayerOnPlayer = true
					v.SittingOnMe = ent
				end

				return ent
			end
		end
	else
		for k,v in pairs(ents.FindInSphere(EyeTrace.HitPos, 5)) do
			if(v.removeonexit) then
				return
			end
		end
	end

	if(not EyeTrace.HitWorld and SitOnEntsMode:GetInt() == 0) then return end
	if(not EyeTrace.HitWorld and blacklist[string.lower(EyeTrace.Entity:GetClass())]) then return end
	if(not EyeTrace.HitWorld and EyeTrace.Entity:GetModel() and model_blacklist[string.lower(EyeTrace.Entity:GetModel())]) then return end
	if(EMETA.CPPIGetOwner) then
		if(SitOnEntsMode:GetInt() >= 1) then
			if(SitOnEntsMode:GetInt() == 1) then
				if(not EyeTrace.HitWorld) then
					local owner = EyeTrace.Entity:CPPIGetOwner()
					if(owner ~= nil and owner:IsValid() and owner:IsPlayer()) then
						return
					end
				end
			end
			if(SitOnEntsMode:GetInt() == 2) then
				if(not EyeTrace.HitWorld) then
					local owner = EyeTrace.Entity:CPPIGetOwner()
					if(owner ~= nil and owner:IsValid() and owner:IsPlayer() and owner ~= ply) then
						return
					end
				end
			end
		end
	end

	local EyeTrace2Tr = util.GetPlayerTrace(ply)
	EyeTrace2Tr.filter = ply
	EyeTrace2Tr.mins = Vector(-5,-5,-5)
	EyeTrace2Tr.maxs = Vector(5,5,5)
	local EyeTrace2 = util.TraceHull(EyeTrace2Tr)
	--if EyeTrace2.Entity ~= EyeTrace.Entity then return end

	local ang = EyeTrace.HitNormal:Angle() + Angle(-270, 0, 0)
	if(math.abs(ang.pitch) <= 15) then
		local ang = Angle()
		local filter = player.GetAll()
		local dists = {}
		local distsang = {}
		local ang_smallest_hori = nil
		local smallest_hori = 90000
		for I=0,360,15 do
			local rad = math.rad(I)
			local dir = Vector(math.cos(rad), math.sin(rad), 0)
			local trace = util.QuickTrace(EyeTrace.HitPos + dir*20 + Vector(0,0,5), Vector(0,0,-15000), filter)
			trace.HorizontalTrace = util.QuickTrace(EyeTrace.HitPos + Vector(0,0,5), (dir) * 1000, filter)
			trace.Distance  =  trace.StartPos:Distance(trace.HitPos)
			trace.Distance2 = trace.HorizontalTrace.StartPos:Distance(trace.HorizontalTrace.HitPos)
			trace.ang = I

			if((not trace.Hit or trace.Distance > 14) and (not trace.HorizontalTrace.Hit or trace.Distance2 > 20)) then
				table.insert(dists,trace)

			end
			if(trace.Distance2 < smallest_hori and (not trace.HorizontalTrace.Hit or trace.Distance2 > 3)) then
				smallest_hori = trace.Distance2
				ang_smallest_hori = I
			end
			distsang[I] = trace
		end
		local infront = ((ang_smallest_hori or 0) + 180) % 360

		if(ang_smallest_hori and distsang[infront].Hit and distsang[infront].Distance > 14 and smallest_hori <= 16) then
			local hori = distsang[ang_smallest_hori].HorizontalTrace
			ang.yaw = (hori.HitNormal:Angle().yaw - 90)
			local ent = nil
			if not EyeTrace.HitWorld then
				ent = EyeTrace.Entity
				if ent:IsPlayer() and not SittingOnPlayer2:GetBool() then return end

				if ent:IsPlayer() and ent:GetInfoNum("sitting_disallow_on_me",0)==1 then
					ply:ChatPrint(ent:Name()..' has disabled sitting!')
					return
				end
				if ent:IsPlayer() and sitting_disallow_on_me then
					ply:ChatPrint("You've disabled sitting on players!")
					return
				end
			end
			local vehicle = Sit(ply, EyeTrace.HitPos-Vector(0,0,20), ang, ent, EyeTrace.PhysicsBone or 0)
			return vehicle
		else
			table.sort(dists, function(a,b) return b.Distance < a.Distance end)
			local wants = {}
			local eyeang = ply:EyeAngles() + Angle(0,180,0)
			for I=1,#dists do
				local trace = dists[I]
				local behind = distsang[(trace.ang + 180) % 360]
				if behind.Distance2 > 3 then
					local cost = 0
					if(trace.ang % 90 ~= 0) then cost = cost + 12 end
					if(math.abs(eyeang.yaw - trace.ang) > 12) then
						cost = cost + 30
					end
					local tbl = {
						cost = cost,
						ang = trace.ang,
					}
					table.insert(wants, tbl)
				end
			end
			table.sort(wants,function(a,b) return b.cost > a.cost end)
			if(#wants == 0) then return end
			ang.yaw = (wants[1].ang - 90)
			local ent = nil
			if not EyeTrace.HitWorld then
				ent = EyeTrace.Entity
				if ent:IsPlayer() and not SittingOnPlayer2:GetBool() then return end
				if ent:IsPlayer() and IsValid(ent:GetVehicle()) and ent:GetVehicle():GetParent() == ply then return end

				if ent:IsPlayer() and ent:GetInfoNum("sitting_disallow_on_me",0)==1 then
					ply:ChatPrint(ent:Name()..' has disabled sitting!')
					return
				end
				if ent:IsPlayer() and sitting_disallow_on_me then
					ply:ChatPrint("You've disabled sitting on players!")
					return
				end
			end
			local vehicle = Sit(ply, EyeTrace.HitPos - Vector(0,0,20), ang, ent, EyeTrace.PhysicsBone or 0)

			return vehicle
		end

	end

end


local function sitcmd(ply)
	if ply:InVehicle() then return end
	if AdminOnly:GetBool() then
		if not ply:IsAdmin() then return end
	end
	local now=CurTime()

	if NextUse[ply]>now then return end

	-- do want to prevent player getting off right after getting in but how :C
	if ply:Sit() then
		NextUse[ply] = now + 1
	else
		NextUse[ply] = now + 0.1
	end
end

concommand.Add("sit",function(ply, cmd, args)
	sitcmd(ply)
end)

local function UndoSitting(self, ply)
	local prev = ply.sitting_allowswep
	if prev~=nil then
		ply.sitting_allowswep = nil
		ply:SetAllowWeaponsInVehicle(prev)
	end
	if(self.exit) then
		self.exit(ply)
	end
	self:Remove()
end


local PickupAllowed = {
	"GravGunPickupAllowed",
	"PhysgunPickup"
}
local cache = {}

local CheckSeat
function CheckSeat(ply, ent, tbl)
	
	if not ply:InVehicle() then return true end

	local vehicle = ply:GetVehicle()
	local parent = vehicle.parent

	if parent == ent then
		return false
	end

	for _,v in next, ent:GetChildren() do
		if IsValid(v) and not tbl[v] then
			tbl[v] = true
			if v ~= ent and CheckSeat(ply, v, tbl) == false then
				return false
			end
		end
	end
	local cEnts = constraint.GetAllConstrainedEntities(ent)
	if cEnts then
		for _,v in next, cEnts do
			if IsValid(v) and not tbl[v] then
				tbl[v] = true
				if v ~= ent and CheckSeat(ply, v, tbl) == false then
					return false
				end
			end
		end
	end
end
local function CheckSeat2(ply, ent)
	if not IsValid(ply:GetVehicle()) or not ply:GetVehicle().playerdynseat then return end
	
	if cache[ply:SteamID()] and cache[ply:SteamID()][ent:EntIndex()] and (CurTime() - cache[ply:SteamID()][ent:EntIndex()][1]) < 5 then
		return cache[ply:SteamID()][ent:EntIndex()][2]
	end
	cache[ply:SteamID()] = cache[ply:SteamID()] or {}
	cache[ply:SteamID()][ent:EntIndex()] = {CurTime(), CheckSeat(ply, ent, {})}
	return cache[ply:SteamID()][ent:EntIndex()][2]
end

for _,v in next, PickupAllowed do
	hook.Add(v, "SA_DontTouchYourself", function(ply, ent)
		if AntiPropSurf:GetBool() then
			if CheckSeat2(ply, ent) == false then return false end
		end
	end)
end

hook.Add("CanTool", "SA_DontTouchYourself", function(ply, tr)
	if AntiToolAbuse:GetBool() and IsValid(tr.Entity) then
		if CheckSeat2(ply, tr.Entity) == false then return false end
	end
end)

hook.Add("PlayerSwitchWeapon", "VehicleFOVFix", function(ply, ent)
	if IsValid(ply) and ply:InVehicle() then
		ply:SetFOV(ply:GetFOV(),0)
	end
end)

hook.Add("CanExitVehicle","Remove_Seat",function(self, ply)
	if not self.playerdynseat then return end
	if CurTime()<NextUse[ply] then return false end

	NextUse[ply] = CurTime() + 1

	local OnExit = function() UndoSitting(self, ply) end

	if ShouldAlwaysSit(ply) then
		-- Movie gamemode
		if ply.UnStuck then
			local pos,ang = LocalToWorld(Vector(0,36,20),Angle(),self:GetPos(),Angle(0,self:GetAngles().yaw,0))
		
			ply:UnStuck(pos, OnExit)
		else
			timer.Simple(0, function()
				ply:SetPos(self:GetPos()+Vector(0,0,36))
				OnExit()
			end)
		end
	else
		local oldpos, oldang = self:LocalToWorld(self.oldpos), self:LocalToWorldAngles(self.oldang)
		if ply.UnStuck then
			ply:UnStuck(oldpos, OnExit)
		else
			timer.Simple(0, function()
				ply:SetPos(oldpos)
				ply:SetEyeAngles(oldang)
				OnExit()
			end)
		end
	end
end)


hook.Add("AllowPlayerPickup","Nopickupwithalt",function(ply)
	if(ply:KeyDown(IN_WALK)) then
		return false
	end
end)

hook.Add("PlayerDeath","SitSeat",function(pl)
	for k,v in next, player.GetAll() do
		local veh = v:GetVehicle()
		if veh:IsValid() and veh.playerdynseat and veh:GetParent()==pl then
			veh:Remove()
		end
	end
end)

hook.Add("PlayerEnteredVehicle","unsits",function(pl,veh)
	pl:SetFOV(pl:GetFOV(),0) -- FOV Fix

	for k,v in next,player.GetAll() do
		if v~=pl and v:InVehicle() and v:GetVehicle():IsValid() and v:GetVehicle():GetParent()==pl then
			v:ExitVehicle()
		end
	end

	DropEntityIfHeld( veh )

	if veh:GetParent():IsValid() then
		DropEntityIfHeld( veh:GetParent() )
	end
end)

hook.Add("EntityRemoved","Sitting_EntityRemoved",function(ent)
	if FixLegBug:GetBool() then
		if ent.playerdynseat then
			if IsValid(ent.sittingPly) then
				UndoSitting(ent, ent.sittingPly)
			end
		end
	end
	
	for k,v in pairs(ents.FindByClass("prop_vehicle_prisoner_pod")) do
		if(v:GetParent() == ent) then
			if IsValid(v:GetDriver()) then
				v:GetDriver():ExitVehicle()
				v:Remove()
			end
		end
	end
end)

timer.Create("RemoveSeats",15,0,function()
	for k,v in pairs(ents.FindByClass("prop_vehicle_prisoner_pod")) do
		if(v.removeonexit and (v:GetDriver() == nil or not v:GetDriver():IsValid() or v:GetDriver():GetVehicle() ~= v --[[???]])) then
			v:Remove()
		end
	end
end)

hook.Add("InitPostEntity", "SAW_CompatFix", function()
	if hook.GetTable()["CanExitVehicle"]["PAS_ExitVehicle"] and PM_SendPassengers then
		local function IsSCarSeat( seat )
			if IsValid(seat) and seat.IsScarSeat and seat.IsScarSeat == true then
					return true
			end
			return false
		end
		hook.Add("CanExitVehicle", "PAS_ExitVehicle", function( veh, ply )
			if !IsSCarSeat( veh ) and not veh.playerdynseat and veh.vehicle then
				// L+R
				if ply:VisibleVec( veh:LocalToWorld(Vector(80, 0, 5) )) then
						ply:ExitVehicle()
						ply:SetPos( veh:LocalToWorld(Vector(75, 0, 5) ))
						if veh:GetClass() == "prop_vehicle_prisoner_pod" && !(ply == veh.vehicle:GetDriver()) then PM_SendPassengers( veh.vehicle:GetDriver() ) end
						return false
				end

				if ply:VisibleVec( veh:LocalToWorld(Vector(-80, 0, 5) )) then
						ply:ExitVehicle()
						ply:SetPos( veh:LocalToWorld(Vector(-75, 0, 5) ))
						if veh:GetClass() == "prop_vehicle_prisoner_pod" && !(ply == veh.vehicle:GetDriver()) then PM_SendPassengers( veh.vehicle:GetDriver() ) end
						return false
				end
			end
		end)
	end
end)