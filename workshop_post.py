import pygit2
import os 
from pprint import pprint
from subprocess import check_output

gmodUtilDir = "D:\\Program Files (x86)\\Steam\\SteamApps\\common\\GarrysMod\\bin"

dir_path = os.path.dirname(os.path.realpath(__file__))  + "\\"
repository_path = pygit2.discover_repository(dir_path)

def ask(string):
    while True:
     query = input(string)
     charOutput = query[0].lower()
     if query == '' or not charOutput in ['y', 'n']:
        print('Please answer with yes or no!')
     else:
        break
    if charOutput == 'y':
        return True
    return False

def run():
    repo = pygit2.Repository(repository_path)
    githubUrl = repo.config["remote.origin.url"].replace(".git", "")
    workshopCommit = repo.lookup_reference("refs/tags/workshop")

    currentCommitID = ("{}").format(repo.head.target)
    workshopCommitID = ("{}").format(workshopCommit.target)

    if workshopCommitID == currentCommitID:
        print("No changes!")
        return

    out = check_output(("\"{}\\gmad.exe\" create -folder \".\\sit\" -out \".\\Sit.gma\"").format(gmodUtilDir), shell=True)

    diffUrl = ("{}/compare/{}...{}").format(githubUrl, workshopCommitID, currentCommitID)
    changelog = ("""Update to [url={0}/commit/{1}]{1}[/url] - [url={2}]Changes[/url]""").format(githubUrl, currentCommitID, diffUrl)
    print(changelog)

    def update_ref():
        repo.references.delete("refs/tags/workshop")
        repo.create_reference("refs/tags/workshop", currentCommitID)

    if ask("Do you want to push this to the workshop? "):
        out = check_output(("\"{}\\gmpublish.exe\" update -addon \".\Sit.gma\"  -id \"108176967\" -changes \"{}\"").format(gmodUtilDir, changelog), shell=True)
        update_ref()
    else:
        if ask("Do you want to update the workshop refrence? "):
            update_ref()
            

run()