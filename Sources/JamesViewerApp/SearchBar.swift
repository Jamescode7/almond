import SwiftUI

struct SearchBar: View {
    @Binding var query: String
    let onSubmit: () -> Void
    let onDismiss: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Find in document (Enter for next match)", text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit(onSubmit)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
            .help("Close search (ESC)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thickMaterial)
        .overlay(Divider(), alignment: .bottom)
        .onAppear { isFocused = true }
    }
}
