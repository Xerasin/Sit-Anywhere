import pygit2
import os 
from pprint import pprint
from subprocess import check_output
def run():
    dir_path = os.path.dirname(os.path.realpath(__file__))  + "\\"

    repository_path = pygit2.discover_repository(dir_path)
    repo = pygit2.Repository(repository_path)

    commitId = ("{}").format(repo.head.target)
    currentCommit = repo[commitId]
    currentWorkshop = repo.lookup_reference("refs/tags/workshop")

    lastWorkshop = commitId = ("{}").format(currentWorkshop.target)

    diffUrl = ("https://github.com/Xerasin/Sit-Anywhere/compare/{}..{}").format(lastWorkshop, commitId)
    if lastWorkshop == commitId:
        print("No changes!")
        return

    

    out = check_output("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmad.exe\" create -folder \".\\sit\" -out \".\\Sit.gma\"", shell=True)

    formatStr = """Update to [url=https://github.com/Xerasin/Sit-Anywhere/commit/{0}]{0}[/url]"""
    changelog = (formatStr).format(commitId, ahhh.message)

    if diffUrl != "":
        changelog = ("{} [url={}]Diff[/url]").format(changelog, diffUrl)
    pprint(changelog)

    out = check_output(("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmpublish.exe\" update -addon \".\Sit.gma\"  -id \"108176967\" -changes \"{}\"").format(changelog), shell=True)
    repo.create_reference("refs/tags/workshop", commitId)
run()