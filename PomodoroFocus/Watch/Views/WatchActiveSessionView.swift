import SwiftUI

struct WatchActiveSessionView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(Duration.clockString(store.timerState.remainingSeconds))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)

            HStack(spacing: 8) {
                Button {
                    WatchSession.shared.send(.init(command: .stop))
                } label: {
                    Image(systemName: "stop.fill")
                }
                .tint(.red)

                switch store.timerState.mode {
                case .running:
                    Button {
                        WatchSession.shared.send(.init(command: .pause))
                    } label: {
                        Image(systemName: "pause.fill")
                    }
                case .paused, .finished, .idle:
                    Button {
                        WatchSession.shared.send(.init(command: .resume))
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .tint(.accentColor)
                }

                Button {
                    WatchSession.shared.send(.init(command: .skip))
                } label: {
                    Image(systemName: "forward.fill")
                }
            }
            .buttonStyle(.bordered)

            if let routine = store.activeRoutine, !routine.tasks.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(routine.tasks) { t in
                            HStack {
                                Image(systemName: t.done ? "checkmark.circle.fill" : "circle")
                                Text(t.text).font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        if let routine = store.activeRoutine { return routine.name }
        if let id = store.timerState.presetID,
           let preset = store.presets.first(where: { $0.id == id }) {
            let step = preset.steps[safe: store.timerState.currentStepIndex]
            return "\(preset.name) · \(step?.kind.displayName ?? "")"
        }
        return "Focus"
    }

    private var progress: CGFloat {
        guard store.timerState.stepTotalSeconds > 0 else { return 0 }
        let done = store.timerState.stepTotalSeconds - store.timerState.remainingSeconds
        return CGFloat(done) / CGFloat(store.timerState.stepTotalSeconds)
    }
}
