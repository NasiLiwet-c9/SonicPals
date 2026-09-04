# SonarCore

The ultrasonic simulation behind Sonic Pals, with no rendering in it.

Plain Swift and `simd` only: no SwiftUI, UIKit, ARKit or RealityKit. That
is the point of the boundary — this is the part of the game that can be
unit-tested without a device, a camera or a running AR session.

| Area | Types |
| --- | --- |
| `Model` | `WaveSetting`, `WaveSet`, `WaveStart`, `WaveRay`, `WaveHit`, `WaveData`, `FPBand`, `FPZone`, `FPKey`, `FPTri`, `FPSample`, `FPItem`, `FPMeshData` |
| `Acoustics` | `EchoCalc`, `RayMaker` |
| `Sim` | `RayCasting` port, `WaveSim` |
| `Field` | `FPConeScan`, `FPHitScan`, `FPClassify`, `FPSampleSvc`, `FPMeshPack` |

`WaveSim` needs to intersect rays with the scanned room, which only
RealityKit can do, so the package declares the `RayCasting` port and the
app supplies `SceneRayCaster`. Anything producing an `Entity` stays in the
app for the same reason.

```bash
swift test
```
