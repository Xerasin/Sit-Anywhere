import pygit2
import os 
from pprint import pprint
from subprocess import check_output
def run():
    dir_path = os.path.dirname(os.path.realpath(__file__))  + "\\"

    repository_path = pygit2.discover_repository(dir_path)
    repo = pygit2.Repository(repository_path)

    commitId = ("{}").format(repo.head.target)
    
    lastUpdate = open("lastcommit.txt", "r")
    diffUrl = ""
    if lastUpdate:
        fileData = lastUpdate.read()
        if fileData == commitId:
            print("No changes!")
            return
        diffUrl = ("https://github.com/Xerasin/Sit-Anywhere/compare/{}..{}").format(fileData, commitId)

    ahhh = repo[commitId]

    out = check_output("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmad.exe\" create -folder \".\\sit\" -out \".\\Sit.gma\"", shell=True)

    formatStr = """Update to [url=https://github.com/Xerasin/Sit-Anywhere/commit/{0}]{0}[/url]"""
    changelog = (formatStr).format(commitId, ahhh.message)

    if diffUrl != "":
        changelog = ("{} [url={}]Diff[/url]").format(changelog, diffUrl)
    pprint(changelog)

    out = check_output(("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmpublish.exe\" update -addon \".\Sit.gma\"  -id \"108176967\" -changes \"{}\"").format(changelog), shell=True)
    
    lastUpdate = open("lastcommit.txt", "w")
    lastUpdate.write(commitId)
    lastUpdate.close()

run()