# ADB Browser — native Chromium Android build experiment

Public, clean-history export of the native Android build files and existing
launcher icon. No inherited Expo application, credentials or private Git history.

Target: ARM64 full Chromium browser APK, package `com.adblock.browser.vn`,
label `ADB Browser`. Source and depot_tools commits are pinned in
`chromium/versions.json`. APK uses the upstream public test key, not production.

This experiment runs on the standard public GitHub Ubuntu 22.04 runner. It
measures resources, removes unused preinstalled SDKs from the ephemeral VM,
and attempts a build even below upstream's 100 GB free-space guidance.
Compilation defaults to four jobs to use the runner CPU capacity; two jobs remain
available as a comparison. The job timeout is six hours. Memory and disk
usage are sampled every minute and included in build diagnostics.
No successful build or runtime test is claimed until artifacts are available.

Dispatch `chromium-android.yml` on the default `android` branch with gh.
Only APK/metadata and explicit build logs are uploaded. Chromium source,
dependencies and build output are ignored. No adblock or other app services
are integrated at this milestone.
