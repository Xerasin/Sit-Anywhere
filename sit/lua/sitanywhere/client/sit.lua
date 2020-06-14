local useAlt = CreateClientConVar("sitting_use_alt",               "1.00", true, true)
local forceBinds = CreateClientConVar("sitting_force_binds",       "0", true, true)
local SittingNoAltServer = CreateConVar("sitting_force_no_alt","0", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})

CreateClientConVar("sitting_ground_sit",         "1.00", true, true)
CreateClientConVar("sitting_disallow_on_me",       "0.00", true, true)

local function ShouldSit(ply)
	return hook.Run("ShouldSit", ply)
end

hook.Add("KeyPress","seats_use",function(ply,key)
	if not IsFirstTimePredicted() and not game.SinglePlayer() then return end


	if key ~= IN_USE then return end
	local good = not useAlt:GetBool()
	local alwaysSit = ShouldSit(ply)

	if forceBinds:GetBool() then
		if useAlt:GetBool() and (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)) then
			good = true
		end
	else
		if useAlt:GetBool() and ply:KeyDown(IN_WALK) then
			good = true
		end
	end

	if SittingNoAltServer:GetBool() then
		good = true
	end

	if alwaysSit == true then
		good = true
	elseif alwaysSit == false then
		good = false
	end

	if not good then return end
	local trace = LocalPlayer():GetEyeTrace()

	if trace.Hit then
		RunConsoleCommand("sit")
	end
end)