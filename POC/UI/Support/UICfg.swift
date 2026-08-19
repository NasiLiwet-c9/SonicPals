//
//  UICfg.swift
//  POC
//
//  Created by Shan Newcastle on 19/08/26.
//

import CoreGraphics

nonisolated enum UICfg {
    static let refW: CGFloat = 393      // Reference width.
    static let refH: CGFloat = 852      // Reference height.

    static func s(_ size: CGSize) -> CGFloat {
        min(size.width / refW, size.height / refH)
    }

    static func v(_ value: CGFloat, _ size: CGSize) -> CGFloat {
        value * s(size)
    }

    static func x(_ value: CGFloat, _ size: CGSize) -> CGFloat {
        value * (size.width / refW)
    }

    static func y(_ value: CGFloat, _ size: CGSize) -> CGFloat {
        value * (size.height / refH)
    }

    enum Home {
        static let bgW: CGFloat = 390      // Main BG width.
        static let bgY: CGFloat = 0        // Main BG Y.

        static let bat: CGFloat = 240      // Battiw size.
        static let playW: CGFloat = 220    // Play width.
        static let playH: CGFloat = 64     // Play height.
        static let mapW: CGFloat = 76      // Map width.
        static let mapH: CGFloat = 86      // Map height.

        static let gap: CGFloat = 18       // Button gap.
        static let bottom: CGFloat = 210   // Bottom gap.
    }

    enum Load {
        static let bgW: CGFloat = 393      // Loading BG width.
        static let bgH: CGFloat = 852      // Loading BG height.
        static let bgY: CGFloat = 0        // Loading BG Y.
        static let sec: Double = 1.8       // Loading time.

        static let barW: CGFloat = 300     // Loading bar width.
        static let barH: CGFloat = 14      // Loading bar height.
        static let barY: CGFloat = 740     // Loading bar Y.
    }

    enum Trans {
        static let gifW: CGFloat = 393     // Transition width.
        static let gifY: CGFloat = 0       // Transition Y.
        static let dim: CGFloat = 0.18     // Extra dim.

        static let preMs = 700             // Before fade.
        static let fade: Double = 0.35     // Fade time.
        static let postMs = 700            // Before play.
    }

    enum Eat {
        static let gifW: CGFloat = 393     // Bite width.
        static let gifY: CGFloat = 0       // Bite Y.
        static let ms = 500                // Bite time.
    }

    enum Map {
        static let bgW: CGFloat = 393      // Map BG width.
        static let bgH: CGFloat = 852      // Map BG height.
        static let bgY: CGFloat = 0        // Map BG Y.

        static let bat: CGFloat = 145      // Battiw size.
        static let batX: CGFloat = 170     // Battiw X.
        static let batY: CGFloat = 188     // Battiw Y.

        static let backW: CGFloat = 51     // Back width.
        static let backH: CGFloat = 48     // Back height.
        static let backX: CGFloat = 48     // Back X.
        static let backY: CGFloat = 85     // Back Y.

        static let oneX: CGFloat = 128     // Level 1 X.
        static let oneY: CGFloat = 265     // Level 1 Y.
        static let oneW: CGFloat = 100     // Level 1 tap width.
        static let oneH: CGFloat = 75      // Level 1 tap height.

        static let lockX: CGFloat = 175    // Lock X.
        static let lockY: CGFloat = 605    // Lock Y.
        static let lockW: CGFloat = 100    // Lock tap width.
        static let lockH: CGFloat = 100    // Lock tap height.

        static let msgW: CGFloat = 200     // Lock bubble width.
        static let msgX: CGFloat = 170     // Lock bubble X.
        static let msgY: CGFloat = 520     // Lock bubble Y.
        static let msgTxt: CGFloat = 16    // Lock text size.
        static let msgTxtY: CGFloat = -10  // Lock text Y.
    }

    enum Dlg {
        static let bat: CGFloat = 240      // Home Battiw size.
        static let bubW: CGFloat = 170     // Home bubble width.
        static let shortH: CGFloat = 81    // Short bubble height.
        static let tallH: CGFloat = 167    // Tall bubble height.

        static let gap: CGFloat = -50      // Bubble/Battiw gap.
        static let shortY: CGFloat = -15   // Short bubble Y.
        static let tallY: CGFloat = -88    // Tall bubble Y.
        static let txt: CGFloat = 16       // Home text size.
        static let padX: CGFloat = 20      // Text padding.
    }

    enum Sess {
        static let topW: CGFloat = 250     // Top bubble width.
        static let topH: CGFloat = 108     // Top bubble height.
        static let topTxt: CGFloat = 15    // Top text size.
        static let topBat: CGFloat = 130   // Top Battiw size.
        static let topGap: CGFloat = -125  // Top bubble gap.
        static let topBatX: CGFloat = 52   // Top Battiw X.
        static let topBatY: CGFloat = 14   // Top Battiw Y.
        static let topPadX: CGFloat = 20   // Top text padding.
        static let topPadY: CGFloat = 20   // Top text Y.

        static let botW: CGFloat = 270     // Mission bubble width.
        static let botTxt: CGFloat = 18    // Mission text size.
        static let botPadX: CGFloat = 20   // Mission text padding.
        static let botPadY: CGFloat = 20   // Mission text Y.
        static let botBottom: CGFloat = 12 // Mission bottom gap.

        static let statusTxt: CGFloat = 15 // Status text size.
    }

    enum Scan {
        static let pctTxt: CGFloat = 19    // Scan percent size.
        static let pctY: CGFloat = 70      // Scan percent Y.
        static let pctPadX: CGFloat = 10   // Percent side padding.
        static let pctPadY: CGFloat = 5    // Percent top padding.
        static let pctBg: CGFloat = 0.55   // Percent BG opacity.

        static let arrTxt: CGFloat = 18    // Scan arrow size.
        static let arrX: CGFloat = 90      // Scan arrow X.
    }

    enum Done {
        static let cardW: CGFloat = 440    // Complete card width.
        static let cardY: CGFloat = 0      // Complete card Y.

        static let nextW: CGFloat = 140    // Next width.
        static let nextX: CGFloat = 88     // Next X.
        static let nextY: CGFloat = 290    // Next Y.

        static let bottom: CGFloat = 10    // Bottom gap.
        static let dim: CGFloat = 0.55     // Background dim.
    }

    enum Quiz {
        static let cardW: CGFloat = 365    // Question card width.
        static let cardH: CGFloat = 423    // Question card height.
        static let qW: CGFloat = 275       // Question text width.
        static let qTxt: CGFloat = 19      // Question text size.
        static let qGap: CGFloat = 16      // Question/answer gap.

        static let ansW: CGFloat = 165     // Answer button width.
        static let ansTxt: CGFloat = 14    // Answer text size.
        static let ansGap: CGFloat = 10    // Answer button gap.

        static let resW: CGFloat = 350     // Result card width.
        static let resTop: CGFloat = 132   // Result text Y.
        static let resTitle: CGFloat = 20  // Correct title size.
        static let resTxt: CGFloat = 17    // Result text size.
        static let resTxtW: CGFloat = 245  // Result text width.

        static let againW: CGFloat = 350   // Replay card width.
        static let againTxt: CGFloat = 20  // Replay title size.
        static let againBtnW: CGFloat = 160 // Replay button width.
        static let againBtnTxt: CGFloat = 13 // Replay button text.

        static let backTxt: CGFloat = 13   // Menu text size.
        static let gap: CGFloat = 18       // Result card gap.
    }
}
