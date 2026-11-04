#!/bin/bash
# Check a macOS build host without installing software or staging firmware.
set -euo pipefail

if [ "$(uname -s)" != Darwin ]; then
    echo "Run this preflight on a Mac with the Xcode Command Line Tools." >&2
    exit 2
fi
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <MacKernelSDK checkout> <linux-firmware checkout>" >&2
    exit 2
fi
if ! xcode-select -p; then
    echo "Install the Command Line Tools with xcode-select --install, then retry." >&2
    exit 1
fi

for tool in make codesign python3 git; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required build tool missing: $tool" >&2
        exit 1
    fi
done
for input in Headers/IOKit/IOService.h Library/x86_64/libkmodc++.a Library/x86_64/libkmod.a; do
    if [ ! -f "$1/$input" ]; then
        echo "Missing SDK input: $1/$input. Pass the MacKernelSDK directory." >&2
        exit 1
    fi
done

sw_vers
uname -m
xcrun --sdk macosx --show-sdk-path
xcrun clang --version
xcrun ld -v
python3 --version
tools="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$tools/verify-dependencies.sh" "$2"
echo "Bring-up kext preflight passed. Target architecture: x86_64."
