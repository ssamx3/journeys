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
    private(set) var overdriveStartSeconds: TimeInterval?
    private(set) var isPaused: Bool = false

    private var now: Date = .now
    private var tickTask: Task<Void, Never>?
    private var pauseStartedAt: Date?
    private var pausedAccumulated: TimeInterval = 0

    var elapsedSeconds: TimeInterval{
        guard let startTime else { return 0 }
        let referenceNow = isPaused ? (pauseStartedAt ?? now) : now
        return referenceNow.timeIntervalSince(startTime) - pausedAccumulated}
    
    var isOverdriveActive: Bool {
        return finishAtNextStop}
    
    var currentMultiplier: Double {
        return (isOverdriveActive) ? 1.5:1}
    
    var milesSoFar: Double {
        if isOverdriveActive, let overdriveStart = overdriveStartSeconds {
            let baseMiles = overdriveStart * pace
            let overdriveSeconds = elapsedSeconds - overdriveStart
            let overdriveMiles = overdriveSeconds * pace * 1.5
            return baseMiles + overdriveMiles
        } else {
            return elapsedSeconds * pace
        }
    }
    
    var pace: Double {
        return company?.level.pace ?? 0.0166667}
    
    var progress: Double {
        guard let targetDuration else { return 0 }
        return min(elapsedSeconds / targetDuration, 1)}
    
    
    var shouldAutoDisembark: Bool {
           guard startTime != nil else { return false }
    
           if !isEndless {
               guard let targetDuration else { return false }
               return elapsedSeconds >= targetDuration
           }
           guard finishAtNextStop else { return false }
           let seconds = Int(elapsedSeconds)
           return seconds > 0 && seconds % 600 == 0
       }
    
    func begin(company: RailCompany, startPlace: String, targetPlace: String?, duration: TimeInterval?, endless: Bool){
        self.company = company
        self.startPlace = startPlace
        self.targetPlace = targetPlace
        self.targetDuration = duration
        self.isEndless = endless
        self.startTime = .now
        self.finishAtNextStop = false
        self.isPaused = false
        self.pauseStartedAt = nil
        self.pausedAccumulated = 0
        
        self.now = .now
        
        startTicking()
        
    }
    
    /// Pauses elapsed-time accumulation. Intended for indefinite journeys
    /// only — the countdown-mode auto-disembark check keeps evaluating
    /// against wall-clock progress, so pausing there would just delay a
    /// finish the person already committed to.
    func pause() {
        guard startTime != nil, !isPaused else { return }
        isPaused = true
        pauseStartedAt = .now
    }
    
    func resume() {
        guard let pauseStartedAt else { return }
        pausedAccumulated += Date.now.timeIntervalSince(pauseStartedAt)
        self.pauseStartedAt = nil
        isPaused = false
    }
    
    func disembarkAtNextStop() {
        guard isEndless, elapsedSeconds >= 1800 else { return }
        finishAtNextStop = true
        overdriveStartSeconds = elapsedSeconds
        }
    
    func disembark() -> JourneyResult {
        let result = JourneyResult(
            company: company!,
            miles: milesSoFar,
            startTime: startTime!,
            endTime: now,
            startPlace: startPlace ?? "",
            endPlace: targetPlace ?? ""
        )
        
        stopTicking()
        
        company = nil
        startTime = nil
        startPlace = nil
        targetPlace = nil
        targetDuration = nil
        isEndless = false
        finishAtNextStop = false
        isPaused = false
        pauseStartedAt = nil
        pausedAccumulated = 0
       
        
        return result
    }
    
    
    func cancel() {
            
            stopTicking()
     
            company = nil
            startTime = nil
            startPlace = nil
            targetPlace = nil
            targetDuration = nil
            isEndless = false
            finishAtNextStop = false
            isPaused = false
            pauseStartedAt = nil
            pausedAccumulated = 0
        }
    
    
    
    private func startTicking() {
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self.now = .now

            }
        }
    }
    
    private func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }
    
}
