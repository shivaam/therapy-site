# Handoff — continue on the Mac mini

The branch `claude/pomodoro-timer-ios-app-gooHp` is **mid-rewrite and does not
build**. Last working build: commit `8ff71eb`. Work on a Mac with Xcode so
every step can be compiled and run.

## Setup

```bash
git clone https://github.com/shivaam/therapy-site.git
cd therapy-site && git checkout claude/pomodoro-timer-ios-app-gooHp
brew install xcodegen
cd PomodoroFocus && xcodegen generate && open PomodoroFocus.xcodeproj
```

Build from the command line to check errors:

```bash
xcodebuild -project PomodoroFocus.xcodeproj -scheme PomodoroFocus \
  -destination 'generic/platform=iOS Simulator' build
```

## Product direction (from the user)

- **Free app. Minimal, easy, simple.** Built for ADHD brains: few decisions,
  one big Start button, nothing on screen that isn't needed right now.
- iPhone + Apple Watch only.

## User-reported problems to fix

1. Timer sometimes starts at **25:01**.
2. Unclear how focus + break ("25 + 5") works.
3. The full step queue on the session screen is clutter. Show only *now* and
   *up next*.
4. **Lock screen and Dynamic Island don't show the timer.**
5. **Timer doesn't finish when the app is minimized.**
6. Needs an optional **sound/beep when a timer ends**, easy to change.
7. Presets for contexts (work, morning, …), designed thoughtfully.
8. Needs a proper **app icon**.

## Done in commit `40b47db`

- `Shared/Models/Preset.swift`: presets are now **rounds** (`FocusRound`:
  focus minutes + break after). The long break comes after the last round.
  Fields: `icon`, `colorHex`, `bestTime: TimeOfDay`, `sounds: SoundChoice`,
  `lastUsedAt`. `steps` is derived. The decoder migrates the old step-list
  format. Defaults: Quick Start, Classic, Deep Work (45/45/25/25).
- `Shared/Models/Sounds.swift`: `AmbientSound` (silent, tickTock, softTick,
  brownNoise, rain), `AlertSound` (silent, chime, bell, digital, bowl),
  `SoundChoice` (nil = app default). The case is `.silent`, not `.none`, to
  avoid clashing with `Optional.none`.
- `Routine` has a `sounds` field and backward-compatible decoding.
- `Shared/Utils`: `TimeFormat` (replaces `Duration`, which shadowed Swift's
  stdlib type), `Color(hex:)` plus `.focusDefault/.breakGreen/.longBreakBlue`,
  and `Collection[safe:]`.
- Removed: old home/preset list/routine list/tab view, `AmbientAudio`,
  `WatchPresetListView`, and the HTML mockups.

## Still to do (planned design)

### Models / services
- **`TimerState`**: modes `idle, running, paused, waiting, finished`
  (`waiting` = the step ended and the next one waits for a tap). Store
  `stepEndsAt` (while running) and `pausedRemaining: TimeInterval`. Add
  `stepKind`, `round`, `roundCount`, `nextKind`, `nextDurationSeconds`,
  `sessionID`, and `focusSecondsCompleted`.
  - **Fix for 25:01:** `displaySeconds = min(stepTotal, ceil(remaining - 0.01))`.
    Never round the paused remainder.
- **`AppSettings`** (its own file): `ambientSound`, `ambientVolume`,
  `endSound`, `hapticsOnTransition`, `autoStartBreaks`, `autoStartFocus`.
  Decode every field with `decodeIfPresent`.
- **`AppStore`**:
  - Add `didSet { scheduleSave() }` on the persisted arrays and settings, so
    views can bind `$store.settings.x` directly.
  - **Persist the running session** (timerState, activePreset, activeRoutine,
    sessionTasks) to `session.json`, so it survives iOS killing the app.
  - Add `currentAmbient` / `currentEndSound` (session override, otherwise the
    default), `setSessionAmbient/EndSound`, `markPresetUsed`, and
    `featuredPreset()`: prefer presets matching the current time of day, most
    recently used first.
  - Also add `duplicatePreset`, `restoreDefaultPresets`, and
    `upsertPreset/upsertRoutine`.
- **`TimerEngine`**:
  - Stop mutating state every tick. Schedule a one-shot `Timer` at
    `stepEndsAt`.
  - `reconcile(now:)` catches up through every step boundary that passed
    while suspended. Chain each next step from the previous step's end time,
    not from now.
  - Emit only the **last** event: `.stepEnded(...)` or `.sessionFinished`.
  - API: `start(preset, projectID:)`, `start(routine)`, `pause`, `resume`
    (also starts a `waiting` step), `togglePause`, `skip`, `stop`.
