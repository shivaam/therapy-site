import Foundation
import Combine

/// Single observable source of truth for presets, projects, routines,
/// settings and the current timer state. Persists to a JSON file in the app's
/// Application Support directory. Small enough that the Watch can read the
/// same file via its own container (state is also sent via WatchConnectivity).
@MainActor
final class AppStore: ObservableObject {
    @Published var presets: [Preset]
    @Published var projects: [Project]
    @Published var routines: [Routine]
    @Published var settings: AppSettings
    @Published var timerState: TimerState = .idle
    /// The preset currently attached to the running/paused session, if any.
    @Published var activePreset: Preset?
    @Published var activeRoutine: Routine?

    private let storageURL: URL
    private var saveTask: Task<Void, Never>?

    init() {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)) ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("PomodoroFocus", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("state.json")

        if let data = try? Data(contentsOf: storageURL),
           let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            self.presets = snap.presets
            self.projects = snap.projects
            self.routines = snap.routines
            self.settings = snap.settings
        } else {
            self.presets = Preset.defaults
            self.projects = []
            self.routines = Routine.defaults
            self.settings = AppSettings()
        }
    }

    // MARK: - Presets

    func addPreset(_ preset: Preset) {
        presets.append(preset)
        scheduleSave()
    }

    func updatePreset(_ preset: Preset) {
        guard let idx = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[idx] = preset
        scheduleSave()
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        scheduleSave()
    }

    // MARK: - Projects

    enum ProjectError: LocalizedError {
        case activeLimitReached
        var errorDescription: String? {
            switch self {
            case .activeLimitReached:
                return "You can have at most \(Project.maxActive) active projects. Archive one first."
            }
        }
    }

    var activeProjects: [Project] {
        projects.filter { $0.isActive }
    }

    @discardableResult
    func addProject(_ project: Project) throws -> Project {
        if project.isActive, activeProjects.count >= Project.maxActive {
            throw ProjectError.activeLimitReached
        }
        projects.append(project)
        scheduleSave()
        return project
    }

    func updateProject(_ project: Project) throws {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        let wasActive = projects[idx].isActive
        if !wasActive, project.isActive, activeProjects.count >= Project.maxActive {
            throw ProjectError.activeLimitReached
        }
        projects[idx] = project
        scheduleSave()
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        scheduleSave()
    }

    // MARK: - Routines

    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        scheduleSave()
    }

    func updateRoutine(_ routine: Routine) {
        guard let idx = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[idx] = routine
        scheduleSave()
    }

    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        scheduleSave()
    }

    // MARK: - Settings

    func updateSettings(_ update: (inout AppSettings) -> Void) {
        update(&settings)
        scheduleSave()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var presets: [Preset]
        var projects: [Project]
        var routines: [Routine]
        var settings: AppSettings
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled, let self else { return }
            self.saveNow()
        }
    }

    private func saveNow() {
        let snap = Snapshot(presets: presets,
                            projects: projects,
                            routines: routines,
                            settings: settings)
        guard let data = try? JSONEncoder().encode(snap) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

struct AppSettings: Codable, Hashable {
    var ambientSound: AmbientSound = .tickTick
    var ambientVolume: Double = 0.6
    var hapticsOnTransition: Bool = true
    var autoStartBreaks: Bool = true
    var autoStartFocus: Bool = false
}

enum AmbientSound: String, Codable, CaseIterable, Identifiable {
    case none
    case tickTick
    case rain
    case brownNoise
    case cafe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .tickTick: return "Tick-tock clock"
        case .rain: return "Gentle rain"
        case .brownNoise: return "Brown noise"
        case .cafe: return "Café hum"
        }
    }

    /// File basename expected in the app bundle (user ships their own loops).
    var fileName: String? {
        switch self {
        case .none: return nil
        case .tickTick: return "tick"
        case .rain: return "rain"
        case .brownNoise: return "brown_noise"
        case .cafe: return "cafe"
        }
    }
}
