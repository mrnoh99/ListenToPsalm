//
//  Psalm.swift
//  ListenToPsalm
//

import Foundation

// MARK: - Browse modes (2×3 hub)

enum BrowseMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case byBook
    case byGenre
    case byLiturgy
    case favorites

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .all: return "전체"
        case .byBook: return "권별"
        case .byGenre: return "장르"
        case .byLiturgy: return "전례"
        case .favorites: return "즐겨찾기"
        }
    }

    var accessibilitySuffix: String { rawValue }
}

// MARK: - Five books of the Psalter

enum PsalmBook: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case one = 1
    case two
    case three
    case four
    case five

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .one: return "제1권"
        case .two: return "제2권"
        case .three: return "제3권"
        case .four: return "제4권"
        case .five: return "제5권"
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .one: return 1...41
        case .two: return 42...72
        case .three: return 73...89
        case .four: return 90...106
        case .five: return 107...150
        }
    }

    var subtitle: String {
        "\(range.lowerBound)–\(range.upperBound)편"
    }

    static func book(for number: Int) -> PsalmBook {
        allCases.first { $0.range.contains(number) } ?? .five
    }
}

// MARK: - Genre & liturgy filters

enum PsalmGenre: String, CaseIterable, Identifiable, Hashable, Sendable {
    case praise
    case lament
    case thanksgiving
    case pilgrimage
    case wisdom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .praise: return "찬양시"
        case .lament: return "탄원시"
        case .thanksgiving: return "감사시"
        case .pilgrimage: return "순례시"
        case .wisdom: return "지혜시"
        }
    }

    var subtitle: String? {
        switch self {
        case .pilgrimage: return "120–134편"
        default: return nil
        }
    }

    var psalmNumbers: [Int] {
        PsalmCatalog.numbers(for: self)
    }
}

enum PsalmLiturgy: String, CaseIterable, Identifiable, Hashable, Sendable {
    case penitential
    case hallel
    case messianic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .penitential: return "7대 참회시편"
        case .hallel: return "할렐 시편"
        case .messianic: return "메시아 시편"
        }
    }

    var psalmNumbers: [Int] {
        PsalmCatalog.numbers(for: self)
    }
}

// MARK: - Psalm catalog

enum PsalmCatalog {
    static let totalCount = 150

    static func psalm(_ number: Int) -> Psalm? {
        guard (1...totalCount).contains(number) else { return nil }
        return Psalm(number: number)
    }

    static var allPsalms: [Psalm] {
        (1...totalCount).map { Psalm(number: $0) }
    }

    static func psalms(
        browseMode: BrowseMode,
        book: PsalmBook,
        genre: PsalmGenre?,
        liturgy: PsalmLiturgy?,
        favorites: Set<Int>
    ) -> [Psalm] {
        let numbers: [Int]
        switch browseMode {
        case .all:
            numbers = Array(1...totalCount)
        case .byBook:
            numbers = Array(book.range)
        case .byGenre:
            numbers = genre?.psalmNumbers ?? []
        case .byLiturgy:
            numbers = liturgy?.psalmNumbers ?? []
        case .favorites:
            numbers = favorites.sorted()
        }
        return numbers.compactMap { psalm($0) }
    }

    static func numbers(for genre: PsalmGenre) -> [Int] {
        switch genre {
        case .praise:
            return [8, 19, 29, 33, 100, 103, 104, 111, 113, 117, 145, 146, 147, 148, 149, 150]
        case .lament:
            return [3, 4, 5, 6, 13, 22, 25, 28, 31, 38, 39, 42, 43, 51, 54, 55, 56, 57, 59, 60, 61, 64, 70, 71, 77, 86, 90, 141, 142, 143]
        case .thanksgiving:
            return [18, 30, 32, 34, 40, 66, 92, 116, 118, 124, 129, 138]
        case .pilgrimage:
            return Array(120...134)
        case .wisdom:
            return [1, 14, 19, 37, 49, 73, 78, 90, 91, 92, 94, 111, 112, 127, 128, 133, 139]
        }
    }

    static func numbers(for liturgy: PsalmLiturgy) -> [Int] {
        switch liturgy {
        case .penitential:
            return [6, 32, 38, 51, 102, 130, 143]
        case .hallel:
            return Array(113...118)
        case .messianic:
            return [2, 16, 22, 23, 24, 69, 110, 118]
        }
    }

    static func playbackOrder(in psalms: [Psalm], startingAt selected: Psalm) -> [Psalm] {
        guard !psalms.isEmpty else { return [] }
        guard let index = psalms.firstIndex(of: selected) else {
            return psalms
        }
        return Array(psalms[index...]) + Array(psalms[..<index])
    }
}

struct Psalm: Identifiable, Hashable, Sendable {
    let number: Int

    var id: Int { number }

    var book: PsalmBook { PsalmBook.book(for: number) }

    var title: String { "시편 \(number)편" }

    var shortTitle: String { "시편 \(number)편" }

    var resourceName: String { "시편 \(String(format: "%03d", number))편" }

    var resourceSubdirectory: String { "AudioFiles" }

    var resourceDisplayPath: String { "\(resourceSubdirectory)/\(resourceName).m4a" }

    var accessibilitySuffix: String { "psalm-\(number)" }
}
