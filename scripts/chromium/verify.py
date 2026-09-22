#!/usr/bin/env python3
"""Inspect the built APK with the Android SDK; fail closed on identity errors."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

project = Path(__file__).resolve().parents[2]
src, artifacts = map(Path, sys.argv[1:])
pins = json.loads((project / 'chromium/versions.json').read_text())
apk = artifacts / 'ADB-Browser-arm64.apk'

def run(*args):
    return subprocess.check_output(list(map(str, args)), text=True)

sdk = src / 'third_party/android_sdk/public/build-tools'
tool_dirs = sorted(p for p in sdk.iterdir() if (p / 'aapt2').is_file() and (p / 'apksigner').is_file())
assert tool_dirs, f'No Android build tools found in {sdk}'
tools = tool_dirs[-1]
badging = run(tools / 'aapt2', 'dump', 'badging', apk)
(artifacts / 'badging.txt').write_text(badging)
package_line = next(line for line in badging.splitlines() if line.startswith('package:'))
for key, value in [('name', pins['package']), ('versionCode', pins['version_code']), ('versionName', pins['version_name'])]:
    assert f"{key}='{value}'" in package_line, package_line
assert f"application-label:'{pins['label']}'" in badging
assert "native-code: 'arm64-v8a'" in badging
assert 'launchable-activity:' in badging
manifest = run(tools / 'aapt2', 'dump', 'xmltree', apk, '--file', 'AndroidManifest.xml')
(artifacts / 'manifest.txt').write_text(manifest)
# Java classes legitimately retain org.chromium.*; application authorities and
# custom permissions must use the configured application ID.
for line in manifest.splitlines():
    if 'android:authorities(' in line:
        raw = re.search(r'Raw: "([^"]+)"', line)
        assert raw and all(x == pins['package'] or x.startswith(pins['package'] + '.') for x in raw[1].split(';')), line
assert 'org.chromium.chrome.permission.' not in manifest
assert pins['package'] + '.permission.CHILD_SERVICE' in manifest
os.environ['JAVA_HOME'] = str(src / 'third_party/jdk/current')
os.environ['PATH'] = os.environ['JAVA_HOME'] + '/bin:' + os.environ['PATH']
signature = run(tools / 'apksigner', 'verify', '--verbose', '--print-certs', apk)
(artifacts / 'signature.txt').write_text(signature)
# Compare decoded pixels: aapt2 may recompress PNGs when packaging them.
expected = project / 'chromium/branding/res/mipmap-xxxhdpi/layered_app_icon.png'
def pixels(path):
    return subprocess.check_output(['convert', str(path), '-background', '#e93430', '-alpha', 'remove', '-alpha', 'off', 'rgb:-'])
with zipfile.ZipFile(apk) as z:
    names = [n for n in z.namelist() if 'xxxhdpi' in n and Path(n).name in {'layered_app_icon', 'layered_app_icon.png', 'layered_app_icon.webp'}]
    assert len(names) == 1, f'Expected launcher foreground in APK: {names}'
    extracted = artifacts / 'launcher-foreground.png'
    # Chromium release resources use lossless WebP without an extension.
    subprocess.run(['convert', '-', str(extracted)], input=z.read(names[0]), check=True)
    assert pixels(extracted) == pixels(expected), 'APK launcher pixels differ from project icon'
    abis = {n.split('/')[1] for n in z.namelist() if n.startswith('lib/') and n.endswith('.so')}
    assert abis == {'arm64-v8a'}, abis
args = (src / 'out/ADBAndroid/args.gn').read_text()
(artifacts / 'args.gn').write_text(args)
metadata = dict(pins)
metadata.update(app_commit=run('git', '-C', project, 'rev-parse', 'HEAD').strip(),
                chromium_actual_revision=run('git', '-C', src, 'rev-parse', 'HEAD').strip(),
                depot_tools_actual_revision=run('git', '-C', src.parents[1] / 'depot_tools', 'rev-parse', 'HEAD').strip(),
                apk_sha256=hashlib.sha256(apk.read_bytes()).hexdigest(),
                icon_source_sha256=(project / 'chromium/branding/source.sha256').read_text().strip(),
                runtime_tested=False)
assert metadata['chromium_actual_revision'] == pins['chromium_revision']
assert metadata['depot_tools_actual_revision'] == pins['depot_tools_revision']
(artifacts / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
(artifacts / 'SHA256SUMS').write_text(f"{metadata['apk_sha256']}  {apk.name}\n")
print('Verified ARM64 APK identity, signature, authorities and launcher pixels')
