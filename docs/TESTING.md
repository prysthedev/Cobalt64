# Testing Cobalt64

Run build-only and host tests on the separate Mac. Record the source revision, macOS build, toolchain and fixture set with every result.

| Check | Command or evidence | Scope |
| --- | --- | --- |
| Firmware scripts | `python3 tools/test-firmware.py -v` | Synthetic input only. Install zstd to exercise compressed inputs. |
| Bring-up host suites | `bash tools/conductor/suites.sh "$PWD" /absolute/path/to/test-output` | Inspect per-suite compiler and test logs. Host shims and synthetic vectors provide source-level regression coverage. |
| xlat12 | `make -C src/xlat12 test` | Combined C and Python target. The public tree lacks gfx-readset.py and Apple ABI fixtures required by its Python checks. Report the C test outcomes separately if those checks fail. |
| M6 display orchestration | `bash tools/pc/m6-stage2-sim/test-parsers.sh` | Fake CLI and parser inputs. Inspect the script and scratch directory before execution. |
| macOS build | Follow DEVELOPMENT_SETUP.md and BUILD_GUIDE.md | Compile kext and native tools, inspect x86_64 artifacts and save warnings. |
| Target driver integration | Capture driver logs and actual PCI identity, BAR lengths, VRAM, buffer lifecycle, submission, fence and known readback | Requires a recoverable target boot and approval before loading the experimental kext. |

Classify missing tools and fixtures separately from assertion failures. Keep local Apple-derived inputs out of commits. Track each stage in HARDWARE_TEST_LOG.md.

The Linux CI invokes native_rebar_test with `--public-checkout`. This reports
P9 separately because upstream's OpenCore variant and rescue plists are absent.
The default invocation still requires those fixtures and checks their exact
content. The optional Mesa source pins retain their existing behavior.
