import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TimerHomeView()
                .tabItem { Label("Focus", systemImage: "timer") }
            PresetListView()
                .tabItem { Label("Presets", systemImage: "square.stack.3d.up") }
            ProjectListView()
                .tabItem { Label("Projects", systemImage: "folder") }
            RoutineListView()
                .tabItem { Label("Routines", systemImage: "sun.and.horizon") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