- **Views tick with `TimelineView(.periodic(from: end - total, by: 1))`** in a
  shared `TimerClock` view (in `Shared/Views`, also used by the Watch).

### iOS
- **`AudioController`** (replaces `AmbientAudio`):
  - Ambient loop. Mute sets volume to 0 but keeps the loop playing, so iOS
    keeps the app alive in the background.
  - End sound via a separate player, plus preview in the sound picker.
- **`NotificationScheduler`**:
  - Schedule one local notification per upcoming step boundary (follow the
    auto-start chain) using the end sound file. This is what plays the sound
    when the app is suspended.
  - Leave pending notifications due within about 1 second, to avoid racing
    the boundary.
  - Foreground delegate returns `[]`, because the app plays the sound itself.
- **Live Activity** (new `Widgets` extension target plus a
  `LiveActivityShared/FocusActivityAttributes.swift` file shared by the app
  and the extension):
  - Lock screen and Dynamic Island use `Text(timerInterval:countsDown:)` and
    `ProgressView(timerInterval:)`, so they tick without updates.
  - Set `staleDate = stepEndsAt` and show "Time's up" when stale.
  - Add `NSSupportsLiveActivities` to the app's Info.plist.
- **`SessionCoordinator`**:
  - Observes the store (debounced) to drive ambient audio, the Live Activity,
    notifications, and the Watch snapshot.
  - On `scenePhase == .active`, calls `engine.reconcile()`.
  - Plays the end sound and haptic in the foreground.
- **Simplified UI: 3 tabs**: Focus, Brain Dump, Settings.
  - **Home:**
    - A hero card for the featured preset (icon, summary, timeline bar,
      "ends ~time", a project chip menu, a big Start button).
    - A horizontal row of presets: tap to select, long-press to edit,
      duplicate, or delete.
    - A Routines list with a play button on each.
  - **Session:**
    - A colored phase pill (FOCUS / BREAK) and round dots.
    - A big ring; tapping it mutes or unmutes.
    - Stop (asks for confirmation), Pause, and Skip.
    - One "Up next" line and a sound chip that opens a sound picker.
    - The checklist (routine tasks or session tasks) and the brain-dump button.
    - In `waiting`: a big "Start 5 min break" button. When finished: a summary
      with Done / Go again.
  - **Preset editor:**
    - Name, icon, and color.
    - "Same length every round" toggle: when on, set the round count, focus
      length, and break length; when off, edit each round.
    - Long break and repeat. A plain-English preview ("Focus 25 → Break 5 →
      …, done by 11:40").
    - Sounds and best time of day.
  - **Settings:**
    - Default sounds, auto-start toggles, haptics.
    - Projects (max 5 active), notification permission.
    - "Restore default presets", and a line saying it's free, no ads, no
      tracking.
- **Assets:**
  - Synthesize WAV files into `iOS/Resources/Sounds`:
    `ambient_tick_tock`, `ambient_soft_tick`, `ambient_brown_noise`,
    `ambient_rain` (loop-crossfaded), and `alert_chime/bell/digital/bowl`.
  - App icon at 1024×1024 with no alpha: a tomato-shaped progress ring with a
    leaf, on a dark navy background. Same file for the Watch.

### Watch
- Snapshot includes settings, `activePreset`, and `activeRoutine`.
  - **Only the phone pushes snapshots; only the Watch applies them.** The old
    code let the Watch overwrite the phone's presets.
  - On activation, read `receivedApplicationContext`.
- Commands apply locally first (instant UI), then go to the phone. After a
  snapshot, run `engine.reconcile()` on the Watch, with a haptic on step
  events.
- One-tap start from the preset list. The session view uses `TimerClock`,
  with stop (confirmation), pause/resume, and skip. Show a "Start break"
  button when `waiting`.

### project.yml
- Remove the bogus `resources:` keys and the iOS `WKCompanionAppBundleIdentifier`.
- iPhone only (`TARGETED_DEVICE_FAMILY: "1"`).
- Add `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`.
- Add the `PomodoroFocusWidgets` app-extension target. Its sources are
  `Widgets`, `LiveActivityShared`, and `Shared/Utils`.
- Add `LiveActivityShared` to the app's sources.
- Exclude `Info.plist` and `*.md` from the sources.

## Known bugs in the remaining old files
- `RoutineListView` used `.foregroundStyle(.accent)`, which doesn't exist.
  That file is now deleted.
- The Watch used `[safe:]`, which was only defined in an iOS file. It now
  lives in `Shared/Utils`.
