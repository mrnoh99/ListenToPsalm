//
//  PsalmEntity.swift
//  ListenToPsalm
//

import AppIntents
import Foundation

struct PsalmEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "시편")

    static var defaultQuery = PsalmEntityQuery()

    var id: String { "\(number)" }

    var number: Int

    init(number: Int) {
        self.number = number
    }

    var displayRepresentation: DisplayRepresentation {
        guard let psalm = PsalmCatalog.psalm(number) else {
            return DisplayRepresentation(title: "\(number)편")
        }
        return DisplayRepresentation(title: "\(psalm.title)")
    }
}

struct PsalmEntityQuery: EntityQuery {
    func entities(for identifiers: [PsalmEntity.ID]) -> [PsalmEntity] {
        identifiers.compactMap { id in
            guard let number = Int(id),
                  PsalmCatalog.psalm(number) != nil else { return nil }
            return PsalmEntity(number: number)
        }
    }

    func suggestedEntities() -> [PsalmEntity] {
        [23, 51, 91, 121, 130].map { PsalmEntity(number: $0) }
    }

    func defaultResult() async -> PsalmEntity? {
        PsalmEntity(number: 23)
    }
}
