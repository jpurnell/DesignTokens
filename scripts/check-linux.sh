#!/bin/bash
# Builds and tests the package on a Linux host over ssh: copies the working tree (without .build and .git), then runs
# `swift build` and `swift test` there in a login shell, so the toolchain on that machine's PATH is the one used.
# Usage: scripts/check-linux.sh [host]   (default: starscream.local)
# Exits 0 only if both the build and the tests pass; a host that cannot be reached exits 2, never 0.
set -u
cd "$(dirname "$0")/.."
host="${1:-starscream.local}"
dest="DesignTokens-linux-check"

if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" true 2>/dev/null; then
    echo "UNREACHABLE  $host"
    exit 2
fi

echo "== $host: $(ssh "$host" 'bash -lc "swift --version 2>&1 | head -1"')"
rsync -az --delete --exclude .build --exclude .git --exclude '.DS_Store' ./ "$host:$dest/" || { echo "rsync failed"; exit 1; }

status=0
for step in "swift build" "swift test"; do
    echo "== $step"
    ssh "$host" "bash -lc 'cd $dest && $step 2>&1'" || { echo "FAILED  $step on $host"; status=1; break; }
done
[ $status -eq 0 ] && echo "PASSED  build and test on $host"
exit $status
