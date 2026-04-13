import SwiftUI

struct TimerHomeView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var engine: TimerEngine

    @State private var selectedPresetID: UUID?
    @State private var selectedProjectID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if store.timerState.mode != .idle {
                    ActiveSessionView()
                } else {
                    startForm
                }
            }
            .navigationTitle("Focus")
        }
        .onAppear {
            if selectedPresetID == nil { selectedPresetID = store.presets.first?.id }
        }
    }

    private var startForm: some View {
        Form {
            Section("Preset") {
                if store.presets.isEmpty {
                    Text("Create a preset in the Presets tab to get started.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Preset", selection: Binding(
                        get: { selectedPresetID ?? store.presets.first?.id ?? UUID() },
                        set: { selectedPresetID = $0 }
                    )) {
                        ForEach(store.presets) { preset in
                            Text(preset.name).tag(preset.id)
                        }
                    }
                    if let preset = currentPreset {
                        PresetSummaryRow(preset: preset)
                    }
                }
            }

            Section("Project") {
                if store.activeProjects.isEmpty {
                    Text("Add up to \(Project.maxActive) active projects in the Projects tab.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Project", selection: Binding(
                        get: { selectedProjectID ?? store.activeProjects.first?.id },
                        set: { selectedProjectID = $0 }
                    )) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.activeProjects) { p in
                            Text(p.name).tag(Optional(p.id))
                        }
                    }
                }
            }

            Section {
                Button {
                    guard let preset = currentPreset else { return }
                    engine.startPreset(preset, projectID: selectedProjectID)
                } label: {
                    Label("Start focus session", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentPreset == nil)
            }
        }
    }

    private var currentPreset: Preset? {
        if let id = selectedPresetID {
            return store.presets.first(where: { $0.id == id })
        }
        return store.presets.first
    }
}

struct PresetSummaryRow: View {
    let preset: Preset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(preset.focusCount) focus blocks · \(Duration.clockString(preset.totalDurationSeconds)) total")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                ForEach(preset.steps) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: step.kind))
                        .frame(width: max(8, CGFloat(step.durationSeconds) / 60),
                               height: 10)
                }
            }
        }
    }

    private func color(for kind: SessionStep.Kind) -> Color {
        switch kind {
        case .focus: return .accentColor
        case .shortBreak: return .green.opacity(0.6)
        case .longBreak: return .blue.opacity(0.6)
        }
    }
}
