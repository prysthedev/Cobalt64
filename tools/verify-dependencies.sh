#!/bin/bash
# Verify local AMD firmware before staging it.
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -d "$1/amdgpu" ]; then
    echo "Usage: $0 <linux-firmware checkout containing amdgpu/>" >&2
    exit 2
fi

root="$1"
tools="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -s "$root/LICENSES/LICENSE.amdgpu" ] && [ ! -s "$root/LICENSE.amdgpu" ]; then
    echo "Missing or empty AMD license: check $root/LICENSES/LICENSE.amdgpu and $root/LICENSE.amdgpu" >&2
    exit 1
fi
if command -v shasum >/dev/null 2>&1; then
    checksum=(shasum -a 256)
elif command -v sha256sum >/dev/null 2>&1; then
    checksum=(sha256sum)
else
    echo "Install shasum or sha256sum to verify AMD firmware." >&2
    exit 2
fi

failed=0
count=0
while read -r name expected; do
    count=$((count + 1))
    blob="$root/amdgpu/$name.bin"
    if [ -f "$blob" ]; then
        digest="$("${checksum[@]}" < "$blob")"
    elif [ -f "$blob.zst" ]; then
        if ! command -v zstd >/dev/null 2>&1; then
            echo "Install zstd to verify $blob.zst." >&2
            exit 2
        fi
        digest="$(zstd -dqc -- "$blob.zst" | "${checksum[@]}")"
    else
        echo "Missing firmware: $blob (or $blob.zst)" >&2
        failed=1
        continue
    fi
    actual="${digest%% *}"
    if [ "$actual" != "$expected" ]; then
        echo "SHA-256 mismatch for $name.bin: expected $expected, got $actual" >&2
        failed=1
    fi
done < "$tools/firmware-sha256.txt"

if [ "$count" -ne 10 ]; then
    echo "Expected 10 entries in the firmware manifest, found $count." >&2
    exit 2
fi
if [ "$failed" -ne 0 ]; then
    exit 1
fi
echo "Verified SHA-256 for all $count AMD firmware blobs."
