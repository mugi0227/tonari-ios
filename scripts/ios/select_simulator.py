"""Bound CoreSimulator discovery so runner preparation cannot hang invisibly."""
import json
import os
from pathlib import Path
import subprocess

print("Discovering an available iPhone simulator (120 second limit)",flush=True)
result = subprocess.run(["xcrun","simctl","list","devices","available","-j"],
                        text=True,capture_output=True,timeout=120,check=True)
groups = json.loads(result.stdout)["devices"]
candidates = [(runtime,device) for runtime,devices in groups.items() if ".iOS-" in runtime
              for device in devices if device["name"].startswith("iPhone") and device.get("isAvailable")]
assert candidates, "No available iPhone runtime is installed on this runner"
candidates.sort(key=lambda item: (item[1]["name"] == "iPhone 17 Pro", item[0]),reverse=True)
runtime,device = candidates[0]
with Path(os.environ["GITHUB_ENV"]).open("a") as out:
    out.write("SIMULATOR_UDID=" + device["udid"] + "\n")
print("Selected " + device["name"] + " / " + runtime,flush=True)
