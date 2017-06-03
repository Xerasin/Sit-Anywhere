CreateClientConVar("sitting_disallow_on_me","0",true,true)

local function ShouldAlwaysSit(ply)
	return hook.Run("ShouldAlwaysSit",ply)
end

hook.Add("KeyPress","seats_use",function(ply,key)
	if not IsFirstTimePredicted() then return end
	
	if key ~= IN_USE then return end
	
	local walk=ply:KeyDown(IN_WALK) or ShouldAlwaysSit(ply)
	if not walk then return end
	
	RunConsoleCommand("sit")
end)
