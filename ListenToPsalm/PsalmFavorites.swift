//
//  PsalmFavorites.swift
//  ListenToPsalm
//

import Foundation

enum PsalmFavorites {
    private static let key = "favoritePsalmNumbers"

    static func load() -> Set<Int> {
        let array = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        return Set(array.filter { (1...PsalmCatalog.totalCount).contains($0) })
    }

    static func save(_ numbers: Set<Int>) {
        let sorted = numbers.filter { (1...PsalmCatalog.totalCount).contains($0) }.sorted()
        UserDefaults.standard.set(sorted, forKey: key)
    }

    static func toggle(_ number: Int) -> Set<Int> {
        var set = load()
        if set.contains(number) {
            set.remove(number)
        } else {
            set.insert(number)
        }
        save(set)
        return set
    }
}
