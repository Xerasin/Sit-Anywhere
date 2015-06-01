local t = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
local function PlayerNotStuck(ply, pos)

	t.start = pos or ply:GetPos()
	t.endpos = t.start
	t.filter = ply
	return util.TraceEntity(t, ply).StartSolid == false
	
	
end

local function FindPassableSpace(ply, direction, step )
	local OldPos = ply:GetPos()
	local i = 0
	local origin = ply:GetPos()
	while ( i < 20 ) do
		origin = origin + step * direction
		if ( PlayerNotStuck(ply, origin) ) then
			return true, origin
		end
		i = i + 1
	end
	--ply:SetPos(OldPos)
	return false, OldPos
end

local function UnstuckPlayer(pl, ang)
	ply = pl

	NewPos = ply:GetPos()
	local OldPos = NewPos
	
	if ( !PlayerNotStuck( ply ) ) then
	
		local angle = ang or ply:GetAngles()
		
		local forward = angle:Forward()
		local right = angle:Right()
		local up = angle:Up()
		
		local SearchScale = 1
		local found
		found, NewPos = FindPassableSpace(pl, forward, -SearchScale )
		if ( not found ) then
			found, NewPos = FindPassableSpace(pl, right, SearchScale )
			if ( not found ) then
				found, NewPos = FindPassableSpace(pl, right, -SearchScale )
				if ( not found ) then
					found, NewPos = FindPassableSpace(pl, up, -SearchScale )
					if ( not found ) then
						found, NewPos = FindPassableSpace(pl, up, SearchScale )
						if ( not found ) then
							found, NewPos = FindPassableSpace(pl, forward, SearchScale )
							if ( not found ) then
								return false	
							end
						end
					end
				end
			end
		end
		
		if OldPos == NewPos then
			return true -- ???
		else
			ply:SetPos( NewPos )
			if SERVER and ply and ply:IsValid() and ply:GetPhysicsObject():IsValid() then
				if ply:IsPlayer() then
					ply:SetVelocity(vector_origin)
				end
				ply:GetPhysicsObject():SetVelocity(vector_origin) -- For some reason setting origin MAY apply some velocity so we're resetting it here.
			end
			return true
		end
		
	end
end

---------------------	
-- Helper functions
---------------------
local meta= FindMetaTable"Player" 

if meta.UnStuck then
	--ErrorNoHalt"Player:UnStuck implemented by other addon?"	
else


	function meta:UnStuck(...)
		return UnstuckPlayer(self, ...)
	end
end