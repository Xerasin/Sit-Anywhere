local t = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
local function PlayerNotStuck(ply, pos)
	t.start = pos
	t.endpos = pos
	t.filter = ply
	return util.TraceEntity(t, ply).Hit == false
end

local meta= FindMetaTable("Player" )
function meta:UnStuck(pos, callback)
	if self.unstucking then return end
	if not pos then pos = self:GetPos() end
	if PlayerNotStuck( self, pos ) then
		self:ExitVehicle()
		if callback then callback() end
		timer.Simple(0, function()
			if self:IsValid() then
				self:SetPos(pos)
			end
		end)
	else
		self.unstucking = true

		local origin = self:GetPos()
		local phi = math.rad(self:GetAngles().yaw)
		local cosphi, sinphi = math.cos(phi), math.sin(phi)

		--Spherical coordinates
		local ranges = {
			{38, 118, 20}, --rho
			{0.14, 0.94, 0.2}, --theta
			{0.14, 3.14, 0.5}, --phi
		}
		local state = {ranges[1][1], ranges[2][1], ranges[3][1]}
		local hookname = "Unstucking"..self:EntIndex()

		local function UnStuck(pos)
			self.unstucking = nil
			hook.Remove("Think", hookname)
			self:ExitVehicle()
			if callback then callback() end
			if pos then
				timer.Simple(0, function()
					if self:IsValid() then
						self:SetPos(pos)
					end
				end)
			end
		end

		hook.Add("Think", hookname, function()
			if not self:IsValid() then hook.Remove("Think", hookname) return end
			local i, k, j = state[1], state[2], state[3]
			local sinj, cosj = math.sin(j), math.cos(j)
			local sink, cosk = math.sin(k), math.cos(k)

			--Check 4 directions per frame
			local v1 = Vector( i*sinj*cosk, i*sinj*sink, i*cosj )
			local v2 = Vector( -v1.x, v1.y, v1.z )
			local v3 = Vector( v1.x, v1.y, -v1.z )
			local v4 = Vector( -v1.x, v1.y, -v1.z )

			--Rotate by phi
			local function rotate(v)
				local x, y = cosphi*v.x - sinphi*v.y, cosphi*v.y + sinphi*v.x
				v.x = x
				v.y = y
			end
			rotate(v1) rotate(v2) rotate(v3) rotate(v4)

			--Check if open
			if PlayerNotStuck( self, origin + v1 ) then
				UnStuck( origin + v1 )
			elseif PlayerNotStuck( self, origin + v2 ) then
				UnStuck( origin + v2 )
			elseif PlayerNotStuck( self, origin + v3 ) then
				UnStuck( origin + v3 )
			elseif PlayerNotStuck( self, origin + v4 ) then
				UnStuck( origin + v4 )
			else
				-- Increment state. This is a digit counter loop. Each state variable is considered a digit.
				local stage = 3
				while true do
					state[stage] = state[stage] + ranges[stage][3]
					if state[stage] > ranges[stage][2] then
						state[stage] = ranges[stage][1]
						stage = stage - 1
						if stage == 0 then
							UnStuck()
							break
						end
					else
						break
					end
				end
			end
		end)
	end
end