# RX 9070 XT hardware test log

## Baseline inventory

| Observation | Evidence |
| --- | --- |
| Target board | Windows BIOS registry reports B850 AORUS ELITE WIFI7 ICE, BIOS F7d |
| GPU | Windows PnP reports 1002:7550, subsystem 1DA2:3490, revision C0 |
| Driver matching | Pinned kext plist includes 0x75501002 |
| BAR lengths and ReBAR | Windows CIM reported assigned memory ranges of 256 MiB above 4 GiB and 1 MiB below 4 GiB for PCI bus 3, device 0, function 0. BAR indices and ReBAR capability remain unverified. |
| macOS and recovery | Target build and fallback boot pending |

## Run record

No target macOS driver runs have been performed.

For each run, record the commit, artifact digest, macOS build, OpenCore configuration revision, GPU PCI ID, BAR lengths, display connector, explicit approval, and fallback boot method. Omit serial numbers and private identifiers from shared records.

| Gate | Evidence required |
| --- | --- |
| Recovery | Verify the baseline macOS boot and an independent Windows boot. Verify fallback media before the experimental boot. |
| Bring-up | Capture probe, firmware and stage results. Record PCI and VRAM evidence. Stop on panic, hang or an unexpected init failure. |
| Command execution | Submit one bounded workload, observe fence retirement and compare GPU readback to a known value. |
| Display | Verify one monitor with stable scanout. Record hardware composition evidence and a basic Metal render with known output. |
| Repeatability | Log consecutive cold boots and the render result for each boot. Include any panics, timeouts and recovery actions. |

After a failed driver boot, use the verified fallback EFI and collect diagnostics from the baseline. Leave unload and reload trials pending the DMA teardown review.
