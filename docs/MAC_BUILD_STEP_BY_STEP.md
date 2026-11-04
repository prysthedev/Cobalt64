# Build Navi48Bringup on a separate Mac

This guide builds an x86_64 kext and collects logs for review. Stop after
the build. A target trial requires a verified fallback EFI and an independent
Windows boot.

## 1. Check the developer tools

Open Terminal on the Mac and run:

```sh
xcode-select -p
```

If developer tools are missing, run `xcode-select --install`, finish the
installation, and check again.

## 2. Get the source and pinned dependencies

Review the [AMD firmware license](https://gitlab.com/kernel-firmware/linux-firmware/-/blob/b2722d241309a1872446c1d00c2e812bad055f89/LICENSES/LICENSE.amdgpu)
before downloading firmware. Run these commands in Terminal and stop if any
command fails.

```sh
mkdir -p ~/cobalt64-dev
cd ~/cobalt64-dev

git clone --branch codex/firmware-preflight --single-branch \
  https://github.com/prysthedev/Cobalt64.git

git clone https://github.com/acidanthera/MacKernelSDK.git
git -C MacKernelSDK checkout --detach 05094e5e88cec7caedbfb35e8449ed0db94bf95b

git clone --depth 1 --branch 20260622 \
  https://gitlab.com/kernel-firmware/linux-firmware.git
git -C linux-firmware rev-parse HEAD
```

The last command should print `b2722d241309a1872446c1d00c2e812bad055f89`.

## 3. Run the preflight

```sh
cd ~/cobalt64-dev/Cobalt64
bash tools/setup-dev.sh \
  "$HOME/cobalt64-dev/MacKernelSDK" \
  "$HOME/cobalt64-dev/linux-firmware" \
  > ../cobalt64-preflight.log 2>&1
cat ../cobalt64-preflight.log
```

Proceed when the log reports `Verified SHA-256 for all 10 AMD firmware blobs`
and `Bring-up kext preflight passed`. If either message is missing, share the
preflight log.

## 4. Stage firmware and build

```sh
bash tools/fetch-firmware.sh "$HOME/cobalt64-dev/linux-firmware" &&
make -C src/navi48-bringup \
  MKSDK="$HOME/cobalt64-dev/MacKernelSDK" all \
  > ../cobalt64-build.log 2>&1
```

Terminal may stay quiet during compilation. Once the prompt returns, run
`tail -n 40 ../cobalt64-build.log`. A successful build reports
`Built build/Navi48Bringup.kext for x86_64`. The bundle is under
`src/navi48-bringup/build/Navi48Bringup.kext`.

## 5. Share the logs

Attach `cobalt64-preflight.log` and `cobalt64-build.log` from
`~/cobalt64-dev` to the Codex chat. If staging failed before compilation,
share its Terminal output instead. Review the build result before loading the
kext or changing OpenCore.
