CreateClientConVar("sitting_disallow_on_me","1",true,true)

local function ShouldAlwaysSit(ply)
	if not ms then return end
	if not ms.GetTheaterPlayers then return end
	if not ms.GetTheaterPlayers() then return end
	return ms.GetTheaterPlayers()[ply]
end

hook.Add("KeyPress","seats_use",function(ply,key)
	if key ~= IN_USE then return end
	
	local walk=ply:KeyDown(IN_WALK) or ShouldAlwaysSit(ply)
	if not walk then return end
	
	RunConsoleCommand("sit")
	
end)
