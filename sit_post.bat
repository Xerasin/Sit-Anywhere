"D:\Program Files (x86)\Steam\SteamApps\common\GarrysMod\bin\gmad.exe" create -folder ".\sit" -out ".\Sit.gma"
set /p id="ChangeLog: "
"D:\Program Files (x86)\Steam\SteamApps\common\GarrysMod\bin\gmpublish" update -addon ".\Sit.gma" -id "108176967" -changes "%id%"
