# Cobalt64 repository audit

## Baseline and scope

Upstream defaults to `main` at `d1f7bad8408a0a2c016b067c477422975a59de44`. The separate `upstream-audit` checkout is detached at that revision and names its remote `upstream`. The project workspace began as an unborn Git repository with no remotes. The fork prysthedev/Cobalt64 defaults to main at the same full SHA. A direct fetch and symmetric history comparison returned zero commits on either side, and the tree diff was empty. The upstream history has 17 commits and exposes only main in the checkout. Key changes include the initial public export, clean-build handling for omitted Apple assets, the multi-display snapshot, and the later IOAccelerator layout generator. This is a preliminary source and build audit. Full lifecycle review, compilation and target hardware validation remain open.

## Architecture and dependency paths

| Path | Responsibility and evidence |
| --- | --- |
| src/navi48-bringup | IOKit service owns PCI and BAR mapping, IP discovery, embedded firmware, hardware startup and teardown. The AMD subtree covers PSP, SMU, GMC/GART, CP, MES, SDMA, interrupts and doorbells. Native and diagnostic clients expose separate interfaces. |
| src/dcn41 and bring-up src/dcn | Register definitions and display helpers plus kernel integration. Scanout depends on successful memory and display bring-up. Upstream reports fixed modes tailored to its monitors. |
| src/xlat12 and bring-up src/apple | Alternate path translating Apple GFX10.3 register and PM4 streams to GFX12. Missing captures prevent some self-tests and leave translation arms disabled. |
| src/g2capture and src/shadercache | Apple compiler capture tooling and shader cache parser. Apple-derived payloads are absent from the public tree. |
| mesa-patches | Nine ordered RADV patches provide a Darwin backend over the N48N user client. N48N kernel header advertises ABI 1.12. Review mirrored structures, selector shapes and compatibility with 1.11 before any ABI change. |
| tools/native | Navi48Metal packages x86_64 RADV, uses Metal-facing Objective-C interfaces and can use libn48xlate for AIR translation. navi48accel supplies an auxiliary kext. mtlprobe is a Metal probe. |
| tools/pc, tools/dcn41, tools/conductor | Diagnostics, remote hardware orchestration, display analysis, host suites and mutation tests. Treat scripts that load kexts or restart WindowServer as hardware procedures. |
| tools/ioaccel-layout | Reconstructs private IOAcceleratorFamily2 layout from local matching kernel collections and checks generated vtables. Upstream tested x86_64 Tahoe 26.6.2 (25G83). Extracting standalone Mach-O inputs is manual. |

Native runtime path: Metal caller → Navi48Metal → RADV Darwin → N48N user client → GPU queues and memory. Shader translation adds Apple compiler services and the separately licensed libn48xlate wrapper. The older Apple accelerator path has different inputs and must be validated separately.

