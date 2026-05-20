//
//  PlaybackPersistence.swift
//  ListenToPsalm
//

import Foundation

/// Last listened position saved across app launches.
enum PlaybackPersistence {
    struct SavedSession: Codable, Equatable {
        let psalmNumber: Int
        let elapsedSeconds: Double

        var psalm: Psalm? {
            PsalmCatalog.psalm(psalmNumber)
        }
    }

    private static let userDefaultsKey = "lastPlaybackSession"

    static func save(psalm: Psalm, elapsedSeconds: TimeInterval) {
        guard elapsedSeconds.isFinite, elapsedSeconds >= 0 else { return }

        let session = SavedSession(psalmNumber: psalm.number, elapsedSeconds: elapsedSeconds)
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    static func load() -> SavedSession? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let session = try? JSONDecoder().decode(SavedSession.self, from: data),
              session.psalm != nil else {
            return nil
        }
        return session
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

struct LaunchResumeOffer: Equatable {
    let psalm: Psalm
    let elapsedSeconds: TimeInterval

    var buttonTitle: String {
        "이어서 \(psalm.shortTitle) 재생"
    }

    var accessibilityLabel: String {
        "이어서 \(AccessibilitySupport.spokenPsalmTitle(for: psalm)) 재생할까요? \(AccessibilitySupport.spokenDuration(elapsedSeconds)) 위치에서 이어 듣기"
    }
}
