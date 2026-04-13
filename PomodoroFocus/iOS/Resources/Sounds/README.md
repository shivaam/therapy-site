# Ambient sounds

Drop loopable audio files here and they'll be bundled into the iOS app. The
player in `iOS/Audio/AmbientAudio.swift` searches for `.caf`, `.mp3`, `.wav`,
and `.m4a` in that order.

Expected filenames (matches `AmbientSound.fileName` in
`Shared/Services/AppStore.swift`):

| Sound          | Filename              |
|----------------|-----------------------|
| Tick-tock clock| `tick.caf`            |
| Gentle rain    | `rain.caf`            |
| Brown noise    | `brown_noise.caf`     |
| Café hum       | `cafe.caf`            |

If a file is missing the app still works — it just won't play ambient audio
for that option. A 30–60 second file with a seamless loop works best because
`AVAudioPlayer.numberOfLoops = -1` will repeat it indefinitely.