Upstream reports GPU composition across three displays and accelerated rendering in several apps on one OpenCore x86_64 RX 9070 XT system with Tahoe 26.6.2. CHANGES describes kext 0.0.664, Metal bundle revision 20 and experimental display flags. That report is the reference configuration. This audit has no independent build or hardware evidence. [Upstream README](https://github.com/Almosst-DEV/Cobalt64/blob/d1f7bad8408a0a2c016b067c477422975a59de44/README.md)

## Build and test evidence

- Windows Python ran three existing checks. All exited 1. The readset and descriptor generator tests reference missing tools/gfx-readset.py and tools/gen-desc-xlat.py. The ABI row test parsed 39 rows and passed structural checks before failing on missing ABI JSON and mutation fixtures under re/. These are observed public-export gaps.
- The xlat12 Makefile groups sanitizer-backed C tests and fuzzers with fixture-dependent Python checks. DCN C tests, pure C++ bring-up tests, autoarm fake-tool tests and M6 script simulation are candidates for execution without the RX 9070 XT. Verify per-suite tool and fixture requirements. The IOAccelerator checker needs matching local macOS inputs. Driver-facing IOKit tests need a live macOS driver.
- This Windows shell exposed Python but no make or clang on PATH. WSL access was denied and Git Bash could not initialize under the sandbox. Compilation, compiler-warning baseline, Mesa patch application and integration remain unverified.

## Risk review and open work

| Priority | Review target | Evidence or question |
| --- | --- | --- |
| P0 | BAR and MMIO bounds | ReBAR has a pure planning helper and doorbell readback guards. Trace all mapped-range checks and failure exits through PCI enable and bus-master setup. |
| P0 | DMA and submission lifetime | Trace ownership of imported and allocated BOs across submit, completion, timeout, client close and stop. Verify fence retirement, pin lifetime, address range and cleanup ordering under concurrency. |
| P0 | Firmware and partial initialization | Build embeds ten AMD blobs. The copy script warns on digest mismatch and copies anyway. Check firmware parsing bounds, timeouts and reverse-order teardown before hardware use. |
| P0 | ABI and client authorization | Review externalMethod argument lengths, handles, role gates and pointer arithmetic against Mesa and CLI callers. Keep default-deny behavior under review when comparing PR 12. |
| P1 | Display and Apple hooks | Review fixed topology assumptions, saved-state restoration, watchdog and lock ordering, and compatibility with the exact Apple binary build. A successful boot or device name alone provides insufficient acceleration evidence. |
| P1 | Documentation | Missing end-to-end public build and OpenCore reproduction recipe, clean-checkout test matrix, tested toolchain/SDK revisions, and target recovery record. |

## Upstream tracker

The public tracker showed 10 open issues and 3 open PRs. Issue 11 and PR 17 describe a descriptor log format mismatch and proposed fix. Issue 14 requests reproducible Metal build 52 inputs associated with PR 12. PR 12 changes VMID pooling, boot auto-arm and the application-open policy. Keep it separate from the baseline and evaluate its security and lifecycle effects independently. PR 13 covers a Linux RDNA3 build recipe outside the initial target. Other discussions include attribution, contributor collaboration, expanded Metal APIs, older macOS and additional GPUs. [Issues](https://github.com/Almosst-DEV/Cobalt64/issues) · [Pull requests](https://github.com/Almosst-DEV/Cobalt64/pulls)


## Lifecycle review at the pinned baseline

### P0 candidate — teardown can release storage after MES disable fails

In src/navi48-bringup/src/amd/amdgpu_init.cpp, bringup_teardown logs an unacknowledged MES queue removal and continues to stop the engines. If mes_enable(false) fails, teardown logs that failure and still calls mes_release_storage and the other release functions. Navi48Bringup::stop subsequently unmaps BARs. Verify which engine-stop and reset acknowledgements are sufficient to prove that DMA is quiescent before releasing each allocation. The current control flow establishes a failure-handling gap. Whether the GPU can still fetch a given buffer on each failure path requires hardware-specific review. Use a fake-engine failure injection to check ownership and ordering before any unload trial.

### Startup and provider teardown

Navi48Bringup::start publishes gBringupSelf and gBringupPci before validating the PCI provider and enables PCI memory decoding before mapping BAR5. The BAR5 mapping failure returns directly, and the probe failure unmaps registers before returning. Neither branch visibly reverses the early publication or PCI command changes. Check every reader of those globals and confirm what IOKit restores on a failed start before proposing a fix. Normal stop restores display hooks, shuts down scanout and the nubs, tears down the hardware, disarms the host interrupt source and unmaps BARs. Verify that interrupt handlers and client calls have drained before their backing memory is freed.

### Native submit, wait and close

The native user client enforces route and role gates, rejects out-of-line structures and bounds the submission descriptor. n1c_submit validates context and fence handles and requires each IB address range to be covered by executable mappings. This check covers the submitted ranges. Review reachable PM4 operations, nested command streams and mapping lifetime separately before considering broader application access.

n1c_close parks the VMID before releasing BOs after successful retirement. If retirement or parking cannot be proven, it keeps GPU-visible allocations pinned and marks the slot unavailable. Preserve that behavior when investigating device teardown. n1c_wait polls against a bounded timeout and distinguishes ordinary expiration in the result payload from a detected hang error. Review whether a waiter can observe a reused static session record after a concurrent close. Verify the caller handles both timeout forms.

### Host and target inventory

Docker Desktop's Linux daemon was unreachable, so it could not supply a compiler for host suites in this session. Windows CIM access was denied during the read-only GPU inventory attempt. Exact PCI and subsystem IDs remain unverified. The tracked plists cover driver personalities and helper daemons. The source tree does not contain a target OpenCore configuration.

### Teardown acknowledgement trace

- MES disable writes halt/reset and reads CP_MES_CNTL for logging. It clears both software enabled flags and returns success regardless of readback. Checking the existing return value alone cannot prove DMA quiescence.
- CP graphics halt polls CP_STAT for up to 100 ms. It logs a timeout and still returns success. SDMA halt logs MCU_CNTL readback and returns success without an idle check. Teardown discards the CP, SDMA and IH stop results.
- Separate the requested register state, observed register state and evidence that outstanding work drained. The failure-injection matrix must include an unacknowledged queue removal, mismatched halt readback, CP timeout, and interrupt delivery during teardown. Until those contracts are established, keep unload/reload out of the hardware trial plan.
