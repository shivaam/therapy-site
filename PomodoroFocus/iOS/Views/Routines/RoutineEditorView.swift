import SwiftUI

struct RoutineEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State var routine: Routine
    @State private var newTaskText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $routine.name)
                    Picker("Kind", selection: $routine.kind) {
                        ForEach(Routine.Kind.allCases) { k in
                            Label(k.displayName, systemImage: k.systemImage).tag(k)
                        }
                    }
                }

                Section("Timer") {
                    Stepper(value: Binding(
                        get: { routine.totalSeconds / 60 },
                        set: { routine.totalSeconds = max(1, $0) * 60 }
                    ), in: 1...120) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(routine.totalSeconds / 60) min")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                Section("Checklist") {
                    ForEach($routine.tasks) { $task in
                        TextField("Task", text: $task.text)
                    }
                    .onDelete { routine.tasks.remove(atOffsets: $0) }
                    .onMove { routine.tasks.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        TextField("Add task", text: $newTaskText)
                        Button("Add") {
                            let t = newTaskText.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            routine.tasks.append(.init(text: t))
                            newTaskText = ""
                        }
                    }
                }
            }
            .navigationTitle(routine.name.isEmpty ? "Routine" : routine.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if store.routines.contains(where: { $0.id == routine.id }) {
                            store.updateRoutine(routine)
                        } else {
                            store.addRoutine(routine)
                        }
                        dismiss()
                    }
                    .disabled(routine.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
