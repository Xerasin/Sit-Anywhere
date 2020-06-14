import pygit2
import os 
from pprint import pprint
from subprocess import check_output

githubUrl = "https://github.com/Xerasin/Sit-Anywhere"

def run():
    dir_path = os.path.dirname(os.path.realpath(__file__))  + "\\"
    repository_path = pygit2.discover_repository(dir_path)
    repo = pygit2.Repository(repository_path)

    currentWorkshop = repo.lookup_reference("refs/tags/workshop")

    currentCommitID = ("{}").format(repo.head.target)
    workshopCommitID = ("{}").format(currentWorkshop.target)

    diffUrl = ("{}/compare/{}..{}").format(githubUrl, workshopCommitID, currentCommitID)
    if workshopCommitID == currentCommitID:
        print("No changes!")
        return

    out = check_output("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmad.exe\" create -folder \".\\sit\" -out \".\\Sit.gma\"", shell=True)

    changelog = ("""Update to [url={0}/commit/{1}]{1}[/url]""").format(githubUrl, currentCommitID)

    if diffUrl != "":
        changelog = ("{} [url={}]Diff[/url]").format(changelog, diffUrl)
    pprint(changelog)

    out = check_output(("\"D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin\\gmpublish.exe\" update -addon \".\Sit.gma\"  -id \"108176967\" -changes \"{}\"").format(changelog), shell=True)
    pprint(out)
    
    repo.references.delete("refs/tags/workshop")
    repo.create_reference("refs/tags/workshop", currentCommitID)
run()