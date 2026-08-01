import RealityKit
import simd

struct ARState: Equatable {
    var msg = "move cam to detect room"
    var lidarOK = false
    var hasBot = false
    var meshOn = false
}

struct BotPart {
    let root: Entity
    let sensor: Entity
}

enum WaveType {
    case outgoing
    case reflected
    case echo
}

struct WaveSeg {
    let start: SIMD3<Float>
    let end: SIMD3<Float>
    let type: WaveType
}

struct WaveData {
    let segs: [WaveSeg]
    let hits: [SIMD3<Float>]

    let rayCount: Int
    let hitCount: Int
    let echoCount: Int

    let bestPath: Float?
    let echoMs: Float?
}
