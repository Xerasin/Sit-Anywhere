if CLIENT then return end
local TAG = "SitAny_"
SitAnywhere = SitAnywhere or {}

--Oh my god I can sit anywhere! by Xerasin--
local NextUse = setmetatable({}, {__mode = 'k', __index = function() return 0 end})

local SittingOnPlayer = CreateConVar("sitting_can_sit_on_players","1",{FCVAR_ARCHIVE}, "Allows players to sit on SitAnywhere sitting players", 0, 1)
local SittingOnPlayer2 = CreateConVar("sitting_can_sit_on_player_ent","1",{FCVAR_ARCHIVE}, "Allows players to sit on actual player entities", 0, 1)
local PlayerDamageOnSeats = CreateConVar("sitting_can_damage_players_sitting","0",{FCVAR_ARCHIVE}, "Allows damaging sitting players (hacky, not a true solution)", 0, 1)
local AllowWeaponsInSeat = CreateConVar("sitting_allow_weapons_in_seat","0",{FCVAR_ARCHIVE}, "Allows the use of weapons in SitAnywhere sitting", 0, 1)
local AdminOnly = CreateConVar("sitting_admin_only","0",{FCVAR_ARCHIVE}, "Locks sitting to admins only (uses PLAYER:IsAdmin)", 0, 1)
local AntiPropSurf = CreateConVar("sitting_anti_prop_surf","1",{FCVAR_ARCHIVE}, "Disables the use of the physgun on contraptions with someone sitting on them", 0, 1)
local AntiToolAbuse = CreateConVar("sitting_anti_tool_abuse","1",{FCVAR_ARCHIVE}, "Disables the use of the toolgun on contraptions with someone sitting on them", 0, 1)
local AllowSittingTightPlaces = CreateConVar("sitting_allow_tight_places","0",{FCVAR_ARCHIVE}, "Allows sitting in places where a player cannot physically stand, allows easier clipping", 0, 1)
CreateConVar("sitting_force_no_walk","0", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Disables the need for using walk to sit anywhere on your server", 0, 1)

local META = FindMetaTable("Player")

util.AddNetworkString("SitAnywhere")

net.Receive("SitAnywhere", function(len, ply)
	local netID = net.ReadInt(4)
	if netID == SitAnywhere.NET.SitWantedAng then
		local wantedAng, traceStart, traceNormal = net.ReadFloat(), net.ReadVector(), net.ReadVector()

		if traceStart:Distance(ply:EyePos()) > 10 then return end
		local trace = util.TraceLine({
			start = traceStart,
			endpos = traceStart + traceNormal * 12000,
			filter = player.GetAll()
		})

		ply:Sit(trace, nil, nil, nil, nil, nil, wantedAng)
	elseif netID == SitAnywhere.NET.SitRequestExit then
		ply:ExitSit()
	end
end)

local function Sit(ply, pos, ang, parent, parentbone, func, exit)
	if IsValid(ply:GetVehicle()) then
		local veh = ply:GetVehicle()
		if veh:GetClass() == "prop_vehicle_prisoner_pod" and IsValid(veh.holder) then
			SafeRemoveEntity(veh.holder)
		end
		ply:ExitVehicle()
	end


	--[=[local function getHolders(pl)
		local holders = {}
		for _, v in pairs(ents.FindByClass("sit_holder")) do
			if v.GetTargetPlayer and v:GetTargetPlayer() == pl then
				table.insert(holders, v)
			end
		end
		return holders
	end

	for _, holder in next, getHolders(ply) do
		SafeRemoveEntityDelayed(holder, 0.1)
	end]=]

	local vehicle = ents.Create("prop_vehicle_prisoner_pod")
	local t = hook.Run("OnPlayerSit", ply, pos, ang, parent or NULL, parentbone, vehicle)

	if t == false then
		SafeRemoveEntity(vehicle)
		return false
	end

	vehicle:SetAngles(ang)
	pos = pos + vehicle:GetUp() * 18
	vehicle:SetPos(pos)

	vehicle.playerdynseat = true
	vehicle:SetNWBool("playerdynseat", true)
	vehicle.sittingPly = ply
	vehicle.oldpos = vehicle:WorldToLocal(ply:GetPos())
	vehicle.wasCrouching = ply:Crouching()

	vehicle:SetModel("models/nova/airboat_seat.mdl") -- DO NOT CHANGE OR CRASHES WILL HAPPEN

	vehicle:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
	vehicle:SetKeyValue("limitview", "0")
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
		local r = math.rad(ang.yaw + 90)
		vehicle.plyposhack = vehicle:WorldToLocal(pos + Vector(math.cos(r) * 2, math.sin(r) * 2, 2))

		--[[if parent:IsPlayer() or SitAnywhere.DoNotParent[parent:GetClass()] then
			vehicle.holder = ents.Create("sit_holder")
			vehicle.holder:SetPos(pos)
			vehicle.holder:SetAngles(ang)
			vehicle.holder:Spawn()
			vehicle.holder:SetTargetEnt(parent, vehicle, pos, ang)
			vehicle:SetParent(vehicle.holder)

			parent.holder = vehicle.holder
		else
			vehicle:SetParent(parent)
		end]]

		vehicle:SetParent(parent)
		vehicle.parent = parent
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

	ply:EnterVehicle(vehicle)

	if PlayerDamageOnSeats:GetBool() then
		ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		ply:CollisionRulesChanged()
	end

	if func then
		func(ply)
	end

	ply.seatExit = exit
	ply:SetEyeAngles(Angle(0,90,0))

	return vehicle
end

local d = function(a,b) return math.abs(a-b) end

local SittingOnPlayerPoses =
{

	{
		Pos = Vector(-33,13,7),
		Ang = Angle(0,90,90),
		Func = function(ply)
			if not ply:LookupBone("ValveBiped.Bip01_R_Thigh") then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,90,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,90,0))
		end,
		OnExitFunc = function(ply)
			if not ply:LookupBone("ValveBiped.Bip01_R_Thigh") then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,0,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,0,0))
		end,
		FindAng = 90,
	},
	{
		Pos = Vector(33,13,7),
		Ang = Angle(0,270,90),
		Func = function(ply)
			if not ply:LookupBone("ValveBiped.Bip01_R_Thigh") then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,90,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,90,0))
		end,
		OnExitFunc = function(ply)
			if not ply:LookupBone("ValveBiped.Bip01_R_Thigh") then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,0,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,0,0))
		end,
		FindAng = 270,
	},
	{
		Pos = Vector(0, 16, -15),
		Ang = Angle(0, 180, 0),
		Func = function(ply)
			if not ply:LookupBone("ValveBiped.Bip01_R_Thigh") then return end
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(45,0,0))
			ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(-45,0,0))
		end,
		OnExitFunc = function(ply)
			if not ply:LookupBone("ValveBiped.Bip01_R_Thigh") then return end
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

