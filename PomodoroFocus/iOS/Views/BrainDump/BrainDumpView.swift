import SwiftUI

/// Always-one-tap-away capture surface for ADHD brains.
/// - Scratchpad: append-only stream of thoughts.
/// - Parking Lot: distractions to come back to later.
struct BrainDumpView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case scratchpad, parkingLot
        var id: String { rawValue }
        var title: String {
            switch self {
            case .scratchpad: return "Scratchpad"
            case .parkingLot: return "Parking Lot"
            }
        }
    }

    @EnvironmentObject var store: AppStore
    @State private var tab: Tab = .scratchpad

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { t in
                        Text(t.title).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch tab {
                case .scratchpad:
                    ScratchpadPane()
                case .parkingLot:
                    ParkingLotPane()
                }
            }
            .navigationTitle("Brain Dump")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Scratchpad

private struct ScratchpadPane: View {
    @EnvironmentObject var store: AppStore
    @State private var draft: String = ""
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            composer
            Divider()
            if store.scratchpad.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.scratchpad) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.text).font(.body)
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        offsets.map { store.scratchpad[$0] }
                               .forEach(store.deleteScratchpad)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Dump a thought…",
                      text: $draft,
                      axis: .vertical)
                .lineLimit(1...5)
                .focused($composerFocused)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button {
                    store.appendScratchpad(draft)
                    draft = ""
                } label: {
                    Label("Save note", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Nothing here yet.")
                .font(.headline)
            Text("Write whatever pops into your head — it's safe here, not in the way of focus.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Parking Lot

private struct ParkingLotPane: View {
    @EnvironmentObject var store: AppStore
    @State private var draft: String = ""
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            composer
            Divider()
            if store.parkingLot.isEmpty {
                emptyState
            } else {
                List {
                    Section {
                        ForEach(openItems) { item in
                            row(item)
                        }
                        .onDelete { offsets in
                            offsets.map { openItems[$0] }
                                   .forEach(store.deleteParkingLotItem)
                        }
                    } header: {
                        Text("Parked · \(openItems.count)")
                    }

                    if !doneItems.isEmpty {
                        Section("Done") {
                            ForEach(doneItems) { item in
                                row(item)
                            }
                            .onDelete { offsets in
                                offsets.map { doneItems[$0] }
                                       .forEach(store.deleteParkingLotItem)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var openItems: [ParkingLotItem] { store.parkingLot.filter { !$0.done } }
    private var doneItems: [ParkingLotItem] { store.parkingLot.filter { $0.done } }

    private func row(_ item: ParkingLotItem) -> some View {
        HStack(alignment: .top) {
            Button {
                store.toggleParkingLotItem(item)
            } label: {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.done ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .strikethrough(item.done)
                    .foregroundStyle(item.done ? .secondary : .primary)
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !item.done, store.timerState.mode != .idle {
                Button {
                    store.promoteParkingLotItemToSession(item)
                } label: {
                    Image(systemName: "arrow.up.right.circle")
                }
                .buttonStyle(.borderless)
                .help("Add to current session")
            }
        }
    }

    private var composer: some View {
        HStack {
            TextField("Park a distraction…", text: $draft)
                .focused($composerFocused)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit(add)
            Button(action: add) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    private func add() {
        store.addParkingLotItem(draft)
        draft = ""
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Nothing parked.")
                .font(.headline)
            Text("If a new idea or worry grabs your attention mid-session, park it here and get back to work.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
