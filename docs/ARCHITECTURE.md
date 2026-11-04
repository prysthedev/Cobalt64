# Architecture

The native path runs Metal calls through Navi48Metal, Darwin RADV and the
N48N IOKit user client. Navi48Bringup owns PCI discovery, firmware, GPU queues,
memory mappings and interrupts. The DCN code owns scanout programming and
restoration. The auxiliary navi48accel kext provides a separate accelerator
attachment route. The diagnostic CLI uses both diagnostic and native interfaces.

N48N ABI 1.12 carries resource creation, GPU VA mappings, command submission
and fence waits. It also exposes scanout and host import through role-gated
selectors. Treat the kernel header and the mirrored RADV structures as one
interface when changing layouts or selector behavior.

Shader translation uses the Apple compiler and the separately licensed
libn48xlate wrapper around metal2vulkan. The older Apple accelerator route
uses xlat12 to translate register and PM4 streams and has distinct capture
and shader-cache dependencies. See PROJECT_AUDIT.md for the dependency and
lifecycle review.
