//
//  SfxSvc.swift
//  POC
//
//  Created by Jayvin Tiya Silo on 14/08/26.
//

import AVFoundation

@MainActor
final class SfxSvc {
    static let shared = SfxSvc()

    // MARK: - Audio Files
    // Change filenames here only. Extension does not matter.

    private enum File {
        static let menu = "bgm-menu"                 // Main menu BGM.
        static let ses = "bgm-session"               // AR/session BGM.
        static let quiz = "bgm-quiz"                 // Quiz BGM.

        static let tap = "ui-tap-sfx"                // Meaningful UI tap.
        static let dlg = "dialogue-sfx"              // New dialogue line appears.
        static let sonar = "sonar-sfx"               // Sonar button/ping.
        static let tDet = "tree-detect-sfx"          // Tree echo first detected.
        static let tFnd = "tree-found-sfx"            // Full tree is discovered.
        static let mDet = "mango-detect-sfx"         // Violet mango echo detected.
        static let mRdy = "mango-ready-sfx"           // Close enough to eat mango.
        static let eat = "eat-sfx"                   // Mango eaten.
        static let ok = "correct-sfx"                // Correct quiz answer.
        static let bad = "incorrect-sfx"             // Incorrect quiz answer.
        static let done = "mission-complete-sfx"     // All 3 mangoes found.
        static let scan = "scan-complete-sfx"        // Room scanning completed.

        static let amb = "night ambience-sfx"        // Existing night ambience.

        static let wind = "wind-sfx"                 // Existing, currently unused.
        static let rustle = "grasakgrusuk"           // Existing, currently unused.
        static let rustle2 = "grusukgrusuk-sfx"      // Existing, currently unused.
    }

    private enum Bgm: CaseIterable {
        case menu, ses, quiz

        var file: String {
            switch self {
            case .menu: File.menu
            case .ses: File.ses
            case .quiz: File.quiz
            }
        }

        var vol: Float {
            switch self {
            case .menu: 0.48
            case .ses: 0.42
            case .quiz: 0.48
            }
        }
    }

    private enum Fx: CaseIterable {
        case tap, dlg, sonar, tDet, tFnd, mDet, mRdy
        case eat, ok, bad, done, scan

        var file: String {
            switch self {
            case .tap: File.tap
            case .dlg: File.dlg
            case .sonar: File.sonar
            case .tDet: File.tDet
            case .tFnd: File.tFnd
            case .mDet: File.mDet
            case .mRdy: File.mRdy
            case .eat: File.eat
            case .ok: File.ok
            case .bad: File.bad
            case .done: File.done
            case .scan: File.scan
            }
        }

        var vol: Float {
            switch self {
            case .tap: 0.30
            case .dlg: 0.42
            case .sonar: 1.00
            case .tDet: 0.65
            case .tFnd: 0.78
            case .mDet: 0.65
            case .mRdy: 0.58
            case .eat: 1.00
            case .ok: 0.82
            case .bad: 0.55
            case .done: 0.88
            case .scan: 0.68
            }
        }
    }

    private let fade: TimeInterval = 0.9
    private let exts = ["mp3", "m4a", "wav", "caf", "aiff", "aac"]

    private var bgm: [Bgm: AVAudioPlayer] = [:]
    private var fx: [Fx: AVAudioPlayer] = [:]
    private var amb: AVAudioPlayer?
    private var cur: Bgm?
    private var fadeTask: Task<Void, Never>?

    private init() {
        configureSession()
        loadBgm()
        loadFx()

        amb = make(File.amb)
        amb?.numberOfLoops = -1
        amb?.volume = 0.30
    }

    // MARK: - BGM

    func menuBgm() {
        cross(to: .menu)
    }

    func sessionBgm() {
        cross(to: .ses)
    }

    func quizBgm() {
        cross(to: .quiz)
    }

    // MARK: - SFX

    func tap() {
        play(.tap)
    }

    func dialogue() {
        play(.dlg)
    }

    func sonar() {
        play(.sonar)
    }

    func treeDetect() {
        play(.tDet)
    }

    func treeFound() {
        play(.tFnd)
    }

    func mangoDetect() {
        play(.mDet)
    }

    func mangoReady() {
        play(.mRdy)
    }

    func eat() {
        play(.eat)
    }

    func correct() {
        play(.ok)
    }

    func incorrect() {
        play(.bad)
    }

    func complete() {
        play(.done)
    }

    func scanDone() {
        play(.scan)
    }

    // MARK: - Ambience

    func startAmbience() {
        guard let amb, !amb.isPlaying else { return }

        amb.currentTime = 0
        amb.play()
    }

    func stopAmbience() {
        amb?.setVolume(0, fadeDuration: 0.35)

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(380))
            self?.amb?.stop()
            self?.amb?.currentTime = 0
            self?.amb?.volume = 0.30
        }
    }

    // MARK: - BGM Engine

    private func cross(to next: Bgm) {
        guard cur != next else {
            if let p = bgm[next], !p.isPlaying {
                p.volume = next.vol
                p.play()
            }
            return
        }

        fadeTask?.cancel()

        let old = cur.flatMap { bgm[$0] }
        let new = bgm[next]

        cur = next

        old?.setVolume(0, fadeDuration: fade)

        if let new {
            new.currentTime = 0
            new.volume = 0
            new.numberOfLoops = -1
            new.play()
            new.setVolume(next.vol, fadeDuration: fade)
        }

        fadeTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(fade))

            guard !Task.isCancelled else { return }

            old?.stop()
            old?.currentTime = 0
        }
    }

    // MARK: - Setup

    private func loadBgm() {
        for key in Bgm.allCases {
            guard let p = make(key.file) else { continue }

            p.numberOfLoops = -1
            p.volume = key.vol
            bgm[key] = p
        }
    }

    private func loadFx() {
        for key in Fx.allCases {
            guard let p = make(key.file) else { continue }

            p.volume = key.vol
            fx[key] = p
        }
    }

    private func play(_ key: Fx) {
        guard let p = fx[key] else { return }

        p.currentTime = 0
        p.play()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
#if DEBUG
            print("[AUDIO] session:", error.localizedDescription)
#endif
        }
    }

    private func make(_ name: String) -> AVAudioPlayer? {
        guard let url = find(name) else {
#if DEBUG
            print("[AUDIO] missing:", name)
#endif
            return nil
        }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            return p
        } catch {
#if DEBUG
            print("[AUDIO] load \(name):", error.localizedDescription)
#endif
            return nil
        }
    }

    private func find(_ name: String) -> URL? {
        for ext in exts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }

        return nil
    }
}
