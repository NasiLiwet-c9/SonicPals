//
//  AppTheme.swift
//  POC
//
//  Created by Shan Newcastle on 04/09/26.
//

import SwiftUI

/// SF Pro Rounded, applied once at the root and inherited everywhere
///
/// Ask for size and weight only. An explicit `design:` opts that view
/// back out, which is what made the old UI inconsistent
extension View {
    func sonicPalsTypography() -> some View {
        fontDesign(.rounded)
    }
}
