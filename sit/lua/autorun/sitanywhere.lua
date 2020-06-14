if SERVER then
    AddCSLuaFile("sitanywhere/client/sit.lua")
    AddCSLuaFile("sitanywhere/ground_sit.lua")
    include("sitanywhere/server/sit.lua")
    include("sitanywhere/server/unstuck.lua")
    include("sitanywhere/ground_sit.lua")
else
    include("sitanywhere/client/sit.lua")
    include("sitanywhere/ground_sit.lua")
end