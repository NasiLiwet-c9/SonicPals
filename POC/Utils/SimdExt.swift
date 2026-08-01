import simd

extension simd_float4x4 {
    var pos3: SIMD3<Float> {
        SIMD3<Float>(
            columns.3.x,
            columns.3.y,
            columns.3.z
        )
    }
}
