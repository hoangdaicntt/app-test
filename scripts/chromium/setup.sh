#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
"$PROJECT_ROOT/scripts/chromium/preflight.sh" "$CHROMIUM_WORK_ROOT"
mkdir -p "$CHROMIUM_WORK_ROOT"
if [[ ! -d "$CHROMIUM_WORK_ROOT/depot_tools/.git" ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$CHROMIUM_WORK_ROOT/depot_tools"
fi
git -C "$CHROMIUM_WORK_ROOT/depot_tools" fetch origin "$(pin depot_tools_revision)"
git -C "$CHROMIUM_WORK_ROOT/depot_tools" checkout --detach "$(pin depot_tools_revision)"
mkdir -p "$CHROMIUM_WORK_ROOT/checkout"
cd "$CHROMIUM_WORK_ROOT/checkout"
if [[ ! -e .gclient ]]; then
  fetch --no-history --nohooks android
fi
cd "$CHROMIUM_SRC"
git fetch --depth=1 origin "$(pin chromium_revision)"
git checkout --detach "$(pin chromium_revision)"
gclient sync --nohooks --no-history --revision "src@$(pin chromium_revision)"
[[ $(git rev-parse HEAD) == "$(pin chromium_revision)" ]]
# Dependency installation is allowed in a container or ephemeral hosted CI.
[[ -f /.dockerenv || "${RUNNER_ENVIRONMENT:-}" == github-hosted ]] || { echo 'Use Docker or an ephemeral GitHub-hosted runner'; exit 1; }
sudo build/install-build-deps.sh --no-prompt
gclient runhooks
