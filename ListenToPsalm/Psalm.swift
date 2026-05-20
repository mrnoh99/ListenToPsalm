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

// MARK: - Five books of the Psalter (Torah structure)

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

    /// Traditional theme for this book of the Psalter.
    var theme: String {
        switch self {
        case .one: return "다윗의 시편 (개인 탄원)"
        case .two: return "다윗/코라 자손 (공동체)"
        case .three: return "아삽/코라 자손 (성전 예배)"
        case .four: return "무명 시편 (하나님의 통치)"
        case .five: return "할렐루야 시편 (찬양)"
        }
    }

    var pickerLabel: String {
        "\(title) (\(subtitle))"
    }

    static func book(for number: Int) -> PsalmBook {
        allCases.first { $0.range.contains(number) } ?? .five
    }
}

// MARK: - Genre filters (content-based)

enum PsalmGenre: String, CaseIterable, Identifiable, Hashable, Sendable {
    case praise
    case personalLament
    case communityLament
    case personalThanksgiving
    case communityThanksgiving
    case royal
    case wisdom
    case pilgrimage
    case historical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .praise: return "찬양시"
        case .personalLament: return "탄원시 (개인)"
        case .communityLament: return "탄원시 (공동체)"
        case .personalThanksgiving: return "감사시 (개인)"
        case .communityThanksgiving: return "감사시 (공동체)"
        case .royal: return "왕시"
        case .wisdom: return "지혜시"
        case .pilgrimage: return "순례시"
        case .historical: return "역사시"
        }
    }

    var subtitle: String? {
        switch self {
        case .pilgrimage: return "120–134편 · 성전 올라가는 노래"
        case .praise: return "하나님 찬양"
        case .personalLament: return "개인의 고통과 호소"
        case .communityLament: return "민족·공동체의 탄원"
        case .personalThanksgiving: return "개인 구원에 대한 감사"
        case .communityThanksgiving: return "공동체 구원에 대한 감사"
        case .royal: return "메시아 왕 · 왕위"
        case .wisdom: return "교훈 · 경건한 삶"
        case .historical: return "구원 역사 회상"
        }
    }

    var pickerLabel: String {
        if let subtitle {
            return "\(title) · \(subtitle)"
        }
        return title
    }

    var psalmNumbers: [Int] {
        PsalmCatalog.numbers(for: self)
    }
}

// MARK: - Catholic liturgy filters

enum PsalmLiturgy: String, CaseIterable, Identifiable, Hashable, Sendable {
    case penitential
    case hallel
    case greatHallel
    case enthronement
    case messianic
    case zion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .penitential: return "7대 참회시편"
        case .hallel: return "할렐 시편"
        case .greatHallel: return "대할렐"
        case .enthronement: return "즉위 시편"
        case .messianic: return "메시아 시편"
        case .zion: return "시온 시편"
        }
    }

    var usage: String {
        switch self {
        case .penitential: return "재의 수요일 · 고해성사"
        case .hallel: return "부활 철야 · 유대 절기"
        case .greatHallel: return "감사 전례"
        case .enthronement: return "주일 전례"
        case .messianic: return "그리스도 예언"
        case .zion: return "교회·성전의 의미"
        }
    }

    var pickerLabel: String {
        "\(title) · \(usage)"
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
            return [8, 19, 29, 33, 100, 103, 104] + Array(145...150)
        case .personalLament:
            return [3, 5, 6, 13, 22, 38, 51, 130, 142]
        case .communityLament:
            return [12, 44, 60, 74, 79, 80, 83]
        case .personalThanksgiving:
            return [9, 18, 30, 32, 34, 40, 66, 116]
        case .communityThanksgiving:
            return [65, 67, 107, 124, 136]
        case .royal:
            return [2, 18, 20, 21, 45, 72, 89, 101, 110, 132]
        case .wisdom:
            return [1, 37, 49, 73, 112, 119, 127, 128, 133]
        case .pilgrimage:
            return Array(120...134)
        case .historical:
            return [78, 105, 106, 135, 136]
        }
    }

    static func numbers(for liturgy: PsalmLiturgy) -> [Int] {
        switch liturgy {
        case .penitential:
            return [6, 32, 38, 51, 102, 130, 143]
        case .hallel:
            return Array(113...118)
        case .greatHallel:
            return [136]
        case .enthronement:
            return [47, 93, 96, 97, 98, 99]
        case .messianic:
            return [2, 22, 45, 69, 72, 110, 118]
        case .zion:
            return [46, 48, 76, 84, 87, 122]
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
