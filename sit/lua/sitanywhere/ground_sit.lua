SitAnywhere = SitAnywhere or {}
SitAnywhere.GroundSit = true
local TAG = "SitAnyG_"

hook.Add("SetupMove", TAG .. "SetupMove", function(ply, mv)
	local butts = mv:GetButtons()

	if not ply:GetNWBool(TAG) then
		return
	end

	local getUp = bit.band(butts, IN_JUMP) == IN_JUMP or ply:GetMoveType() ~= MOVETYPE_WALK or ply:InVehicle() or not ply:Alive()

	if getUp then
		ply:SetNWBool(TAG, false)
	end

	local move = bit.band(butts, IN_DUCK) == IN_DUCK

	butts = bit.bxor(bit.bor(butts, bit.bor(IN_JUMP, IN_DUCK)), IN_JUMP)

	if move then
		butts =  bit.bxor(bit.bor(bit.bor(butts, IN_WALK), IN_SPEED), IN_SPEED)

		mv:SetButtons(butts)
		return
	end

	mv:SetButtons(butts)
	mv:SetSideSpeed(0)
	mv:SetForwardSpeed(0)
	mv:SetUpSpeed(0)
end)

hook.Add("CalcMainActivity", TAG .. "CalcMainActivity", function(ply, vel)
	local seq = ply:LookupSequence("pose_ducking_02")
	if ply:GetNWBool(TAG) and seq and vel:Length2DSqr() < 1 then
		return ACT_MP_SWIM, seq
	else
		return
	end
end)


if SERVER then
	local AllowGroundSit = CreateConVar("sitting_allow_ground_sit", "1", {FCVAR_ARCHIVE}, "Allows people to sit on the ground on your server", 0, 1)
	hook.Add("HandleSit", "GroundSit", function(ply, dists, EyeTrace)
		if #dists == 0 and ply:GetInfoNum("sitting_ground_sit", 1) == 1 and AllowGroundSit:GetBool() and ply:EyeAngles().p > 80 then
			local t = hook.Run("OnGroundSit", ply, EyeTrace)
			if t == false then
				return
			end

			if not ply:GetNWBool(TAG) then
				ply:SetNWBool(TAG, true)
				ply.LastSit = CurTime() + 1
				return true
			end
		end
	end)

	concommand.Add("ground_sit", function(ply)
		if AllowGroundSit:GetBool() and (not ply.LastSit or ply.LastSit < CurTime()) then
			ply:SetNWBool(TAG, not ply:GetNWBool(TAG))
			ply.LastSit = CurTime() + 1
		end
	end)
else
	CreateClientConVar("sitting_ground_sit", "1.00", true, true, "Toggles the ability for you to sit on the ground", 0, 1)
end
