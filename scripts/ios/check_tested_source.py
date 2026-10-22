"""Only distribute native source that already passed the simulator workflow."""
import json
import subprocess

runs = json.loads(subprocess.check_output([
    "gh", "run", "list", "--workflow", "ios-tests.yml", "--limit", "30",
    "--json", "headSha,conclusion,databaseId"
],text=True))
for run in runs:
    if run["conclusion"] != "success":
        continue
    result = subprocess.run(["git","diff","--quiet",run["headSha"],"HEAD","--","ios/"])
    if result.returncode == 0:
        print("Native source matches passing simulator run " + str(run["databaseId"]))
        break
else:
    raise SystemExit("Run the iOS simulator checks successfully on this native source before distributing")
