import SwiftUI

struct PresetEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State var preset: Preset
    @State private var isNew: Bool

    init(preset: Preset) {
        _preset = State(initialValue: preset)
        _isNew = State(initialValue: !Preset.defaults.contains(where: { $0.id == preset.id })
                       && preset.createdAt.timeIntervalSinceNow > -1)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $preset.name)
                }

                Section {
                    ForEach($preset.steps) { $step in
                        StepEditorRow(step: $step)
                    }
                    .onDelete { preset.steps.remove(atOffsets: $0) }
                    .onMove { preset.steps.move(fromOffsets: $0, toOffset: $1) }
                } header: {
                    Text("Steps (\(preset.steps.count))")
                } footer: {
                    Text("Each focus block can have its own length. Tap a step to change its type and duration.")
                }

                Section {
                    Button {
                        preset.steps.append(.init(kind: .focus, durationSeconds: 25 * 60))
                    } label: {
                        Label("Add focus", systemImage: "plus.circle")
                    }
                    Button {
                        preset.steps.append(.init(kind: .shortBreak, durationSeconds: 5 * 60))
                    } label: {
                        Label("Add break", systemImage: "plus.circle")
                    }
                    Button {
                        preset.steps.append(.init(kind: .longBreak, durationSeconds: 15 * 60))
                    } label: {
                        Label("Add long break", systemImage: "plus.circle")
                    }
                }

                Section {
                    Toggle("Loop forever", isOn: $preset.loop)
                }
            }
            .navigationTitle(isNew ? "New Preset" : "Edit Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if store.presets.contains(where: { $0.id == preset.id }) {
                            store.updatePreset(preset)
                        } else {
                            store.addPreset(preset)
                        }
                        dismiss()
                    }
                    .disabled(preset.name.trimmingCharacters(in: .whitespaces).isEmpty || preset.steps.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
            }
        }
    }
}

private struct StepEditorRow: View {
    @Binding var step: SessionStep

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Type", selection: $step.kind) {
                ForEach(SessionStep.Kind.allCases) { k in
                    Text(k.displayName).tag(k)
                }
            }
            .pickerStyle(.segmented)

            Stepper(value: Binding(
                get: { step.durationMinutes },
                set: { step.durationMinutes = max(1, $0) }
            ), in: 1...180) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(step.durationMinutes) min")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 4)
    }
}
