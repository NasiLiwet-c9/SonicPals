//
//  PresentationTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 07/09/26.
//

import SonarCore
import Testing
import UIKit

@testable import SonicPals

@Suite("Quiz")
struct QuizTests {
    @Test("Sound is the right answer; light is not")
    func onlySoundIsCorrect() {
        #expect(QuestionCardView.Answer.ultrasonic.isCorrect)
        #expect(!QuestionCardView.Answer.flashlight.isCorrect)
    }
}

/// The tutorial tells a child "red is close, blue is far", so that had better be what the mesh does
@Suite("Reveal style")
struct FPStyleTests {
    private func style(_ band: FPBand, _ zone: FPZone = .core) -> FPStyle {
        FPKey(band: band, zone: zone).style
    }

    private struct RGB {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
    }

    private func rgb(_ color: UIColor) -> RGB {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGB(r: r, g: g, b: b)
    }

    @Test("The closest band really is red")
    func closestIsRed() {
        let colour = rgb(style(.hot).color)

        #expect(colour.r > colour.b)
        #expect(colour.r > colour.g)
    }

    @Test("The furthest band really is blue-green, not red")
    func furthestIsBlue() {
        let colour = rgb(style(.far).color)

        #expect(colour.b > colour.r)
        #expect(colour.g > colour.r)
    }

    @Test("Every band gets its own colour")
    func bandsAreDistinct() {
        let colours = FPBand.allCases.map { style($0).color }
        let unique = Set(colours.map { "\($0)" })

        #expect(unique.count == FPBand.allCases.count)
    }

    @Test(
        "Every alpha is a legal opacity",
        arguments: FPBand.allCases
    )
    func alphasAreLegal(band: FPBand) {
        for zone in FPZone.allCases {
            let style = FPKey(band: band, zone: zone).style

            #expect(style.wireA >= 0 && style.wireA <= 1)
            #expect(style.fillA >= 0 && style.fillA <= 1)
        }
    }

    @Test("The middle of the beam reads stronger than its edge")
    func coreBeatsEdge() {
        #expect(style(.hot, .core).wireA > style(.hot, .edge).wireA)
        #expect(style(.hot, .core).fillA > style(.hot, .edge).fillA)
    }

    @Test("The outline always reads stronger than the fill")
    func wireBeatsFill() {
        for band in FPBand.allCases {
            for zone in FPZone.allCases {
                let style = FPKey(band: band, zone: zone).style

                #expect(style.wireA > style.fillA)
            }
        }
    }

    @Test("The reveal sweeps outward, edge first")
    func revealDelaysStagger() {
        #expect(style(.hot, .edge).delayMs == 0)
        #expect(style(.hot, .soft).delayMs > style(.hot, .edge).delayMs)
        #expect(style(.hot, .core).delayMs > style(.hot, .soft).delayMs)
    }
}

@Suite("Layout scaling")
struct UICfgTests {
    private let reference = CGSize(width: UICfg.refW, height: UICfg.refH)

    @Test("The reference screen scales by one")
    func referenceIsUnscaled() {
        #expect(abs(UICfg.s(reference) - 1) < 0.0001)
        #expect(abs(UICfg.v(100, reference) - 100) < 0.0001)
    }

    @Test("A bigger screen scales up, a smaller one down")
    func scaleFollowsSize() {
        let big = CGSize(width: UICfg.refW * 2, height: UICfg.refH * 2)
        let small = CGSize(width: UICfg.refW / 2, height: UICfg.refH / 2)

        #expect(UICfg.s(big) > 1)
        #expect(UICfg.s(small) < 1)
    }

    @Test("Scaling takes the tighter of the two axes")
    func scaleTakesTheTighterAxis() {
        // Scaling a narrow screen by height would run off the sides
        let narrow = CGSize(width: UICfg.refW / 2, height: UICfg.refH * 2)

        #expect(abs(UICfg.s(narrow) - 0.5) < 0.0001)
    }

    @Test("Per-axis helpers follow their own axis")
    func axisHelpersAreIndependent() {
        let wide = CGSize(width: UICfg.refW * 2, height: UICfg.refH)

        #expect(abs(UICfg.x(100, wide) - 200) < 0.0001)
        #expect(abs(UICfg.y(100, wide) - 100) < 0.0001)
    }
}
