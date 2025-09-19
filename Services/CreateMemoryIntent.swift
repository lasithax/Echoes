import Foundation
import AppIntents


/// When invoked, we set a small flag in UserDefaults that the app istens for and then opens the Create tab.
struct CreateMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Memory"
    static var description = IntentDescription("Open Echoes to start creating a new memory.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "shortcut_open_create_memory")
        return .result()
    }
}

/// Advertises this intent to the Shortcuts app with natural language phrases.
struct EchoesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateMemoryIntent(),
            phrases: [
                "Create a memory in Echoes",
                "New Echoes memory",
                "Capture a memory in Echoes"
            ],
            shortTitle: "Create Memory",
            systemImageName: "plus.circle"
        )
    }
}


