import Foundation
import SwiftData

@Model
final class RailCompany {
    var name: String
    var callSign: String
    var railPassLevel: RailPassLevel
    var totalMiles: Double
    var totalTimeTravelled: Double
    
    init(name: String, callSign: String, railPassLevel: RailPassLevel, totalMiles: Double, totalTimeTravelled: Double) {
        self.name = name
        self.callSign = callSign
        self.railPassLevel = railPassLevel
        self.totalMiles = totalMiles
        self.totalTimeTravelled = totalTimeTravelled
    }
}

enum RailPassLevel: String, Codable {
    case bronze, silver, gold, platinum, titanium
}
