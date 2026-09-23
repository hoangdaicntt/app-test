#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"

retry() {
  local attempt=1
  local delay=30
  local max_attempts=5
  until "$@"; do
    if (( attempt >= max_attempts )); then
      echo "Command failed after $attempt attempts: $*" >&2
      return 1
    fi
    echo "Command failed on attempt $attempt; retrying in ${delay}s: $*" >&2
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
  done
}

"$PROJECT_ROOT/scripts/chromium/preflight.sh" "$CHROMIUM_WORK_ROOT"
mkdir -p "$CHROMIUM_WORK_ROOT"
if [[ ! -d "$CHROMIUM_WORK_ROOT/depot_tools/.git" ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$CHROMIUM_WORK_ROOT/depot_tools"
fi
retry git -C "$CHROMIUM_WORK_ROOT/depot_tools" fetch origin "$(pin depot_tools_revision)"
git -C "$CHROMIUM_WORK_ROOT/depot_tools" checkout --detach "$(pin depot_tools_revision)"
# DEPOT_TOOLS_UPDATE=0 requires explicit bootstrap on a fresh checkout.
"$CHROMIUM_WORK_ROOT/depot_tools/ensure_bootstrap"
mkdir -p "$CHROMIUM_WORK_ROOT/checkout"
cd "$CHROMIUM_WORK_ROOT/checkout"
if [[ ! -e .gclient ]]; then
  gclient config --spec 'solutions = [
    {
      "name": "src",
      "url": "https://chromium.googlesource.com/chromium/src.git",
      "managed": False,
      "custom_deps": {},
      "custom_vars": {},
    },
  ]
  target_os = ["android"]'
fi
retry gclient sync --nohooks --no-history --revision "src@$(pin chromium_revision)"
cd "$CHROMIUM_SRC"
git checkout --detach "$(pin chromium_revision)"
[[ $(git rev-parse HEAD) == "$(pin chromium_revision)" ]]
# Dependency installation is allowed in a container or ephemeral hosted CI.
[[ -f /.dockerenv || "${RUNNER_ENVIRONMENT:-}" == github-hosted ]] || { echo 'Use Docker or an ephemeral GitHub-hosted runner'; exit 1; }
sudo build/install-build-deps.sh --no-prompt
retry gclient runhooks
