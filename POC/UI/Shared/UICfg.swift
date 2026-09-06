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

    enum Intro {
        static let cardH: CGFloat = 430    // Pager height.
        static let mascot: CGFloat = 168   // Battiw size.
        static let bubW: CGFloat = 300     // Bubble width.
        static let gap: CGFloat = 6        // Mascot/bubble gap.

        static let titleTxt: CGFloat = 21  // Title size.
        static let bodyTxt: CGFloat = 15   // Body size.
        static let textGap: CGFloat = 7    // Title/body gap.
        static let textPadX: CGFloat = 34  // Text side padding.
        static let textPadY: CGFloat = 26  // Text bottom padding.

        static let badge: CGFloat = 34     // Badge icon size.
        static let badgeX: CGFloat = 10    // Badge X offset.
        static let badgeY: CGFloat = -6    // Badge Y offset.

        static let dotTop: CGFloat = 6     // Dots top gap.
        static let bottom: CGFloat = 40    // Button bottom gap.
        static let skipTxt: CGFloat = 14   // Skip text size.
        static let skipTop: CGFloat = 64   // Skip top gap.
    }

    /// How dark the mission gets. Nearly opaque on purpose — the room is
    /// meant to be unreadable until a ping reveals it. What has to punch
    /// through is the revealed geometry, which `RealityShade.keepBright`
    /// puts in front of the shade rather than under it.
    enum Shade {
        static let darkMid: CGFloat = 0.93     // Dark, centre.
        static let darkHalf: CGFloat = 0.96    // Dark, mid.
        static let darkEdge: CGFloat = 0.98    // Dark, edge.

        static let liteMid: CGFloat = 0.10     // Lit, centre.
        static let liteHalf: CGFloat = 0.20    // Lit, mid.
        static let liteEdge: CGFloat = 0.32    // Lit, edge.
    }

    /// Speech-bubble art carries its tail in the bottom of the frame, so
    /// the visual body sits above the frame centre. Text lifts by this
    /// fraction of the frame height to land in the body.
    enum Bubble {
        static let aspect: CGFloat = 400.0 / 925.0
        static let tailLift: CGFloat = 0.09

        static func textLift(width: CGFloat) -> CGFloat {
            width * aspect * tailLift
        }
    }

    enum Coach {
        static let top: CGFloat = 8        // Coach bubble top gap.
    }

    enum Credits {
        static let txt: CGFloat = 9        // Credits text size.
        static let gap: CGFloat = 2        // Line gap.
        static let padX: CGFloat = 18      // Side padding.
        static let bottom: CGFloat = 14    // Bottom gap.
        static let alpha: CGFloat = 0.92   // Credits opacity.
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
        static let topPadMascot: CGFloat = 64 // Right inset, under Battiw.
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

    enum Respawn {
        static let size: CGFloat = 44      // Button diameter.
        static let icon: CGFloat = 19      // Icon size.
        static let txt: CGFloat = 12       // Hint text size.
        static let gap: CGFloat = 8        // Hint/button gap.
        static let hintAfterS: Double = 35 // Delay before the hint shows.
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
