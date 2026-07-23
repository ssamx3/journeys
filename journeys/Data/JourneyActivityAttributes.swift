
import ActivityKit
import Foundation

struct JourneyActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {

        var progress: Double

        var elapsedSeconds: TimeInterval

        var targetDate: Date?
        var isPaused: Bool
        var isOverdriveActive: Bool
    }

    let companyName: String
    let originCode: String
    let destinationCode: String
    let isIndefinite: Bool

    let startDate: Date
}
