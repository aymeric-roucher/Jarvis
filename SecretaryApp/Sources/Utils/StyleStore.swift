import Foundation

final class StyleStore: ObservableObject {
    @Published var styleText: String = ""

    private let storageKey = "userStyleExamples"

    init() {
        load()
    }

    func save() {
        UserDefaults.standard.set(styleText, forKey: storageKey)
    }

    private func load() {
        styleText = UserDefaults.standard.string(forKey: storageKey) ?? ""
    }
}