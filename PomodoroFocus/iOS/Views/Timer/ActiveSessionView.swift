import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var audio: AmbientAudio
    @State private var showingCapture = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                ringTimer
                controls
                if store.activeRoutine != nil {
                    RoutineChecklistView()
                } else {
                    SessionTasksView()
                }
                if let preset = store.activePreset {
                    StepListView(preset: preset, currentIndex: store.timerState.currentStepIndex)
                }
            }
            .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            // Always-there brain-dump button so a random thought never has an
            // excuse to turn into a distraction.
            Button {
                showingCapture = true
            } label: {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .padding(16)
                    .background(Color.accentColor, in: Circle())
                    .foregroundStyle(.white)
                    .shadow(radius: 6, y: 2)
            }
            .padding()
            .accessibilityLabel("Brain dump")
        }
        .sheet(isPresented: $showingCapture) {
            QuickCaptureSheet()
                .presentationDetents([.medium, .large])
        }
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
                HStack(spacing: 4) {
                    Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    Text(audio.isMuted ? "Muted" : store.settings.ambientSound.displayName)
                }
                .font(.caption2)
                .foregroundStyle(audio.isMuted ? Color.red : .secondary)
                .padding(.top, 2)
            }
        }
        .frame(width: 260, height: 260)
        .contentShape(Circle())
        // Single tap anywhere on the timer toggles ambient sound.
        .onTapGesture { audio.toggleMuted() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(audio.isMuted ? "Unmute ambient sound" : "Mute ambient sound")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let routine = store.activeRoutine {
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
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func toggle(_ task: RoutineTask) {
        guard var r = store.activeRoutine,
              let idx = r.tasks.firstIndex(of: task) else { return }
        r.tasks[idx].done.toggle()
        store.updateRoutine(r)
        store.activeRoutine = r
    }
}

/// Ad-hoc checklist that sits under the ring for preset-based sessions.
/// Lets the user jot down what they're going to work on and tick items off
/// without leaving the timer screen.
private struct SessionTasksView: View {
    @EnvironmentObject var store: AppStore
    @State private var newTaskText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tasks").font(.headline)

            ForEach(store.sessionTasks) { task in
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
                        Button(role: .destructive) {
                            store.sessionTasks.removeAll { $0.id == task.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .buttonStyle(.plain)
            }

            HStack {
                TextField("Add a task", text: $newTaskText)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit(addTask)
                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(newTaskText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if store.sessionTasks.isEmpty {
                Text("Jot down what you'll work on — tasks are cleared when the session ends.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func addTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.sessionTasks.append(.init(text: trimmed))
        newTaskText = ""
    }

    private func toggle(_ task: RoutineTask) {
        guard let idx = store.sessionTasks.firstIndex(of: task) else { return }
        store.sessionTasks[idx].done.toggle()
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
