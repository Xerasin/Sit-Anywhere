
local newUI = CreateClientConVar("sitting_new_ui",                 "0.00", true, true)
local useAlt = CreateClientConVar("sitting_use_alt",               "1.00", true, true)
local sitTimer = CreateClientConVar("sitting_sit_timer",           "0.25", true, true)
local sitStartTimer = CreateClientConVar("sitting_sit_starttimer", "0.75", true, true)
local groundSit = CreateClientConVar("sitting_ground_sit",         "1.00", true, true)
local notOnMe = CreateClientConVar("sitting_disallow_on_me",       "0.00", true, true)

local activeTimer = {}




local function ShouldAlwaysSit(ply)
	return hook.Run("ShouldAlwaysSit",ply)
end


local function drawCircleThing( x, y, outerRadius, segments, startI, endI)
	local cir = {}
	local length = (endI - startI)
	local parts = length / segments

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, segments do
		local a = math.rad((parts * i) + startI)

		table.insert( cir, { x = x + math.sin( a * -1 ) * outerRadius, y = y + math.cos(  a * -1 ) * outerRadius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end
	
	surface.DrawPoly( cir )

end

surface.CreateFont('sitfont', {
	font = "Roboto Bk",
	size = 32,
	weight = 800,
})



hook.Add("HUDPaint", "SittingDrawHUD", function()
	if activeTimer.startTime then
		local sitTimerS = sitStartTimer:GetFloat()
		local timeElapsed = (SysTime() - activeTimer.startTime)

		if timeElapsed >= sitTimerS and not activeTimer.startTime2 then
			activeTimer.startTime2 = SysTime()
		end
		if activeTimer.startTime2 then
			local timeElapsed = (SysTime() - activeTimer.startTime2)
			local totalTime = activeTimer.timeToSit
			local timeLeft = totalTime - timeElapsed
			local timeRatio = timeLeft / totalTime
			if timeLeft >= 0 then
				if newUI:GetInt() == 2 then
					surface.SetTexture(0)
					surface.SetDrawColor(150, 150, 150, 150)
					drawCircleThing(ScrW()/2, ScrH()/2, 70, 90, 0, 360 * timeRatio * 2)
				elseif newUI:GetInt() == 1 then
					local width = 200
					surface.SetTexture(0)
					surface.SetDrawColor(150, 150, 150, 150)
					surface.DrawRect(ScrW()/2 - width * timeRatio /2, (ScrH()/4 * 1) - 1, width * timeRatio, 2)
				end

				
			else
				activeTimer = {}
				RunConsoleCommand("sit")
			end

			surface.SetFont('sitfont')
			local txt = "Sitting down..."
			local txtW, txtH = surface.GetTextSize(txt)
			surface.SetTextPos(ScrW()/2 - txtW/2, ScrH()/2 + txtH * (0.075 * timeRatio))
			surface.SetTextColor(Color(0, 0, 0, 255 * math.max(timeRatio, 0.1)))
			surface.DrawText(txt)
		end
		
	end
end)

hook.Add("KeyPress","seats_use",function(ply,key)
	if not IsFirstTimePredicted() and not game.SinglePlayer() then return end


	if key ~= IN_USE then return end

	local good = (useAlt:GetBool() and ply:KeyDown(IN_WALK)) or ShouldAlwaysSit(ply)
	if not good then return end
	if newUI:GetInt() == 2 or newUI:GetInt() == 1 then
		local EyeTrace = ply:GetEyeTrace()
		local ang = EyeTrace.HitNormal:Angle() + Angle(-270, 0, 0)
		if(math.abs(ang.pitch) <= 15) then
			if activeTimer.startTime == nil then
				activeTimer.startTime = SysTime()
				activeTimer.timeToSit = sitTimer:GetFloat()
				activeTimer.trace = ply:GetEyeTrace()
				activeTimer.drawType = newUI:GetInt()
			end
		end
	else
		activeTimer = {}
		RunConsoleCommand("sit")
	end
end)


hook.Add("KeyRelease","seats_use",function(ply,key)
	if not IsFirstTimePredicted() and not game.SinglePlayer() then return end
	if key ~= IN_USE then return end

	activeTimer = {}
end)