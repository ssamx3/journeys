//
//  CurrentStationStore.swift
//  journeys
//

import Observation
import Foundation

@Observable
final class CurrentStationStore {
    private let defaultsKey = "currentStationName"
    private let defaultStationName = "Folsense"

    private(set) var currentPlaceName: String

    init() {
        let stored = UserDefaults.standard.string(forKey: defaultsKey)
        self.currentPlaceName = stored ?? "Folsense"
    }

    var currentPlace: Place {
        PlaceNames.byName[currentPlaceName] ?? Place(name: defaultStationName, code: "FOL")
    }

    func arrive(at placeName: String) {
        guard !placeName.isEmpty else { return }
        currentPlaceName = placeName
        UserDefaults.standard.set(placeName, forKey: defaultsKey)
    }
}
