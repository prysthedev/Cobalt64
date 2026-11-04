# Building the bring-up kext

> **WARNING.** Navi48Bringup.kext writes GPU registers directly (PCIe BARs, PSP, SMU, RLC, SDMA, CP,
> MES, display engine). It is experimental, it has only been run on one x86_64 test PC with one
> RX 9070 XT, and a wrong build or a different card can hang or restart the machine or corrupt
> display state. Do not run it on a machine you cannot afford to restart or recover. You run
> it entirely at your own risk; there is no warranty (see LICENSE).

## Prerequisites

- macOS with the Xcode Command Line Tools (clang, make, codesign, python3).
- MacKernelSDK from the RDNA4FB project's successor, AMDRadeonRDNA4.kext.
  Its SDK submodule at parent commit `49f7f20c00dd154384418078f8a09e79c400a06a`
  points to the following revision. Clone the SDK directly and pass its path
  as MKSDK. This pin is verified against the published tree. A macOS link
  test with it is still pending.

  ```
  git clone https://github.com/acidanthera/MacKernelSDK.git
  git -C MacKernelSDK checkout --detach 05094e5e88cec7caedbfb35e8449ed0db94bf95b
  ```

- AMD firmware from linux-firmware tag 20260622. All ten SHA-256 digests
  match the build manifest. Review LICENSES/LICENSE.amdgpu before retrieving
  or staging the blobs:

  ```
  git clone https://gitlab.com/kernel-firmware/linux-firmware.git
  git -C linux-firmware checkout --detach b2722d241309a1872446c1d00c2e812bad055f89
  tools/fetch-firmware.sh <path-to-that-checkout>
  ```

  This only copies files (no network) into `src/navi48-bringup/firmware/`, which is
  gitignored. The kext embeds exactly these ten files from linux-firmware's `amdgpu/`:

  ```
  gc_12_0_1_imu.bin  gc_12_0_1_me.bin  gc_12_0_1_mec.bin  gc_12_0_1_pfp.bin
  gc_12_0_1_rlc.bin  gc_12_0_1_uni_mes.bin
  psp_14_0_3_sos.bin  psp_14_0_3_ta.bin
  sdma_7_0_1.bin  smu_14_0_3.bin
  ```

  Run `bash tools/verify-dependencies.sh <path-to-that-checkout>` to check the
  AMD license file and all ten SHA-256 digests without copying anything.
  The staging script runs the same preflight before it copies the inputs.
  For compressed inputs, install zstd. The digest is checked against the
  decompressed bytes. The Makefile reports any staged files that are missing.

## Build

```
make -C src/navi48-bringup MKSDK=/path/to/RDNA4FB/MacKernelSDK all
```

The result is `src/navi48-bringup/build/Navi48Bringup.kext` (x86_64, ad-hoc signed, min macOS
11 ABI). Check it with: `dwarfdump --uuid build/Navi48Bringup.kext/Contents/MacOS/Navi48Bringup`
and `nm -u -arch x86_64 <that binary>` (only kernel, IOKit and KPI symbols).

## Optional pieces that are NOT in this repository

The shader cache (`src/shadercache/shadercache.c` is only its parser) and four gfx1201 blit
kernels serve the older route that substitutes shaders inside Apple's own AMDRadeonX6000
accelerator. They derive from Apple's shader binaries and captures and are therefore left
out. The native route (Mesa RADV plus the Metal bundle in `tools/native`) does not use them.
When `firmware/shadercache.bin` and `firmware/shader_blit_*.bin` are absent the Makefile embeds
zero-length blobs under the same symbols. The cache then refuses to open ("sc_open ...
REFUSED ... substitution stays OFF") and every blit-kernel substitution is refused, so
nothing is substituted or armed. Likewise the translator self-tests in `src/xlat12` need
captured Apple IB streams that are not shipped; without them the self-tests report a failure
and the render-translation arms refuse. Everything else, including the compute test shaders
(`src/navi48-bringup/shaders/store_magic*.s` with their assembled `.bin`), is in the tree.

Boot-args and loading are described in the source comments; this file only covers building.
