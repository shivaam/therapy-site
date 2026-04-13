import SwiftUI

/// Low-friction capture surface reachable from the active timer screen.
/// Keyboard is focused on appear; hitting save routes the text to either the
/// scratchpad or the parking lot without leaving the timer.
struct QuickCaptureSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's in your head?")
                    .font(.headline)
                TextField("Type anything — don't edit, just dump.",
                          text: $text,
                          axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)

                VStack(spacing: 10) {
                    Button {
                        store.appendScratchpad(text)
                        dismiss()
                    } label: {
                        Label("Save to Scratchpad", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmed.isEmpty)

                    Button {
                        store.addParkingLotItem(text)
                        dismiss()
                    } label: {
                        Label("Park for Later", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(trimmed.isEmpty)
                }

                Text("Scratchpad = thoughts. Parking Lot = things to come back to.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Brain Dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
