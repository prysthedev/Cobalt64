# Known issues

| Issue | Status |
| --- | --- |
| DMA teardown | MES and SDMA report success without proving idle. CP logs an idle timeout and still reports success. Keep unload/reload pending until teardown can retain resources when quiescence is uncertain. |
| Public test fixtures | Full xlat12 and ReBAR checks require unpublished inputs. Linux CI covers the public register translator and fuzz tests, public ReBAR checks and firmware staging. |
| macOS build inputs | MacKernelSDK revision, complete Darwin RADV build invocation and an independent clean build are pending. |
| Display modes | Upstream reports fixed modes on its reference system. Validate one target display before enabling multi-display or auto-arm. |
| Recovery | Target macOS boot, independent Windows boot and fallback EFI still need verification before the first experimental kext trial. |
