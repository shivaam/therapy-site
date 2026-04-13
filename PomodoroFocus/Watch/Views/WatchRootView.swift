import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            if store.timerState.mode != .idle {
                WatchActiveSessionView()
            } else {
                WatchPresetListView()
            }
        }
    }
}
