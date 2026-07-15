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
    
    var pace: Double {
        switch self {
        case .bronze:    return 0.0167
        case .silver:    return 0.0180556
        case .gold:      return 0.0194444
        case .platinum:  return 0.0208333
        case .titanium:  return 0.0222222
        }
    }
}
