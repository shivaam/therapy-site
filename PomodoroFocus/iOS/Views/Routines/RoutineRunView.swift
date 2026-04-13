import SwiftUI

struct RoutineRunView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var engine: TimerEngine
    let routine: Routine

    var body: some View {
        Group {
            if store.timerState.mode != .idle && store.activeRoutine?.id == routine.id {
                ActiveSessionView()
            } else {
                Form {
                    Section("Checklist preview") {
                        ForEach(routine.tasks) { t in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                Text(t.text)
                            }
                        }
                    }
                    Section {
                        Button {
                            var fresh = routine
                            // Reset done flags at start of a run so the checklist
                            // is meaningful each time.
                            fresh.tasks = fresh.tasks.map { var t = $0; t.done = false; return t }
                            store.updateRoutine(fresh)
                            engine.startRoutine(fresh)
                        } label: {
                            Label("Start routine · \(Duration.clockString(routine.totalSeconds))",
                                  systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .navigationTitle(routine.name)
    }
}
