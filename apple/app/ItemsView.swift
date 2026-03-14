import SwiftUI
import Observation

@Observable
@MainActor
private final class ItemsViewModel {
    private(set) var items: [ItemResponse] = []
    var newName = ""
    var isSubmitting = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func loadItems(accessToken: String) async {
        do {
            items = try await api.getItems(accessToken: accessToken)
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addItem(accessToken: String) async {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let item = try await api.createItem(accessToken: accessToken, name: name)
            items.insert(item, at: 0)
            newName = ""
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(accessToken: String, id: String) async {
        do {
            try await api.deleteItem(accessToken: accessToken, id: id)
            items.removeAll { $0.id == id }
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ItemsView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var vm = ItemsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Add item form
            HStack(spacing: 8) {
                TextField("Item name", text: $vm.newName)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .disabled(vm.isSubmitting)
                    .accessibilityIdentifier("items_nameTextField")

                Button {
                    guard let token = auth.accessToken else { return }
                    Task { await vm.addItem(accessToken: token) }
                } label: {
                    if vm.isSubmitting {
                        ProgressView()
                            .frame(width: 44, height: 20)
                    } else {
                        Text("Add")
                            .frame(width: 44, height: 20)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isSubmitting || vm.newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("items_addButton")
            }
            .padding()

            if let error = vm.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            Divider()

            if vm.items.isEmpty {
                Spacer()
                Text("No items yet.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("items_emptyState")
                Spacer()
            } else {
                List {
                    ForEach(vm.items) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Button(role: .destructive) {
                                guard let token = auth.accessToken else { return }
                                Task { await vm.deleteItem(accessToken: token, id: item.id) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Delete \(item.name)")
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Items")
        #if os(macOS)
        .frame(minWidth: 300)
        #endif
        .task {
            guard let token = auth.accessToken else { return }
            await vm.loadItems(accessToken: token)
        }
    }
}

#Preview {
    NavigationStack {
        ItemsView()
    }
    .environment(AuthViewModel())
}
