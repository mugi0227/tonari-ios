"""Verify the actual signed .app, rather than source settings alone."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys

app = Path(sys.argv[1])
info = plistlib.loads((app / "Info.plist").read_bytes())
assert info["CFBundleIdentifier"] == "jp.mugilab.tonari"
assert info["CFBundleVersion"] == os.environ["BUILD_NUMBER"]
assert info["CFBundleShortVersionString"] == "0.1.0"
assert info["NSMicrophoneUsageDescription"] and info["NSCameraUsageDescription"]
assert not info.get("NSAppTransportSecurity", {}).get("NSAllowsArbitraryLoads", False)
assert not info.get("UIBackgroundModes"), "No unverified background recording"
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
entitlements = plistlib.loads(subprocess.check_output(["codesign", "-d", "--entitlements", ":-", str(app)], stderr=subprocess.DEVNULL))
assert entitlements["application-identifier"] == "572NVCGLGQ.jp.mugilab.tonari"
assert not entitlements.get("get-task-allow", False)
assert entitlements.get("beta-reports-active") is True
assert (app / "PrivacyInfo.xcprivacy").exists()
binary = (app / "Tonari").read_bytes()
assert b"tonari-125374794305.asia-northeast1.run.app" in binary
assert b"--ui-fixture" not in binary and b"--ui-offline" not in binary
report = {"bundleId":info["CFBundleIdentifier"],"version":info["CFBundleShortVersionString"],
          "build":info["CFBundleVersion"],"distributionSigningVerified":True,
          "debugFixtureDisabled":True,"noBackgroundAudioEntitlement":True,
          "sourceCommit":os.environ.get("GITHUB_SHA"),"binarySha256":hashlib.sha256(binary).hexdigest()}
Path(os.environ["RUNNER_TEMP"], "archive-verification.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print(json.dumps(report,indent=2))
