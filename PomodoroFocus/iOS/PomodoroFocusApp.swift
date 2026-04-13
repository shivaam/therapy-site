import SwiftUI

@main
struct PomodoroFocusApp: App {
    @StateObject private var store: AppStore
    @StateObject private var engine: TimerEngine
    @StateObject private var audio = AmbientAudio()

    init() {
        let s = AppStore()
        let e = TimerEngine(store: s)
        _store = StateObject(wrappedValue: s)
        _engine = StateObject(wrappedValue: e)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(engine)
                .environmentObject(audio)
                .task {
                    audio.configureSession()
                    audio.apply(settings: store.settings)
                    WatchSession.shared.configure(store: store, engine: engine)
                    engine.setHandlers(
                        onStepTransition: { kind in
                            // Stop ambient audio on transitions away from focus;
                            // the onChange below starts it again when the next
                            // focus step begins.
                            if kind == .focus { audio.stop() }
                        },
                        onFinished: {
                            audio.stop()
                        }
                    )
                }
                .onChange(of: store.timerState) { _, state in
                    WatchSession.shared.pushSnapshot()
                    switch state.mode {
                    case .running:
                        let shouldPlay: Bool = {
                            if store.activeRoutine != nil { return true }
                            guard let preset = store.activePreset,
                                  preset.steps.indices.contains(state.currentStepIndex) else { return false }
                            return preset.steps[state.currentStepIndex].kind == .focus
                        }()
                        if shouldPlay {
                            audio.start(store.settings.ambientSound,
                                        volume: store.settings.ambientVolume)
                        } else {
                            audio.stop()
                        }
                    case .paused, .idle, .finished:
                        audio.stop()
                    }
                }
                .onChange(of: store.settings) { _, newSettings in
                    audio.apply(settings: newSettings)
                }
        }
    }
}
