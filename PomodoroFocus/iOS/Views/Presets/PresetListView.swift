import SwiftUI

struct PresetListView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing: Preset?
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.presets) { preset in
                    Button {
                        editing = preset
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(preset.name).font(.headline)
                                Spacer()
                                Text(Duration.clockString(preset.totalDurationSeconds))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            PresetSummaryRow(preset: preset)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { idx in
                    idx.map { store.presets[$0] }.forEach(store.deletePreset)
                }
            }
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) {
                PresetEditorView(preset: Preset(name: "New preset",
                                                steps: [.init(kind: .focus, durationSeconds: 25 * 60),
                                                        .init(kind: .shortBreak, durationSeconds: 5 * 60)]))
            }
            .sheet(item: $editing) { preset in
                PresetEditorView(preset: preset)
            }
        }
    }
}
