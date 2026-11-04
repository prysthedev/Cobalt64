# Metal compatibility

| Area | Current evidence | Target verification |
| --- | --- | --- |
| Device discovery | Navi48Metal bundle and mtlprobe list implementation | Identify the RX 9070 XT registry ID on target macOS |
| Queues, buffers and textures | Source implements queue and resource creation, with restrictions on formats, storage and heap options | Allocate, submit and read back through the selected device |
| Render pipelines | Source implements render-pipeline creation and triangle probe | Run mtlprobe triangle with the target registry ID and compare readback |
| Precompiled shaders | Probe supports --precompiled and the bundle uses the AIR translator | Verify with a locally compiled metallib and record compiler build |
| WindowServer | Upstream reports hardware composition on one machine | Correlate compositor evidence with target GPU submissions and display output |
| Advanced APIs | Coverage varies by method and format | Pending per-feature tests after the basic render gate |

Upstream results establish a reference configuration. No target Metal test has
been recorded in HARDWARE_TEST_LOG.md.
