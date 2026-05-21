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
        var browseModeRaw: String?
        var bookRaw: Int?
        var genreRaw: String?
        var liturgyRaw: String?

        var psalm: Psalm? {
            PsalmCatalog.psalm(psalmNumber)
        }

        var browseMode: BrowseMode? {
            browseModeRaw.flatMap(BrowseMode.init(rawValue:))
        }

        var book: PsalmBook? {
            bookRaw.flatMap(PsalmBook.init(rawValue:))
        }

        var genre: PsalmGenre? {
            genreRaw.flatMap(PsalmGenre.init(rawValue:))
        }

        var liturgy: PsalmLiturgy? {
            liturgyRaw.flatMap(PsalmLiturgy.init(rawValue:))
        }
    }

    private static let userDefaultsKey = "lastPlaybackSession"

    static func save(
        psalm: Psalm,
        elapsedSeconds: TimeInterval,
        browseModeRaw: String? = nil,
        bookRaw: Int? = nil,
        genreRaw: String? = nil,
        liturgyRaw: String? = nil
    ) {
        guard elapsedSeconds.isFinite, elapsedSeconds >= 0 else { return }

        let session = SavedSession(
            psalmNumber: psalm.number,
            elapsedSeconds: elapsedSeconds,
            browseModeRaw: browseModeRaw,
            bookRaw: bookRaw,
            genreRaw: genreRaw,
            liturgyRaw: liturgyRaw
        )
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
