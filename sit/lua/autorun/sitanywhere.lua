if SERVER then
    AddCSLuaFile("sitanywhere/client/sit.lua")
    AddCSLuaFile("sitanywhere/helpers.lua")
    include("sitanywhere/helpers.lua")
    include("sitanywhere/server/sit.lua")
else
    include("sitanywhere/helpers.lua")
    include("sitanywhere/client/sit.lua")
end