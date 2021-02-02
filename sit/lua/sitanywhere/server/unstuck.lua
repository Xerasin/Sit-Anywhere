
do -- is stuck checker

	local output = {}
	local pl_filt
	local filter_tbl  = {}
	local function filter_func(e)
		if e == pl_filt then return false end
		local cg = e:GetCollisionGroup()

		return
			cg ~= 15 -- COLLISION_GROUP_PASSABLE_DOOR
		and cg ~= 11 -- COLLISION_GROUP_WEAPON
		and cg ~= 1 -- COLLISION_GROUP_DEBRIS
		and cg ~= 2 -- COLLISION_GROUP_DEBRIS_TRIGGER
		and cg ~= 20 -- COLLISION_GROUP_WORLD

	end
	local t = {output = output ,mask = MASK_PLAYERSOLID}
	FindMetaTable"Player".IsStuck = function(pl,fast,pos)
		t.start = pos or pl:GetPos()
		t.endpos = t.start
		if fast then
			filter_tbl[1] = pl
			t.filter = filter_tbl
		else
			pl_filt = pl
			t.filter = filter_func
		end


		util.TraceEntity(t,pl)
		return output.StartSolid,output.Entity,output
	end

end


local ply = nil

local NewPos = nil

local dirs = {}

local function FindPassableSpace(n, direction, step)
	local origin = dirs[n]
	if not origin then
		origin = ply:GetPos()
		dirs[n] = origin
	end

	--for i=0,100 do
		--origin = VectorMA( origin, step, direction )
		origin:Add(step * direction)

		if not ply:IsStuck(false,origin) then
			ply:SetPos(origin)
			if not ply:IsStuck(false) then
				NewPos = ply:GetPos()
				return true
			end
		end

	--end

	return false
end

--[[
	Purpose: Unstucks player ,
	Note: Very expensive to call, you have been warned!
]]

--local forward = Vector(1,0,0)
local right = Vector(0,1,0)
local up = Vector(0,0,1)
local function UnstuckPlayer(pl)
	ply = pl
	NewPos = ply:GetPos()
	local OldPos = NewPos

	dirs = {}
	if ply:IsStuck() then
		local SearchScale = 1 -- Increase and it will unstuck you from even harder places but with lost accuracy. Please, don't try higher values than 12
		local ok
		local forward = ply:GetAimVector()
		forward.z = 0
		forward:Normalize()
		right = forward:Angle():Right()
		for i = 1, 10 do
			ok = true
			if not FindPassableSpace(1, forward, SearchScale * i)
				and not FindPassableSpace(2, right, SearchScale * i)
				and not FindPassableSpace(3, right, -SearchScale * i)
				and not FindPassableSpace(4, up, SearchScale * i)
				and not FindPassableSpace(5, up, -SearchScale * i)
				and not FindPassableSpace(6, forward, -SearchScale * i) then
					ok = false
			end
			if ok then break end
		end

		if not ok then return false end

		if OldPos == NewPos then
			ply:SetPos(NewPos)
			return true
		else
			ply:SetPos(NewPos)

			if SERVER and ply and ply:IsValid() and ply:GetPhysicsObject():IsValid() then
				ply:SetVelocity(-ply:GetVelocity())
			end

			return true
		end
	end
end

util.UnstuckPlayer = UnstuckPlayer

local Player = FindMetaTable"Player"

function Player:UnStuck()
	return UnstuckPlayer(self)
end