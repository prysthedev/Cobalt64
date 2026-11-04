# Development setup

Use a separate Mac for compilation and the target PC for hardware validation.
The kext target is x86_64. Record the Mac host architecture separately.

1. Install the Command Line Tools with `xcode-select --install` if needed.
2. Obtain MacKernelSDK as described in BUILDING.md. Record the SDK checkout
   revision and the enclosing RDNA4FB revision, if applicable.
3. Review the AMD firmware license, then obtain a local linux-firmware
   checkout. Record its revision. Install zstd if its firmware is compressed.
4. Run the read-only bring-up kext preflight from the repository root.

   ```sh
   bash tools/setup-dev.sh /absolute/path/to/MacKernelSDK /absolute/path/to/linux-firmware
   ```

5. Follow BUILDING.md to stage the verified firmware and build the kext.
   Save the preflight and compiler output outside the repository. A passing
   preflight establishes tool and firmware availability. A clean build
   requires a separate recorded invocation.

The preflight covers the bring-up kext. Mesa, the translator and Metal
tooling require separate build dependencies and validation.
