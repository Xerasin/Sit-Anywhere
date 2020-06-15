import pygit2
import os 
from pprint import pprint
from subprocess import check_output

githubUrl = "https://github.com/Xerasin/Sit-Anywhere"
gmodUtilDir = "D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin"
def run():
    dir_path = os.path.dirname(os.path.realpath(__file__))  + "\\"
    repository_path = pygit2.discover_repository(dir_path)
    repo = pygit2.Repository(repository_path)

    currentWorkshop = repo.lookup_reference("refs/tags/workshop")

    currentCommitID = ("{}").format(repo.head.target)
    workshopCommitID = ("{}").format(currentWorkshop.target)

    
    if workshopCommitID == currentCommitID:
        print("No changes!")
        return

    out = check_output(("\"{}\\gmad.exe\" create -folder \".\\sit\" -out \".\\Sit.gma\"").format(gmodUtilDir), shell=True)

    diffUrl = ("{}/compare/{}..{}").format(githubUrl, workshopCommitID, currentCommitID)

    changelog = ("""Update to [url={0}/commit/{1}]{1}[/url] - [url={2}]Changes[/url]""").format(githubUrl, currentCommitID, diffUrl)

    pprint(changelog)
    out = check_output(("\"{}\\gmpublish.exe\" update -addon \".\Sit.gma\"  -id \"108176967\" -changes \"{}\"").format(gmodUtilDir, changelog), shell=True)

    repo.references.delete("refs/tags/workshop")
    repo.create_reference("refs/tags/workshop", currentCommitID)
run()