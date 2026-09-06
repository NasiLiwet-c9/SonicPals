//
//  DebugHooks.swift
//  POC
//
//  Created by Shan Newcastle on 19/08/26.
//

import SwiftUI

/// Seams the shipping code uses to reach dev-only tooling. Both compile
/// to nothing in release, so no feature folder needs its own `#if DEBUG`
extension View {
    /// No-op outside DEBUG
    @ViewBuilder
    func debugForceSpawn(world: ECSWorld) -> some View {
#if DEBUG
        overlay {
            ForceSpawnSecret(world: world)
        }
#else
        self
#endif
    }
}

extension ECSWorld {
    /// Always `false` in release builds
    var forceSpawnActive: Bool {
#if DEBUG
        ForceSpawnRuntime.shared.isActive(for: self)
#else
        false
#endif
    }
}
