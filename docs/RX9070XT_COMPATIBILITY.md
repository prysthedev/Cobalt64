# RX 9070 XT compatibility

| Item | Evidence | Status |
| --- | --- | --- |
| GPU PCI vendor and device | Windows PnP reports AMD Radeon RX 9070 XT, 1002:7550 | Observed on target |
| GPU subsystem | PnP reports subsystem vendor 1DA2, subsystem device 3490 and PCI revision C0 | Observed on target |
| Kext match | Pinned Info.plist includes 0x75501002 in IOPCIPrimaryMatch | Static match verified |
| Above 4G, ReBAR and BAR lengths | Target firmware configuration and resource mapping still to be recorded | Unverified |
| macOS | Upstream reference is x86_64 Tahoe 26.6.2 through OpenCore | Target boot unverified |
| Initialization and VRAM | Require target logs showing mapped BARs, firmware and completed init stages | Unverified |
| Scanout and acceleration | Require single-display scanout, a GPU submission with fence and known readback, and WindowServer and Metal evidence | Unverified |

Inventory used the read-only command `pnputil /enum-devices /class Display /connected`. Record GPU IDs without the machine-specific device instance suffix in shared logs.
