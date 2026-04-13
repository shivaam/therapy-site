import Foundation
import WatchConnectivity

/// Keeps iPhone and Apple Watch in sync. The phone is the source of truth for
/// presets/projects/routines; the watch receives snapshots and can send back
/// lightweight commands (start preset X, pause, stop, skip).
@MainActor
final class WatchSession: NSObject, ObservableObject {
    static let shared = WatchSession()

    private unowned var store: AppStore!
    private unowned var engine: TimerEngine!
    private var configured = false

    func configure(store: AppStore, engine: TimerEngine) {
        guard !configured else { return }
        self.store = store
        self.engine = engine
        configured = true
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    enum Command: String, Codable {
        case startPreset
        case startRoutine
        case pause
        case resume
        case stop
        case skip
        case requestState
    }

    struct Message: Codable {
        var command: Command
        var presetID: UUID?
        var routineID: UUID?
        var projectID: UUID?
    }

    /// Push current app + timer state to the counterpart device.
    func pushSnapshot() {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        let snap = Snapshot(
            presets: store.presets,
            activeProjects: store.activeProjects,
            routines: store.routines,
            timerState: store.timerState
        )
        guard let data = try? JSONEncoder().encode(snap) else { return }
        do {
            try WCSession.default.updateApplicationContext(["snapshot": data])
        } catch {
            // updateApplicationContext fails while unpaired / simulator; fall through silently.
        }
    }

    func send(_ message: Message) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(message) else { return }
        if session.isReachable {
            session.sendMessage(["cmd": data], replyHandler: nil, errorHandler: nil)
        } else {
            try? session.updateApplicationContext(["cmd": data])
        }
    }

    struct Snapshot: Codable {
        var presets: [Preset]
        var activeProjects: [Project]
        var routines: [Routine]
        var timerState: TimerState
    }

    // MARK: - Incoming
    fileprivate func handleIncoming(_ data: Data) {
        if let msg = try? JSONDecoder().decode(Message.self, from: data) {
            apply(msg)
        } else if let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            apply(snap)
        }
    }

    private func apply(_ msg: Message) {
        switch msg.command {
        case .startPreset:
            if let id = msg.presetID, let preset = store.presets.first(where: { $0.id == id }) {
                engine.startPreset(preset, projectID: msg.projectID)
            }
        case .startRoutine:
            if let id = msg.routineID, let r = store.routines.first(where: { $0.id == id }) {
                engine.startRoutine(r)
            }
        case .pause: engine.pause()
        case .resume: engine.resume()
        case .stop: engine.stop()
        case .skip: engine.skipStep()
        case .requestState: pushSnapshot()
        }
    }

    private func apply(_ snap: Snapshot) {
        // Watch side: replace local state with phone's snapshot.
        store.presets = snap.presets
        store.projects = snap.activeProjects
        store.routines = snap.routines
        store.timerState = snap.timerState
    }
}

extension WatchSession: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in self.pushSnapshot() }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message["cmd"] as? Data {
            Task { @MainActor in self.handleIncoming(data) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["snapshot"] as? Data {
            Task { @MainActor in self.handleIncoming(data) }
        } else if let data = applicationContext["cmd"] as? Data {
            Task { @MainActor in self.handleIncoming(data) }
        }
    }
}
