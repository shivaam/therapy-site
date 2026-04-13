import SwiftUI

@main
struct PomodoroFocusWatchApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var engine: TimerEngine

    init() {
        let s = AppStore()
        let e = TimerEngine(store: s)
        _store = StateObject(wrappedValue: s)
        _engine = StateObject(wrappedValue: e)
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(store)
                .environmentObject(engine)
                .task {
                    WatchSession.shared.configure(store: store, engine: engine)
                    // Ask the phone for the latest presets + timer state.
                    WatchSession.shared.send(.init(command: .requestState))
                }
        }
    }
}
