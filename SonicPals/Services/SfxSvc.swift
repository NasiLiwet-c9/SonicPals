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
    // Change filenames/volumes here only. Extension does not matter

    private enum File {
        static let menu = "bgm-menu"                 // Main menu BGM.
        static let ses = "bgm-session"               // AR/session BGM.
        static let quiz = "bgm-quiz"                 // Mini quiz BGM.

        static let tap = "ui-tap-sfx"                // Meaningful UI tap.
        static let dlg = "dialogue-sfx"              // New dialogue line appears.
        static let sonar = "sonar-sfx"               // Sonar button/ping.
        static let tFnd = "tree-found-sfx"           // Full tree is discovered.
        static let mDet = "mango-detect-sfx"         // Violet mango echo detected.
        static let eat = "eat-sfx"                   // Mango bite/eat sound.
        static let ok = "correct-sfx"                // Correct quiz answer.
        static let bad = "incorrect-sfx"             // Incorrect quiz answer.
        static let done = "mission-complete-sfx"     // Older completion cue, kept available.
        static let scan = "scan-complete-sfx"        // Room scanning completed.
        static let pop = "pop-up-sfx"                // Completion/quiz card pops in.
        static let lvl = "level-complete-sfx"        // All 3 mangoes completed.

        static let amb = "night ambience-sfx"        // Night ambience during AR.
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
            case .menu: 0.36
            case .ses: 0.16
            case .quiz: 0.36
            }
        }
    }

    private enum Sfx: CaseIterable {
        case tap, dlg, sonar, tFnd, mDet, eat
        case ok, bad, done, scan, pop, lvl

        var file: String {
            switch self {
            case .tap: File.tap
            case .dlg: File.dlg
            case .sonar: File.sonar
            case .tFnd: File.tFnd
            case .mDet: File.mDet
            case .eat: File.eat
            case .ok: File.ok
            case .bad: File.bad
            case .done: File.done
            case .scan: File.scan
            case .pop: File.pop
            case .lvl: File.lvl
            }
        }

        var vol: Float {
            switch self {
            case .tap: 0.28
            case .dlg: 0.40
            case .sonar: 0.85
            case .tFnd: 0.72
            case .mDet: 0.62
            case .eat: 1.00
            case .ok: 0.82
            case .bad: 0.55
            case .done: 0.72
            case .scan: 0.65
            case .pop: 0.45
            case .lvl: 0.85
            }
        }
    }

    private let fade: TimeInterval = 0.9
    private let ambVol: Float = 0.10
    private let exts = ["mp3", "m4a", "wav", "caf", "aiff", "aac"]

    private var bgm: [Bgm: AVAudioPlayer] = [:]
    private var fx: [Sfx: AVAudioPlayer] = [:]
    private var amb: AVAudioPlayer?
    private var cur: Bgm?
    private var fadeTask: Task<Void, Never>?
    private var duckTask: Task<Void, Never>?

    private init() {
        configureSession()
        loadBgm()
        loadFx()

        amb = make(File.amb)
        amb?.numberOfLoops = -1
        amb?.volume = ambVol
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

    func stopBgm() {
        fadeTask?.cancel()
        duckTask?.cancel()

        guard let cur else { return }

        let old = bgm[cur]
        self.cur = nil
        old?.setVolume(0, fadeDuration: fade)

        fadeTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(fade))
            guard !Task.isCancelled else { return }

            old?.stop()
            old?.currentTime = 0
        }
    }

    // MARK: - SFX

    func tap() { play(.tap) }
    func dialogue() { play(.dlg) }
    func sonar() { play(.sonar) }
    func treeFound() { play(.tFnd) }
    func mangoDetect() { play(.mDet) }

    func eat() {
        duckForEat()
        play(.eat)
    }

    func correct() { play(.ok) }
    func incorrect() { play(.bad) }
    func missionDone() { play(.done) }
    func scanDone() { play(.scan) }
    func popup() { play(.pop) }
    func levelDone() { play(.lvl) }

    func treeDetect() {
        // tree-detect-sfx removed, kept so call sites still compile
    }

    func mangoReady() {
        // mango-ready-sfx removed, kept so call sites still compile
    }

    // MARK: - Ambience

    func startAmbience() {
        guard let amb, !amb.isPlaying else { return }

        amb.currentTime = 0
        amb.volume = ambVol
        amb.play()
    }

    func stopAmbience() {
        amb?.setVolume(0, fadeDuration: 0.35)

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(380))
            guard let self else { return }

            self.amb?.stop()
            self.amb?.currentTime = 0
            self.amb?.volume = self.ambVol
        }
    }

    // MARK: - BGM Engine

    private func cross(to next: Bgm) {
        guard cur != next else {
            if let p = bgm[next], !p.isPlaying {
                p.volume = next.vol
                p.play()
            }
            return }

        fadeTask?.cancel()
        duckTask?.cancel()

        if amb?.isPlaying == true {
            amb?.setVolume(ambVol, fadeDuration: 0.12)
        }

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

    private func duckForEat() {
        duckTask?.cancel()

        guard let cur, let p = bgm[cur], p.isPlaying else { return }

        p.setVolume(0.035, fadeDuration: 0.05)
        amb?.setVolume(0.02, fadeDuration: 0.05)

        duckTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(760))
            guard let self, !Task.isCancelled, self.cur == cur else { return }

            p.setVolume(cur.vol, fadeDuration: 0.18)

            if self.amb?.isPlaying == true {
                self.amb?.setVolume(self.ambVol, fadeDuration: 0.18)
            }
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
        for key in Sfx.allCases {
            guard let p = make(key.file) else { continue }

            p.volume = key.vol
            fx[key] = p
        }
    }

    private func play(_ key: Sfx) {
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

    /// Not an asset-catalog data set: that hands back `Data` and holds
    /// every track in memory. BGM wants streaming from disk
    private func find(_ name: String) -> URL? {
        for ext in exts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }

        return nil
    }
}
