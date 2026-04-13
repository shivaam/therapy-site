import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// Drives the Pomodoro clock. Uses an absolute end-time so the timer stays
/// accurate across backgrounding, then broadcasts state changes through the
/// AppStore (and onward to the Watch via WatchSession).
@MainActor
final class TimerEngine: ObservableObject {
    private unowned let store: AppStore
    private var ticker: Timer?
    private var onStepTransition: ((SessionStep.Kind) -> Void)?
    private var onFinished: (() -> Void)?

    init(store: AppStore) {
        self.store = store
    }

    var state: TimerState { store.timerState }

    func setHandlers(onStepTransition: ((SessionStep.Kind) -> Void)? = nil,
                     onFinished: (() -> Void)? = nil) {
        self.onStepTransition = onStepTransition
        self.onFinished = onFinished
    }

    // MARK: - Public control

    func startPreset(_ preset: Preset, projectID: UUID? = nil) {
        guard let firstStep = preset.steps.first else { return }
        store.activePreset = preset
        store.activeRoutine = nil
        store.sessionTasks = []
        let total = firstStep.durationSeconds
        store.timerState = TimerState(
            mode: .running,
            presetID: preset.id,
            projectID: projectID,
            routineID: nil,
            currentStepIndex: 0,
            stepEndsAt: Date().addingTimeInterval(TimeInterval(total)),
            remainingSeconds: total,
            stepTotalSeconds: total
        )
        tickNow()
        startTicking()
    }

    func startRoutine(_ routine: Routine) {
        store.activeRoutine = routine
        store.activePreset = nil
        store.sessionTasks = []
        let total = routine.totalSeconds
        store.timerState = TimerState(
            mode: .running,
            presetID: nil,
            projectID: nil,
            routineID: routine.id,
            currentStepIndex: 0,
            stepEndsAt: Date().addingTimeInterval(TimeInterval(total)),
            remainingSeconds: total,
            stepTotalSeconds: total
        )
        tickNow()
        startTicking()
    }

    func pause() {
        guard store.timerState.mode == .running else { return }
        var s = store.timerState
        if let ends = s.stepEndsAt {
            s.remainingSeconds = max(0, Int(ends.timeIntervalSinceNow.rounded()))
        }
        s.mode = .paused
        s.stepEndsAt = nil
        store.timerState = s
        stopTicking()
    }

    func resume() {
        guard store.timerState.mode == .paused else { return }
        var s = store.timerState
        s.stepEndsAt = Date().addingTimeInterval(TimeInterval(s.remainingSeconds))
        s.mode = .running
        store.timerState = s
        startTicking()
    }

    func stop() {
        stopTicking()
        store.timerState = .idle
        store.activePreset = nil
        store.activeRoutine = nil
        store.sessionTasks = []
    }

    func skipStep() {
        advanceStep(force: true)
    }

    // MARK: - Ticking

    private func startTicking() {
        stopTicking()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickNow() }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func stopTicking() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tickNow() {
        guard store.timerState.mode == .running,
              let ends = store.timerState.stepEndsAt else { return }
        let remaining = Int(ends.timeIntervalSinceNow.rounded())
        if remaining <= 0 {
            advanceStep(force: false)
        } else {
            var s = store.timerState
            s.remainingSeconds = remaining
            store.timerState = s
        }
    }

    private func advanceStep(force: Bool) {
        // Routines are single-step — finishing ends them.
        if let routine = store.activeRoutine {
            finishRun(lastKind: nil)
            _ = routine
            return
        }
        guard let preset = store.activePreset else {
            finishRun(lastKind: nil)
            return
        }

        let nextIndex = store.timerState.currentStepIndex + 1
        if nextIndex >= preset.steps.count {
            if preset.loop {
                startStep(at: 0, in: preset)
            } else {
                let finishedKind = preset.steps[store.timerState.currentStepIndex].kind
                finishRun(lastKind: finishedKind)
            }
            return
        }

        let finishedKind = preset.steps[store.timerState.currentStepIndex].kind
        let nextStep = preset.steps[nextIndex]

        // Respect auto-start preferences unless the user pressed skip.
        let shouldAutoStart: Bool = {
            if force { return true }
            switch nextStep.kind {
            case .focus:
                return store.settings.autoStartFocus
            case .shortBreak, .longBreak:
                return store.settings.autoStartBreaks
            }
        }()

        if shouldAutoStart {
            startStep(at: nextIndex, in: preset)
        } else {
            var s = store.timerState
            s.currentStepIndex = nextIndex
            s.mode = .paused
            s.remainingSeconds = nextStep.durationSeconds
            s.stepTotalSeconds = nextStep.durationSeconds
            s.stepEndsAt = nil
            store.timerState = s
            stopTicking()
        }

        onStepTransition?(finishedKind)
    }

    private func startStep(at index: Int, in preset: Preset) {
        let step = preset.steps[index]
        var s = store.timerState
        s.currentStepIndex = index
        s.mode = .running
        s.stepTotalSeconds = step.durationSeconds
        s.remainingSeconds = step.durationSeconds
        s.stepEndsAt = Date().addingTimeInterval(TimeInterval(step.durationSeconds))
        store.timerState = s
    }

    private func finishRun(lastKind: SessionStep.Kind?) {
        stopTicking()
        var s = store.timerState
        s.mode = .finished
        s.remainingSeconds = 0
        s.stepEndsAt = nil
        store.timerState = s
        if let lastKind { onStepTransition?(lastKind) }
        onFinished?()
    }
}
