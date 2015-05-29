if SERVER then
	AddCSLuaFile()
	return
end

local last = false
local lsit = 0
hook.Add("Think","Sitting_AltUse",function()
	if(last and !input.IsKeyDown(KEY_E)) then
		if input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT) then
			if lsit + 1 < CurTime() then
				RunConsoleCommand("sit")
				lsit = CurTime()
			end
		end
	end
	last = input.IsKeyDown(KEY_E)
end)