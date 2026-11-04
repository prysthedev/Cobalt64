# Baseline build plan

Use the separate Mac for build-only work. Record `sw_vers`, `xcode-select -p`, `clang --version`, `ld -v`, `xcrun --sdk macosx --show-sdk-path` and `python3 --version`. Install the Command Line Tools if absent. The target artifacts are x86_64. Record the Mac host architecture separately.

1. Check out the audited SHA in a clean worktree. Obtain MacKernelSDK from RDNA4FB as specified in BUILDING.md and record the SDK and parent checkout revisions. BUILDING.md pins the SDK to the revision used by the successor repository. Link validation on macOS remains pending.
2. Review linux-firmware's LICENSE.amdgpu before obtaining inputs. Use linux-firmware commit b2722d241309a1872446c1d00c2e812bad055f89 (tag 20260622). All ten uncompressed blobs at this release matched tools/firmware-sha256.txt. Run the firmware preflight and staging script as described in BUILDING.md. The preflight rejects a digest mismatch before staging.
3. Run `make -C src/navi48-bringup MKSDK=/absolute/path/to/MacKernelSDK all`. Capture compiler output, inspect the kext executable with file, dwarfdump and nm, and verify the ad-hoc signature with codesign. Record the result from a second clean checkout before calling the build reproducible.
4. In a separate Mesa worktree, check out `f5cb8ee032adabef599ae892ec4e42d796b84da9` and use `git am /absolute/path/to/cobalt/mesa-patches/*.patch` in the documented order. Record the resolved Meson and Ninja versions, native dependencies and x86_64 build arguments that produce libvulkan_radeon.dylib. All nine patches applied with git am in a separate clean checkout at that exact SHA. Git reported one added line with trailing whitespace in include/darwin/amdgpu.h from patch 0001. A verified Darwin build invocation is still needed.
5. Apply the metal2vulkan patch at `43c46ac8a24adf1a6e872b8a52c706ec9614fad0`, copy the n48xlate crate and run `cargo build --release -p n48xlate` with Rust 1.87 or later, targeting x86_64 for deployment. The patch passed git apply --check and git diff --check at the exact pin. Keep the patch checkout LF on Windows. Follow its NOTICE and retain the license. Use `N48_RADV_LIB`, `N48_VK_INC` and `N48_XLATE_LIB` with tools/native/navi48metal/build.sh. Build navi48accel using its Makefile and mtlprobe using its build script. Precompiled mtlprobe shaders require working metal and metallib tools.
6. Run fixture-free tests and capture exit codes, then document all fixture-dependent failures separately. Keep generated binaries, AMD firmware, proprietary shader data and kernel collection extracts out of Git.

## Target reproduction gate

Upstream used OpenCore and x86_64 macOS Tahoe 26.6.2 on one RX 9070 XT PC. The target board, subsystem IDs, firmware state, BAR sizes and monitor configuration still need read-only inventory. Establish a known-good baseline macOS boot on the dedicated SSD and verify the Windows boot path independently. Preserve a known-good EFI copy and verify fallback boot media. For the first approved driver trial, use one display, keep auto-arm and multi-display experiments disabled, and document how to boot the fallback EFI after a hang or black screen. Exact OpenCore settings and kext activation steps require source and target verification.

### Darwin RADV configure candidate

Run this in the patched Mesa checkout on an x86_64 macOS build environment.
Use an x86_64 compiler environment and x86_64 dependencies if building on an
Apple Silicon Mac. Record Meson, Ninja, Apple Clang and SDK versions with the
configuration and compile logs.

```sh
meson setup build-x86_64 \
  -Dvulkan-drivers=amd -Dplatforms=macos -Dgallium-drivers=[] \
  -Dopengl=false -Degl=disabled -Dglx=disabled -Dgbm=disabled -Dllvm=disabled
meson compile -C build-x86_64
lipo -verify_arch x86_64 build-x86_64/src/amd/vulkan/libvulkan_radeon.dylib
```

These options are present at the patched Mesa revision. The build selects the
Darwin AMD backend when the Meson host system is Darwin and the AMD Vulkan
driver is enabled. The configuration and compilation have yet to be exercised
on macOS. Once the dylib passes the architecture check, pass its absolute path
as N48_RADV_LIB when building Navi48Metal.
