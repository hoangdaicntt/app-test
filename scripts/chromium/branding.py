#!/usr/bin/env python3
"""Guarded, idempotent branding overlay for the pinned Chromium revision."""
import hashlib
import json
from pathlib import Path
import shutil
import sys

project = Path(__file__).resolve().parents[2]
src = Path(sys.argv[1]).resolve()
branding = project / 'chromium/branding'
source = project / 'src/assets/images/icon.png'
assert hashlib.sha256(source.read_bytes()).hexdigest() == (branding / 'source.sha256').read_text().strip(), 'Regenerate branding after source icon changes'
guards = json.loads((branding / 'upstream-sha256.json').read_text())
icon_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/layered_app_icon_background"/>
    <foreground android:drawable="@mipmap/layered_app_icon"/>
</adaptive-icon>
'''
for name, expected in guards.items():
    path = src / name
    original = path.read_text()
    if name.endswith('channel_constants.xml'):
        updated = original.replace('>Chromium', '>ADB Browser')
        if 'ADB Browser' in original:
            original = original.replace('>ADB Browser', '>Chromium')
        assert original.count('>Chromium') == 4, 'Unexpected app/widget labels'
    else:
        updated = icon_xml
        if original == updated:
            continue
    assert hashlib.sha256(original.encode()).hexdigest() == expected, f'Upstream changed: {name}'
    path.write_text(updated)
for asset in sorted((branding / 'res').rglob('*.png')):
    target = src / 'chrome/android/java/res_chromium_base' / asset.relative_to(branding / 'res')
    assert target.is_file(), f'Missing upstream launcher resource: {target}'
    shutil.copyfile(asset, target)
print('Applied ADB Browser labels and launcher icons')
