import Foundation
import SwiftData
import SwiftUI

@Model
final class RailCompany {
    var name: String
    var cardText: String
    var totalMiles: Double
    var totalTimeTravelled: Double


    var backgroundColorHex: String
    var blockColorHex: String
    var blockShapeRaw: String
    var blockPositionRaw: String
    var fontColorHex: String


    @Relationship(deleteRule: .cascade, inverse: \Journey.company)
    var journeys: [Journey]? = []

    init(
        name: String,
        cardText: String,
        totalMiles: Double = 0,
        totalTimeTravelled: Double = 0,
        backgroundColorHex: String = "007AFF",
        blockColorHex: String = "FF2D55",
        blockShapeRaw: String = "circle",
        blockPositionRaw: String = "bottom",
        fontColorHex: String = "FFFFFF"
    ) {
        self.name = name
        self.cardText = cardText
        self.totalMiles = totalMiles
        self.totalTimeTravelled = totalTimeTravelled
        self.backgroundColorHex = backgroundColorHex
        self.blockColorHex = blockColorHex
        self.blockShapeRaw = blockShapeRaw
        self.blockPositionRaw = blockPositionRaw
        self.fontColorHex = fontColorHex
    }

    var backgroundColor: Color {
        Color(hex: backgroundColorHex) ?? .blue
    }

    var blockColor: Color {
        Color(hex: blockColorHex) ?? .pink
    }

    var blockShape: CardBlockShape {
        CardBlockShape(rawValue: blockShapeRaw) ?? .circle
    }

    var blockPosition: CardBlockPosition {
        CardBlockPosition(rawValue: blockPositionRaw) ?? .bottom
    }
    
    var fontColor: Color {
        Color(hex: fontColorHex) ?? .white
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

enum CardBlockShape: String, Codable, CaseIterable {
    case circle = "circle"
    case square = "square"
}

enum CardBlockPosition: String, Codable, CaseIterable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "007AFF"
        }
        let r = Float(max(0, min(1, components[0])))
        let g = Float(max(0, min(1, components[1])))
        let b = Float(max(0, min(1, components[2])))
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

extension RailCompany {


    private static let tierThresholds: [(level: RailPassLevel, milesRequired: Double)] = [
        (.silver, 500), (.gold, 1000), (.platinum, 2000), (.titanium, 5000)
    ]

    private static let allTierFloors: [(level: RailPassLevel, floor: Double)] = [
        (.bronze, 0), (.silver, 500), (.gold, 1000), (.platinum, 2000), (.titanium, 5000)
    ]


    var level: RailPassLevel {
        RailCompany.allTierFloors.last(where: { totalMiles >= $0.floor })?.level ?? .bronze
    }

    var nextTier: RailPassLevel? {
        RailCompany.tierThresholds.first(where: { totalMiles < $0.milesRequired })?.level
    }

    var milesToNextTier: Double {
        guard let next = RailCompany.tierThresholds.first(where: { totalMiles < $0.milesRequired }) else { return 0 }
        return max(0, next.milesRequired - totalMiles)
    }

    private var currentTierFloor: Double {
        RailCompany.allTierFloors.last(where: { totalMiles >= $0.floor })?.floor ?? 0
    }

    var tierProgress: Double {
        guard let next = RailCompany.tierThresholds.first(where: { totalMiles < $0.milesRequired }) else { return 1 }
        let floor = currentTierFloor
        let range = next.milesRequired - floor
        guard range > 0 else { return 1 }
        return min(1, max(0, (totalMiles - floor) / range))
    }
}
