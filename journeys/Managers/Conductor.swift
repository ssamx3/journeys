import Observation
import Foundation

@Observable
final class Conductor {
    private(set) var company: RailCompany?
    private(set) var startTime: Date?
    private(set) var startPlace: String?
    private(set) var targetPlace: String?
    private(set) var targetDuration: TimeInterval?
    private(set) var isEndless: Bool = false
    private(set) var finishAtNextStop: Bool = false
    
    private var now: Date = .now
    private var tickTask: Task<Void, Never>?
    
    var elapsedSeconds: TimeInterval{guard let startTime else { return 0 }
        return now.timeIntervalSince(startTime)}
    var isOverdriveActive: Bool {return elapsedSeconds >= 1800 && isEndless && finishAtNextStop}
    var currentMultiplier: Double {return (isOverdriveActive) ? 1.5:1}
    var milesSoFar: Double { return elapsedSeconds * 0.0166666667 * currentMultiplier}
    
}
