#!/usr/bin/env bash
set -euo pipefail
root="${1:?Pass the cache directory}"
mkdir -p "$root"
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { echo 'Requires Linux x86-64'; exit 1; }
ram_kib=$(awk '/MemTotal/{print $2}' /proc/meminfo)
disk_kib=$(df -Pk "$root" | awk 'NR==2{print $4}')
echo "Runner: $(nproc) CPUs; $((ram_kib / 1024)) MiB RAM; $((disk_kib / 1024 / 1024)) GiB free disk"
# Experimental hosted run: measure rather than enforce project safety margins.
if (( disk_kib < 100 * 1024 * 1024 )); then
  echo 'WARNING: below upstream 100 GB free disk guidance; attempting requested experimental build.'
fi
