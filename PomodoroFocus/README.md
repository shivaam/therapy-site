# Pomodoro Focus — iPhone + Apple Watch

A SwiftUI Pomodoro timer built for iPhone with a companion Apple Watch app.

## Features

- **Per-step custom durations.** A preset is a list of steps (focus / short
  break / long break) and each step has its own length. The "4 sessions: 45, 45,
  25, 25 with custom breaks between" shape is just a preset.
- **Presets.** Save any sequence as a reusable preset. Two seed presets ship
  by default.
- **Projects.** Tag a session with a project. Hard cap of 5 active projects —
  enforced in `AppStore.addProject`. Archive a project to free the slot.
- **Ambient sound.** Tick-tock clock, rain, brown noise, café hum. Plays in a
  loop during focus blocks, mutes during breaks. Drop your own loops into
  `iOS/Resources/Sounds`.
- **Morning & night routines.** Single-timer runs that display their checklist
  on screen the whole time. Tasks are tappable to mark done.
- **Apple Watch.** Start / pause / resume / stop / skip from the wrist. State
  mirrors the phone via WatchConnectivity; the phone stays the source of truth.
- **Accurate across backgrounding.** The timer engine uses an absolute end
  timestamp, so pausing/backgrounding doesn't drift.

## Building

The Xcode project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen). This keeps the repo
human-readable and avoids committing a fragile `project.pbxproj`.

```bash
# one-time
brew install xcodegen

# from this directory
cd PomodoroFocus
xcodegen generate

# then open
open PomodoroFocus.xcodeproj
```

In Xcode:

1. Pick your development team in each target's Signing & Capabilities.
2. Select the **PomodoroFocus** scheme and run on an iPhone (or simulator).
3. Select the **PomodoroFocusWatch** scheme and run on a paired Apple Watch or
   simulator.

Minimum targets: **iOS 17**, **watchOS 10**.

## Project layout

```
PomodoroFocus/
├── project.yml                 # XcodeGen spec — source of truth for targets
├── Shared/                     # Code compiled into both iOS and watchOS apps
│   ├── Models/                 # SessionStep, Preset, Project, Routine, TimerState
│   ├── Services/               # AppStore (persistence), TimerEngine, WatchSession
│   └── Utils/                  # Duration formatting, Color(hex:)
├── iOS/
│   ├── PomodoroFocusApp.swift  # @main entry, wires up audio + WatchConnectivity
│   ├── Audio/AmbientAudio.swift
│   ├── Views/
│   │   ├── RootTabView.swift
│   │   ├── Timer/              # TimerHomeView, ActiveSessionView
│   │   ├── Presets/            # PresetListView, PresetEditorView
│   │   ├── Projects/           # ProjectListView (+ inline editor)
│   │   ├── Routines/           # RoutineListView, RoutineEditorView, RoutineRunView
│   │   └── Settings/SettingsView.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Sounds/             # Drop tick.caf, rain.caf, etc. here
└── Watch/
    ├── PomodoroFocusWatchApp.swift
    ├── Views/                  # WatchRootView, WatchPresetListView, WatchActiveSessionView
    └── Resources/Assets.xcassets
```

## How pieces fit together

- `AppStore` owns presets, projects, routines, settings, and the current
  `TimerState`. State is persisted as JSON in Application Support.
- `TimerEngine` mutates `AppStore.timerState`. On every state change the iOS
  app pushes a snapshot to the Watch and vice-versa via `WatchSession`.
- `AmbientAudio` (iOS only) reacts to timer transitions: starts on focus steps,
  stops on breaks/idle/finish. Uses `AVAudioSession.playback` with
  `mixWithOthers` so other audio can coexist.

## What you still need to provide

- **Audio files.** Drop loopable `.caf` / `.mp3` files into
  `iOS/Resources/Sounds` — see that directory's README for names. The app
  degrades gracefully to silent if a file is missing.
- **App icons.** `AppIcon.appiconset` is empty; add 1024×1024 icons before
  shipping.
- **Signing.** Set your team on both targets.

## Notes on choices

- Codable + JSON file storage instead of SwiftData. The dataset is tiny and
  this makes snapshotting to the Watch a one-liner (`try JSONEncoder().encode`).
- `project.yml` instead of committed `.xcodeproj` — avoids merge conflicts and
  makes target configuration reviewable as plain YAML.
- Timer uses an absolute `stepEndsAt: Date` rather than counting down a local
  integer so accuracy survives backgrounding.