local lookup = {}
for k,v in pairs(SittingOnPlayerPoses) do
	table.insert(lookup, {v.FindAng, v})
	table.insert(lookup, {v.FindAng + 360, v})
	table.insert(lookup, {v.FindAng - 360, v})
end

local function FindPose(this,me)
	local avec = me:GetAimVector()
		avec.z = 0
		avec:Normalize()
	local evec = this:GetRight()
		evec.z = 0
		evec:Normalize()
	local derp = avec:Dot(evec)

	local avec2 = me:GetAimVector()
		avec2.z = 0
		avec2:Normalize()
	local evec2 = this:GetForward()
		evec2.z = 0
		evec2:Normalize()
	local herp = avec2:Dot(evec2)
	local v = Vector(derp,herp,0)
	local a = v:Angle()

	local ang = a.y
	assert(ang >= 0)
	assert(ang <= 360)
	ang = ang + 90 + 180
	ang = ang % 360

	table.sort(lookup,function(aa,bb)
		return 	d(ang,aa[1]) < d(ang,bb[1])
	end)
	return lookup[1][2]
end

function META.Sit(ply, EyeTrace, ang, parent, parentbone, func, exit, wantedAng)
	if EyeTrace == nil then
		EyeTrace = ply:GetEyeTrace()
	elseif type(EyeTrace) == "Vector" then
		return Sit(ply, EyeTrace, ang or Angle(0,0,0), parent, parentbone or 0, func, exit)
	end

	local valid, ent = SitAnywhere.ValidSitTrace(ply, EyeTrace)
	if not valid then return end
	local surfaceAng = EyeTrace.HitNormal:Angle() + Angle(-270, 0, 0)
	ang = surfaceAng

	if wantedAng and math.abs(surfaceAng.pitch) <= 15 then
		ent = EyeTrace.Entity
		if wantedAng and (EyeTrace.HitWorld or not ent:IsPlayer()) then
			if SitAnywhere.CheckValidAngForSit(EyeTrace.HitPos, EyeTrace.HitNormal:Angle(), wantedAng) then
				ang.yaw = wantedAng + 90
			else
				return
			end
		end
		return Sit(ply, EyeTrace.HitPos - Vector(0, 0, 23), ang, ent, EyeTrace.PhysicsBone or 0)
	end

	if SittingOnPlayer:GetBool() then -- Sitting on SITTING Players
		local veh
		if not EyeTrace.HitWorld and IsValid(EyeTrace.Entity) and EyeTrace.Entity:IsPlayer() and IsValid(EyeTrace.Entity:GetVehicle()) and EyeTrace.Entity:GetVehicle().playerdynseat then
			local safe = 256

			veh = EyeTrace.Entity:GetVehicle()
			while IsValid(veh.SittingOnMe) and IsValid(veh.SittingOnMe:GetDriver()) and safe > 0 do
				safe = safe - 1
				veh = veh.SittingOnMe
			end
		else
			for k, v in pairs(ents.FindInSphere(EyeTrace.HitPos, 12)) do
				local safe = 256

				veh = v
				while IsValid(veh.SittingOnMe) and IsValid(veh.SittingOnMe:GetDriver()) and safe > 0 do
					safe = safe - 1
					veh = veh.SittingOnMe
				end
			end
		end

		if IsValid(veh)
			and veh:GetClass() == "prop_vehicle_prisoner_pod"
			and veh:GetModel() ~= "models/vehicles/prisoner_pod_inner.mdl"
			and veh:GetDriver()
			and veh:GetDriver():IsValid()
			and not veh.PlayerSitOnPlayer
		then
			if IsValid(veh.holder) and veh.holder.GetTargetPlayer and veh.holder:GetTargetPlayer() == ply then return end
			local findSeat

			function findSeat(tVeh, depth)
				depth = (depth or 0) + 1
				if IsValid(tVeh:GetParent()) and tVeh:GetParent():GetClass() == "sit_holder" and tVeh:GetParent():GetTargetPlayer() == ply then
					return true
				end
				if depth < 50 and IsValid(tVeh:GetParent()) then
					return findSeat(tVeh:GetParent(), depth)
				end
				return false
			end
			if findSeat(veh) then return end

			if veh:GetDriver():GetInfoNum("sitting_allow_on_me", 1) == 0 then
				ply:ChatPrint(veh:GetDriver():Name() .. " has disabled sitting!")
				return false
			end

			local pose = FindPose(veh, ply) -- SittingOnPlayerPoses[math.random(1, #SittingOnPlayerPoses)]
			local pos = veh:GetDriver():GetPos()

			if veh.plyposhack then
				pos = veh:LocalToWorld(veh.plyposhack)
			end

			local vec, ang2 = LocalToWorld(pose.Pos, pose.Ang, pos, veh:GetAngles())

			if veh:GetParent() == ply then return false end

			ent = Sit(ply, vec, ang2, veh, 0, pose.Func, pose.OnExitFunc)

			--[[ent:SetNWVector("SitPosePos", veh:WorldToLocal(ent:GetPos()))
			ent:SetNWVector("SitPoseAng", veh:WorldToLocalAngles(ent:GetAngles()))
			ent:SetNWBool("SitPose", true)]]

			if ent and IsValid(ent) then
				ent.PlayerOnPlayer = true
				veh.SittingOnMe = ent
			end

			return true, ent
		end
	else
		for k, v in pairs(ents.FindInSphere(EyeTrace.HitPos, 5)) do
			if v.playerdynseat then
				return false
			end
		end
	end

	local shouldSitOnPlayer = (ply.IsFlying and ply:IsFlying()) or EyeTrace.Entity == ply:GetGroundEntity() or ply:GetMoveType() == MOVETYPE_NOCLIP
	if IsValid( EyeTrace.Entity ) and EyeTrace.Entity:IsPlayer() and SittingOnPlayer2:GetBool() and shouldSitOnPlayer then
		ent = EyeTrace.Entity
		if IsValid(ent:GetVehicle()) then return end
		if IsValid(ent.holder) and ent.GetTargetPlayer and ent:GetTargetPlayer() == ent then return end
		if ent:GetInfoNum("sitting_allow_on_me", 1) == 0 then
			ply:ChatPrint(ent:Name() .. " has disabled sitting!")
			return
		end

		local min, max = ent:GetCollisionBounds()
		local zadjust = math.abs( min.z ) + math.abs( max.z )
		local seatPos = ent:GetPos() + Vector( 0, 0, 10 + zadjust / 2)

		--[[do
			local bone = ent:LookupBone("ValveBiped.Bip01_Neck1")
			if bone then
				seatPos = ent:GetBonePosition(bone) - Vector(0, 0, 9)
			end
		end]]

		local vehicle = Sit(ply, seatPos, ply:GetAngles(), ent, EyeTrace.PhysicsBone or 0)

		return vehicle
	end

	if math.abs(surfaceAng.pitch) <= 15 then
		ang = Angle()
		local sampleResolution = 24
		local dists, distsang, ang_smallest_hori, smallest_hori = SitAnywhere.GetAreaProfile(EyeTrace.HitPos, sampleResolution, false)
		local infront = ((ang_smallest_hori or 0) + 180) % 360


		local cancelSit, seat = hook.Run("HandleSit", ply, dists, EyeTrace)
		if cancelSit then
			return seat
		end

		if ang_smallest_hori and distsang[infront].Hit and distsang[infront].Distance > 14 and smallest_hori <= 16 then
			local hori = distsang[ang_smallest_hori].HorizontalTrace
			ang.yaw = (hori.HitNormal:Angle().yaw - 90)

			if not EyeTrace.HitWorld then
				ent = EyeTrace.Entity
				if ent:IsPlayer() then
					if not SittingOnPlayer2:GetBool() then return end

					if ent:GetInfoNum("sitting_allow_on_me", 1) == 0 then
						ply:ChatPrint(ent:Name() .. " has disabled sitting!")
						return
					end

					if IsValid(ent:GetVehicle()) then return end
				end
			end
			return Sit(ply, EyeTrace.HitPos - Vector(0, 0, 23), ang, ent, EyeTrace.PhysicsBone or 0)
		else
			table.sort(dists, function(a,b) return b.Distance < a.Distance end)
			local wants = {}
			local eyeang = ply:EyeAngles() + Angle(0, 180, 0)
			for I = 1, #dists do
				local trace = dists[I]
				local behind = distsang[(trace.ang + 180) % 360]
				if behind.Distance2 > 3 then
					table.insert(wants, {
						cost = math.abs(eyeang.yaw - trace.ang),
						ang = trace.ang,
					})
				end
			end

			table.sort(wants,function(a,b) return b.cost > a.cost end)
			if #wants == 0 then return end
			ang.yaw = (wants[1].ang - 90)
			ent = nil

			if not EyeTrace.HitWorld then
				ent = EyeTrace.Entity
				if ent:IsPlayer() then
					if not SittingOnPlayer2:GetBool() then return end
					if IsValid(ent:GetVehicle()) and ent:GetVehicle():GetParent() == ply then return end

					if ent:GetInfoNum("sitting_allow_on_me", 1) == 0 then
						ply:ChatPrint(ent:Name() .. " has disabled sitting!")
						return
					end
				end
			end
			return Sit(ply, EyeTrace.HitPos - Vector(0, 0, 23), ang, ent, EyeTrace.PhysicsBone or 0)
		end

	end
end

local function checkAllowSit(ply)
	local allowSit = hook.Run("ShouldAllowSit", ply)


	local bottom, top = ply:GetHull()
	local diff = top.Z - bottom.Z
	local trace = util.QuickTrace(ply:GetPos(), Vector(0, 0, diff), player.GetAll())

	if not AllowSittingTightPlaces:GetBool() and trace.HitWorld then return false end
	if allowSit == false or allowSit == true then
		return allowSit
	end

	--if ply:Crouching() then return false end

	if AdminOnly:GetBool() and not ply:IsAdmin() then
		return false
	end

	return true
end

local function sitcmd(ply)
	if not IsValid(ply) then return end
	if ply:InVehicle() then return end

	if not checkAllowSit(ply) then return end


	local now = CurTime()

	if NextUse[ply] > now then return end

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

local function UndoSitting(ply)
	if not IsValid(ply) then return end

	local prev = ply.sitting_allowswep
	if prev ~= nil then
		ply.sitting_allowswep = nil
		ply:SetAllowWeaponsInVehicle(prev)
	end

	if PlayerDamageOnSeats:GetBool() then
		ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		ply:CollisionRulesChanged()
	end

	if ply.seatExit then
		ply.seatExit(ply)
		ply.seatExit = nil
	end
end





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

local cache = setmetatable({}, {__mode = 'k'})
local function CheckSeat2(ply, ent)
	if not IsValid(ply:GetVehicle()) or not ply:GetVehicle().playerdynseat then return end

	if cache[ply] and cache[ply][ent] and (CurTime() - cache[ply][ent][1]) < 5 then
		return cache[ply][ent][2]
	end

	cache[ply] = cache[ply] or setmetatable({}, {__mode = 'k'})
	cache[ply][ent] = {CurTime(), CheckSeat(ply, ent, {})}
	return cache[ply][ent][2]
end


local PickupAllowed = {
	"GravGunPickupAllowed",
	"PhysgunPickup"
}
for _,v in next, PickupAllowed do
	hook.Add(v, TAG .. v, function(ply, ent)
		if AntiPropSurf:GetBool() and CheckSeat2(ply, ent) == false then
			return false
		end
	end)
end

hook.Add("CanTool", TAG .. "CanTool", function(ply, tr)
	if AntiToolAbuse:GetBool() and IsValid(tr.Entity) and CheckSeat2(ply, tr.Entity) == false then
		return false
	end
end)


hook.Add("CanExitVehicle", TAG .. "CanExitVehicle", function(seat, ply)
	if not IsValid(seat) or not IsValid(ply) then return end
	if not seat.playerdynseat then return end

	if CurTime() < NextUse[ply] then return false end
end)

hook.Add("PlayerLeaveVehicle", TAG .. "PlayerLeaveVehicle", function(ply, seat)
	if not IsValid(seat) or not IsValid(ply) then return end
	if not seat.playerdynseat then return end

	local oldpos = seat:LocalToWorld(seat.oldpos)
	ply:SetPos(oldpos)
	if ply.UnStuck then
		ply:UnStuck()
	end

	for _, v in next, seat:GetChildren() do
		if IsValid(v) and v.playerdynseat and IsValid(v.sittingPly) then
			v.sittingPly:ExitVehicle()
		end
	end

	SafeRemoveEntityDelayed(seat, 1)
	UndoSitting(ply)
end)

hook.Add("AllowPlayerPickup", TAG .. "AllowPlayerPickup", function(ply)
	if ply:KeyDown(IN_WALK) then
		return false
	end
end)

hook.Add("PlayerDeath", TAG .. "PlayerDeath", function(pl)
	local veh = pl:GetVehicle()
	if IsValid(veh) and veh.playerdynseat then
		SafeRemoveEntity(veh)
	end

	for k, v in next, pl:GetChildren() do
		if IsValid(v) and v.playerdynseat and IsValid(v.sittingPly) then
			v.sittingPly:ExitVehicle()
		end
	end
end)

hook.Add("PlayerEnteredVehicle", TAG .. "PlayerEnteredVehicle",function(pl, veh)
	for k,v in next, pl:GetChildren() do
		if IsValid(v) and v.playerdynseat and IsValid(v.sittingPly) then
			v.sittingPly:ExitVehicle()
		end
	end

	DropEntityIfHeld( veh )

	local parent = veh:GetParent()
	if IsValid(parent) then
		DropEntityIfHeld(parent)
	end
end)

hook.Add("EntityRemoved", TAG .. "EntityRemoved", function(ent)
	if ent.playerdynseat and IsValid(ent.sittingPly) then
		UndoSitting(ent.sittingPly)
	end

	for _, v in next, ent:GetChildren() do
		if IsValid(v) and v.playerdynseat and IsValid(v.sittingPly) then
			v.sittingPly:ExitVehicle()
		end
	end
end)

timer.Create(TAG .. "RemoveSeats", 15, 0, function()
	for k,v in pairs(ents.FindByClass("prop_vehicle_prisoner_pod")) do
		if v.playerdynseat and (not IsValid(v.sittingPly) or v:GetDriver() == nil or not v:GetDriver():IsValid() or v:GetDriver():GetVehicle() ~= v --[[???]]) then
			v:Remove()
		end
	end
end)

--[=[hook.Add("InitPostEntity", "SAW_CompatFix", function()
	if hook.GetTable()["CanExitVehicle"]["PAS_ExitVehicle"] and PM_SendPassengers then
		local function IsSCarSeat( seat )
			if IsValid(seat) and seat.IsScarSeat and seat.IsScarSeat == true then
					return true
			end
			return false
		end
		hook.Add("CanExitVehicle", "PAS_ExitVehicle", function( veh, ply )
			if not IsSCarSeat( veh ) and not veh.playerdynseat and veh.vehicle then
				-- L+R
				if ply:VisibleVec( veh:LocalToWorld(Vector(80, 0, 5) )) then
						ply:ExitVehicle()
						ply:SetPos( veh:LocalToWorld(Vector(75, 0, 5) ))
						if veh:GetClass() == "prop_vehicle_prisoner_pod" and ply ~= veh.vehicle:GetDriver() then PM_SendPassengers( veh.vehicle:GetDriver() ) end
						return false
				end

				if ply:VisibleVec( veh:LocalToWorld(Vector(-80, 0, 5) )) then
						ply:ExitVehicle()
						ply:SetPos( veh:LocalToWorld(Vector(-75, 0, 5) ))
						if veh:GetClass() == "prop_vehicle_prisoner_pod" and ply ~= veh.vehicle:GetDriver() then PM_SendPassengers( veh.vehicle:GetDriver() ) end
						return false
				end
			end
		end)
	end
end)]=]