import SwiftUI

struct RoutineListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingNew = false
    @State private var editing: Routine?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.routines) { routine in
                    NavigationLink {
                        RoutineRunView(routine: routine)
                    } label: {
                        HStack {
                            Image(systemName: routine.kind.systemImage)
                                .foregroundStyle(.accent)
                            VStack(alignment: .leading) {
                                Text(routine.name).font(.headline)
                                Text("\(routine.tasks.count) tasks · \(Duration.clockString(routine.totalSeconds))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                editing = routine
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .onDelete { idx in
                    idx.map { store.routines[$0] }.forEach(store.deleteRoutine)
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) {
                RoutineEditorView(routine: Routine(name: "New routine",
                                                   kind: .custom,
                                                   totalSeconds: 10 * 60,
                                                   tasks: []))
            }
            .sheet(item: $editing) { routine in
                RoutineEditorView(routine: routine)
            }
        }
    }
}
