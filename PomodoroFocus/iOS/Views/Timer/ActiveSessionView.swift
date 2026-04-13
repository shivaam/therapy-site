import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        VStack(spacing: 24) {
            header
            ringTimer
            controls
            if let routine = store.activeRoutine {
                RoutineChecklistView(routine: routine)
            } else if let preset = store.activePreset {
                StepListView(preset: preset, currentIndex: store.timerState.currentStepIndex)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(titleLine).font(.headline)
            if let project = currentProject {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: project.colorHex)).frame(width: 8, height: 8)
                    Text(project.name).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var titleLine: String {
        if let routine = store.activeRoutine { return routine.name }
        guard let preset = store.activePreset else { return "Focus" }
        let step = preset.steps[safe: store.timerState.currentStepIndex]
        return "\(preset.name) · \(step?.kind.displayName ?? "Focus")"
    }

    private var currentProject: Project? {
        guard let id = store.timerState.projectID else { return nil }
        return store.projects.first { $0.id == id }
    }

    private var ringTimer: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
            VStack(spacing: 4) {
                Text(Duration.clockString(store.timerState.remainingSeconds))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(modeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 260, height: 260)
    }

    private var progress: CGFloat {
        guard store.timerState.stepTotalSeconds > 0 else { return 0 }
        let done = store.timerState.stepTotalSeconds - store.timerState.remainingSeconds
        return CGFloat(done) / CGFloat(store.timerState.stepTotalSeconds)
    }

    private var modeLabel: String {
        switch store.timerState.mode {
        case .running: return "Running"
        case .paused: return "Paused"
        case .idle: return "Ready"
        case .finished: return "Finished"
        }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button(role: .destructive) { engine.stop() } label: {
                Label("Stop", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)

            switch store.timerState.mode {
            case .running:
                Button { engine.pause() } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            case .paused, .finished, .idle:
                Button { engine.resume() } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.timerState.mode == .finished)
            }

            Button { engine.skipStep() } label: {
                Label("Skip", systemImage: "forward.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct StepListView: View {
    let preset: Preset
    let currentIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Queue").font(.caption).foregroundStyle(.secondary)
            ForEach(Array(preset.steps.enumerated()), id: \.element.id) { idx, step in
                HStack {
                    Image(systemName: idx < currentIndex
                          ? "checkmark.circle.fill"
                          : (idx == currentIndex ? "play.circle.fill" : "circle"))
                        .foregroundStyle(idx == currentIndex ? Color.accentColor : .secondary)
                    Text(step.kind.displayName)
                    Spacer()
                    Text(Duration.clockString(step.durationSeconds))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RoutineChecklistView: View {
    @EnvironmentObject var store: AppStore
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(routine.name).font(.headline)
            ForEach(routine.tasks) { task in
                Button {
                    toggle(task)
                } label: {
                    HStack {
                        Image(systemName: task.done ? "checkmark.square.fill" : "square")
                            .foregroundStyle(task.done ? Color.accentColor : .secondary)
                        Text(task.text)
                            .strikethrough(task.done)
                            .foregroundStyle(task.done ? .secondary : .primary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func toggle(_ task: RoutineTask) {
        var r = routine
        guard let idx = r.tasks.firstIndex(of: task) else { return }
        r.tasks[idx].done.toggle()
        store.updateRoutine(r)
        store.activeRoutine = r
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
