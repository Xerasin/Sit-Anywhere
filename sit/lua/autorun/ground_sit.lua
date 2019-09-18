
local tag = "ground_sit"

if SERVER then
	concommand.Add(tag, function(ply)
		if not ply.LastSit or ply.LastSit < CurTime() then
			ply:SetNWBool(tag, not ply:GetNWBool(tag))
			ply.LastSit = CurTime() + 1
		end
	end)
	AddCSLuaFile()
end

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
