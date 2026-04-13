import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var audio: AmbientAudio

    var body: some View {
        NavigationStack {
            Form {
                Section("Ambient sound") {
                    Picker("Sound", selection: Binding(
                        get: { store.settings.ambientSound },
                        set: { v in store.updateSettings { $0.ambientSound = v } }
                    )) {
                        ForEach(AmbientSound.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    HStack {
                        Text("Volume")
                        Slider(value: Binding(
                            get: { store.settings.ambientVolume },
                            set: { v in store.updateSettings { $0.ambientVolume = v } }
                        ), in: 0...1)
                    }
                    Button("Preview") {
                        audio.start(store.settings.ambientSound,
                                    volume: store.settings.ambientVolume)
                    }
                    Button("Stop preview", role: .destructive) {
                        audio.stop()
                    }
                }

                Section("Session behavior") {
                    Toggle("Auto-start breaks", isOn: Binding(
                        get: { store.settings.autoStartBreaks },
                        set: { v in store.updateSettings { $0.autoStartBreaks = v } }
                    ))
                    Toggle("Auto-start focus blocks", isOn: Binding(
                        get: { store.settings.autoStartFocus },
                        set: { v in store.updateSettings { $0.autoStartFocus = v } }
                    ))
                    Toggle("Haptics on transition", isOn: Binding(
                        get: { store.settings.hapticsOnTransition },
                        set: { v in store.updateSettings { $0.hapticsOnTransition = v } }
                    ))
                }

                Section(footer: Text("Drop your own loopable audio into iOS/Resources/Sounds. File names: tick.caf, rain.caf, brown_noise.caf, cafe.caf.")) {
                    Text("Audio assets").font(.headline)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
