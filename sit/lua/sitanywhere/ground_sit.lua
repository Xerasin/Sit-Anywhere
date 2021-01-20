
local tag = "ground_sit"

local sitting = 0


local time, speed = 1.5, 1.25
hook.Add("SetupMove", tag, function(ply, mv)
	local butts = mv:GetButtons()

	if not ply:GetNWBool(tag) then
		return
	end

	if CLIENT then
		sitting = math.Clamp(sitting - FrameTime() * speed, 0, time)
	end

	local getUp = bit.band(butts, IN_JUMP) == IN_JUMP or ply:GetMoveType() ~= MOVETYPE_WALK or ply:InVehicle() or not ply:Alive()

	if getUp then
		ply:SetNWBool(tag, false)
	end

	local move = bit.band(butts, IN_DUCK) == IN_DUCK -- do we want to move by ducking

	butts = bit.bor(butts, bit.bor(IN_JUMP, IN_DUCK)) -- enable ducking

	butts = bit.bxor(butts, IN_JUMP) -- disable jumpng

	if move then
		butts = bit.bor(butts, IN_WALK) -- enable walking

		butts = bit.bor(butts, IN_SPEED)
		butts = bit.bxor(butts, IN_SPEED) -- disable sprinting

		mv:SetButtons(butts)
		return
	end

	mv:SetButtons(butts)
	mv:SetSideSpeed(0)
	mv:SetForwardSpeed(0)
	mv:SetUpSpeed(0)
end)

hook.Add("CalcMainActivity", tag, function(ply, vel)
	local seq = ply:LookupSequence("pose_ducking_02")
	if ply:GetNWBool(tag) and seq and vel:Length2DSqr() < 1 then
		return ACT_MP_SWIM, seq
	else
		return
	end
end)


if SERVER then
	local AllowGroundSit = CreateConVar("sitting_allow_ground_sit","1",{FCVAR_ARCHIVE})
	hook.Add("HandleSit","GroundSit", function(ply, dists, EyeTrace)
		if #dists == 0 and ply:GetInfoNum("sitting_ground_sit", 1) == 1 and AllowGroundSit:GetBool() and ply:EyeAngles().p > 80 then
			local t = hook.Run("OnGroundSit", ply, EyeTrace)
			if t == false then
				return
			end

			if not ply:GetNWBool("ground_sit") then
				ply:ConCommand("ground_sit")
				return true
			end
		end
	end)

	concommand.Add("ground_sit", function(ply)
		if AllowGroundSit:GetBool() and (not ply.LastSit or ply.LastSit < CurTime()) then
			ply:SetNWBool("ground_sit", not ply:GetNWBool("ground_sit"))
			ply.LastSit = CurTime() + 1
		end
	end)
end
