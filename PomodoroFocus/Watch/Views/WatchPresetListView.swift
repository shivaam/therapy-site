import SwiftUI

struct WatchPresetListView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        List {
            Section("Presets") {
                if store.presets.isEmpty {
                    Text("Open on iPhone to create a preset.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(store.presets) { preset in
                    NavigationLink {
                        WatchPresetDetailView(preset: preset)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(preset.name).font(.headline)
                            Text("\(preset.focusCount) focus · \(Duration.clockString(preset.totalDurationSeconds))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !store.routines.isEmpty {
                Section("Routines") {
                    ForEach(store.routines) { routine in
                        Button {
                            WatchSession.shared.send(.init(command: .startRoutine,
                                                           routineID: routine.id))
                        } label: {
                            HStack {
                                Image(systemName: routine.kind.systemImage)
                                Text(routine.name)
                                Spacer()
                                Text(Duration.clockString(routine.totalSeconds))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Focus")
    }
}

struct WatchPresetDetailView: View {
    @EnvironmentObject var store: AppStore
    let preset: Preset
    @State private var selectedProjectID: UUID?

    var body: some View {
        List {
            Section("Project") {
                Button {
                    selectedProjectID = nil
                } label: {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedProjectID == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                ForEach(store.activeProjects) { p in
                    Button {
                        selectedProjectID = p.id
                    } label: {
                        HStack {
                            Circle().fill(Color(hex: p.colorHex)).frame(width: 8, height: 8)
                            Text(p.name)
                            Spacer()
                            if selectedProjectID == p.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Section {
                Button {
                    WatchSession.shared.send(.init(command: .startPreset,
                                                   presetID: preset.id,
                                                   projectID: selectedProjectID))
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .tint(.accentColor)
            }
        }
        .navigationTitle(preset.name)
    }
}
