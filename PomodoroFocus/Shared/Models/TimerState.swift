import Foundation

/// Snapshot of what the timer engine is doing right now. The same value is
/// shared between iPhone and Apple Watch over WatchConnectivity so either side
/// can render and control the session.
struct TimerState: Codable, Hashable {
    enum Mode: String, Codable {
        case idle
        case running
        case paused
        case finished
    }

    var mode: Mode
    var presetID: UUID?
    var projectID: UUID?
    var routineID: UUID?
    var currentStepIndex: Int
    /// Epoch seconds when the current step would finish assuming no pauses.
    /// nil when paused or idle.
    var stepEndsAt: Date?
    /// Remaining seconds on the current step (used while paused).
    var remainingSeconds: Int
    /// Seconds originally configured for the step — used to draw progress.
    var stepTotalSeconds: Int

    static let idle = TimerState(
        mode: .idle,
        presetID: nil,
        projectID: nil,
        routineID: nil,
        currentStepIndex: 0,
        stepEndsAt: nil,
        remainingSeconds: 0,
        stepTotalSeconds: 0
    )
}
