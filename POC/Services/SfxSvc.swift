//
//  SfxSvc.swift
//  POC
//
//  Created by Jayvin Tiya Silo on 14/08/26.
//

import AVFoundation

/// Plays short one-shot sound effects. Mirrors `HapticSvc`: load /
/// prepare everything up front in `init`, expose plain fire-and-forget
/// methods for call sites.
@MainActor
final class SfxSvc {
    private var sonarPlayer: AVAudioPlayer?
    private var ambiencePlayer: AVAudioPlayer?
    private var eatPlayer: AVAudioPlayer?

    init() {
        configureSession()
        sonarPlayer = makePlayer(named: "sonar-sfx", ext: "mp3")
        ambiencePlayer = makePlayer(named: "night ambience-sfx", ext: "mp3")
        ambiencePlayer?.numberOfLoops = -1
        ambiencePlayer?.volume = 0.5
        eatPlayer = makePlayer(named: "eat-sfx", ext: "mp3")
    }

    /// Plays the sonar ping. Safe to call rapidly — restarts from the
    /// top each time rather than queuing or overlapping instances.
    func sonar() {
        guard let sonarPlayer else {
            return
        }

        sonarPlayer.currentTime = 0
        sonarPlayer.play()
    }

    /// Plays the mango-eaten bite sound. Safe to call rapidly —
    /// restarts from the top each time rather than queuing or
    /// overlapping instances.
    func eat() {
        guard let eatPlayer else {
            return
        }

        eatPlayer.currentTime = 0
        eatPlayer.play()
    }

    /// Starts the looping night-ambience bed. Safe to call more than
    /// once — a call while it's already playing is a no-op rather
    /// than restarting the loop from the top.
    func startAmbience() {
        guard let ambiencePlayer,
              !ambiencePlayer.isPlaying
        else {
            return
        }

        ambiencePlayer.play()
    }

    func stopAmbience() {
        ambiencePlayer?.stop()
    }

    // MARK: - Setup

    /// `.ambient` + `.mixWithOthers` so the SFX doesn't interrupt any
    /// other audio (e.g. music) the user has playing, and still
    /// respects the silent switch. Switch to `.playback` here if you
    /// want the sonar ping to play even with the ringer silenced.
    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                options: [.mixWithOthers]
            )

            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(
                "SFX: audio session setup failed -",
                error.localizedDescription
            )
        }
    }

    private func makePlayer(
        named name: String,
        ext: String
    ) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: ext
        ) else {
            print("SFX: \(name).\(ext) not found in app bundle")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print(
                "SFX: failed to load \(name).\(ext) -",
                error.localizedDescription
            )
            return nil
        }
    }
}
