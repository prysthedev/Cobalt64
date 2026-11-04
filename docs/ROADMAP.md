# Development roadmap

| State | Milestone | Acceptance evidence |
| --- | --- | --- |
| Done | Pin upstream and capture initial public baseline | Detached upstream checkout, recorded SHA, documentation and tracker review, three host check results. |
| Done | Compare fork with upstream | Both default to main at the same SHA. Zero commits ahead or behind and no tree differences. |
| In progress | Finish source audit | Review start/stop, DMA, MMIO, ABI, timeout and boot paths. |
| Upcoming | Establish a clean build | Independently build x86_64 kext and native tools on macOS, apply all nine Mesa patches at the documented revision, verify firmware and record artifact architecture and digests. |
| Upcoming | Establish host regression baseline | Report public fixture-free suites separately from restricted fixture suites. Retain existing tests and mutation checks. Capture deterministic inputs and each failure reason. |
| Blocked on target inventory and approval | Recoverable test environment | Record GPU IDs and subsystem IDs, BARs, firmware settings, board BIOS, monitor connection and macOS build. Verify a baseline boot and fallback EFI from independent media before a kext experiment. |
| Upcoming | Basic driver operation | Record PCI match, BAR mapping, VRAM and init results. Allocate and free buffers, submit a bounded GPU workload, verify its fence and read back a known result. Test timeout and client teardown. |
| Upcoming | One display and basic acceleration | Verify scanout with one monitor, WindowServer hardware composition evidence, Metal device/queue initialization and a render with known readback on the target RX 9070 XT. |
| Upcoming | Reliability | Record ten consecutive cold boots as an initial project gate, repeat the rendering test, and verify baseline recovery and Windows boot. Record panics, hangs, failed fences and recovery results. |

## Implemented firmware preflight

The read-only firmware preflight is in tools/verify-dependencies.sh. Reuse the upstream digest manifest with one source of truth. Check all ten local blobs and the license file, reject missing or mismatched data, and give actionable diagnostics. Four synthetic checks passed on Windows with Git Bash. The compressed case requires zstd and was skipped. The verifier runs without loading a driver or writing to the firmware staging directory.
