import Foundation
import SwiftData

@Model
final class RailCompany {
    var name: String
    var callSign: String
    var totalMiles: Double
    var totalTimeTravelled: Double
    var level: RailPassLevel
    
    init(name: String, callSign: String, totalMiles: Double, totalTimeTravelled: Double, level: RailPassLevel) {
        self.name = name
        self.callSign = callSign
        self.totalMiles = totalMiles
        self.totalTimeTravelled = totalTimeTravelled
        self.level = level
    }
    
}

enum RailPassLevel: String, Codable {
    case bronze, silver, gold, platinum, titanium
}
