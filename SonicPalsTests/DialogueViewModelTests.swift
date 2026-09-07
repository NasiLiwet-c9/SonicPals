//
//  DialogueViewModelTests.swift
//  POCTests
//
//  Created by Shan Newcastle on 06/09/26.
//

import Foundation
import Testing

@testable import SonicPals

@Suite("Dialogue")
struct DialogueViewModelTests {
    private func tick() async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(2))
    }

    private func wait(until predicate: () -> Bool) async {
        for _ in 0..<300 where !predicate() {
            await tick()
        }
    }

    @Test("A line shows whole, with no typing to wait through")
    func linesShowWhole() {
        let model = DialogueViewModel(lines: ["Hello there", "Second"])
        model.start()

        #expect(model.visibleText == "Hello there")
        #expect(model.currentLineIndex == 0)
    }

    @Test("Tapping moves to the next line")
    func tapAdvances() {
        let model = DialogueViewModel(lines: ["One", "Two"])
        model.start()

        model.advance()

        #expect(model.visibleText == "Two")
        #expect(model.currentLineIndex == 1)
    }

    @Test("Running out of lines reports back")
    func finishesAtTheEnd() {
        var finished = false

        let model = DialogueViewModel(lines: ["Only"]) {
            finished = true
        }

        model.start()
        model.advance()

        #expect(finished)
    }

    @Test("A looping run starts over instead of finishing")
    func loopsBackToTheStart() {
        var finished = false

        let model = DialogueViewModel(lines: ["One", "Two"], loops: true) {
            finished = true
        }

        model.start()
        model.advance()
        model.advance()

        #expect(model.currentLineIndex == 0)
        #expect(model.visibleText == "One")
        #expect(!finished)
    }

    @Test("Lines move on by themselves when asked to")
    func autoAdvances() async {
        let model = DialogueViewModel(
            lines: ["One", "Two"],
            autoAdvance: .milliseconds(10)
        )

        model.start()

        await wait { model.currentLineIndex == 1 }

        #expect(model.visibleText == "Two")
    }

    @Test("Without auto-advance a line waits for a tap")
    func waitsForATapWhenAsked() async {
        let model = DialogueViewModel(lines: ["One", "Two"])
        model.start()

        for _ in 0..<20 {
            await tick()
        }

        #expect(model.currentLineIndex == 0)
    }

    @Test("Stopping halts the auto-advance")
    func stopHalts() async {
        let model = DialogueViewModel(
            lines: ["One", "Two"],
            autoAdvance: .milliseconds(30)
        )

        model.start()
        model.stop()

        for _ in 0..<30 {
            await tick()
        }

        #expect(model.currentLineIndex == 0)
    }

    @Test("An empty script has nothing to show and does not crash")
    func emptyScriptIsSafe() {
        let model = DialogueViewModel(lines: [])
        model.start()

        #expect(model.visibleText.isEmpty)

        model.advance()

        #expect(model.visibleText.isEmpty)
    }

    @Test("An empty looping script does not spin")
    func emptyLoopIsSafe() {
        var finished = false

        let model = DialogueViewModel(lines: [], loops: true) {
            finished = true
        }

        model.start()
        model.advance()

        #expect(finished)
    }
}
