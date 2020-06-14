import pygit2
import os 
from pprint import pprint
from subprocess import check_output
dir_path = os.path.dirname(os.path.realpath(__file__))  + "\\"

repository_path = pygit2.discover_repository(dir_path)
repo = pygit2.Repository(repository_path)

commitId = repo.head.target

ahhh = repo[commitId]

out = check_output("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmad.exe\" create -folder \".\\sit\" -out \".\\Sit.gma\"", shell=True)
pprint(out)

formatStr = """Update to [url=https://github.com/Xerasin/Sit-Anywhere/commit/{0}]{0}[/url]"""
changelog = (formatStr).format(commitId, ahhh.message)

out = check_output(("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmpublish.exe\" update -addon \".\Sit.gma\"  -id \"108176967\" -changes \"{}\"").format(changelog), shell=True)
pprint(out)