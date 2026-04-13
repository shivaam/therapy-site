import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingNew = false
    @State private var editing: Project?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.projects) { project in
                        Button { editing = project } label: {
                            HStack {
                                Circle().fill(Color(hex: project.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(project.name)
                                Spacer()
                                if !project.isActive {
                                    Text("Archived").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { idx in
                        idx.map { store.projects[$0] }.forEach(store.deleteProject)
                    }
                } header: {
                    Text("\(store.activeProjects.count) / \(Project.maxActive) active")
                } footer: {
                    Text("Hard limit of \(Project.maxActive) active projects. Archive one to make room.")
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .disabled(store.activeProjects.count >= Project.maxActive)
                }
            }
            .alert("Can't add project",
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingNew) {
                ProjectEditorView(project: Project(name: "New project"), isNew: true) { new in
                    do { try store.addProject(new) }
                    catch { errorMessage = error.localizedDescription }
                }
            }
            .sheet(item: $editing) { project in
                ProjectEditorView(project: project, isNew: false) { updated in
                    do { try store.updateProject(updated) }
                    catch { errorMessage = error.localizedDescription }
                }
            }
        }
    }
}

private struct ProjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var project: Project
    let isNew: Bool
    let onSave: (Project) -> Void

    private let palette = ["#4F8EF7", "#F76C6C", "#6CC04A", "#F7B84F", "#B066F7", "#3DC1D3"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $project.name)
                Picker("Color", selection: $project.colorHex) {
                    ForEach(palette, id: \.self) { hex in
                        HStack {
                            Circle().fill(Color(hex: hex)).frame(width: 14, height: 14)
                            Text(hex)
                        }.tag(hex)
                    }
                }
                Toggle("Active", isOn: $project.isActive)
            }
            .navigationTitle(isNew ? "New Project" : "Edit Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(project)
                        dismiss()
                    }
                    .disabled(project.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
