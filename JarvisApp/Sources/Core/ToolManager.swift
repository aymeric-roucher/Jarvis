import Foundation
import AppKit
import Carbon

struct ToolManager {

    func execute(toolName: String, args: ToolArguments) {
        do {
            switch toolName {
            case "type":
                if case .text(let text) = args {
                    typeString(text)
                }
            case "open_app":
                if case .text(let target) = args {
                    try openAppOrURL(target)
                }
            case "switch_to":
                if case .text(let appName) = args {
                    try switchToApp(appName)
                }
            case "deep_research":
                if case .text(let topic) = args {
                    deepResearch(topic)
                }
            default:
                throw NSError(domain: "ToolManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown tool"])
            }
        } catch {
            handleToolError(toolName: toolName, error: error)
        }
    }

    private func handleToolError(toolName: String, error: Error) {        let errorMessage = "Tool '\(toolName)' failed: \(error.localizedDescription)"
        log("Tool execution error: \(errorMessage)")

        // Show error in chatbot and as independent toast
        Task { @MainActor in
            let errorMsg = ChatMessage(role: .system, content: errorMessage)
            AppState.shared?.messages.append(errorMsg)
            ToastManager.shared.show(message: errorMsg)
        }
    }
    
    private func typeString(_ string: String) {
        // Using CGEvent to simulate keystrokes
        let source = CGEventSource(stateID: .hidSystemState)
        
        for char in string {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                // We need to map char to keycode or use unicodeString
                var uniChar = Array(String(char).utf16)
                event.keyboardSetUnicodeString(stringLength: uniChar.count, unicodeString: &uniChar)
                event.post(tap: .cghidEventTap)
                
                if let upEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                    upEvent.keyboardSetUnicodeString(stringLength: uniChar.count, unicodeString: &uniChar)
                    upEvent.post(tap: .cghidEventTap)
                }
            }
        }
    }
    
    private func openAppOrURL(_ target: String) throws {
        // Check if target looks like a URL
        let isURL = target.contains(".") && (
            target.hasPrefix("http://") ||
            target.hasPrefix("https://") ||
            target.hasPrefix("www.") ||
            target.range(of: #"^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}"#, options: .regularExpression) != nil
        )

        if isURL {
            // It's a URL - open in default browser
            var urlString = target
            if !target.hasPrefix("http://") && !target.hasPrefix("https://") {
                urlString = "https://" + target
            }
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "ToolManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(target)"])
            }
            NSWorkspace.shared.open(url)
        } else {
            // Try to launch app by name
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target) {
                NSWorkspace.shared.open(appURL)
            } else {
                // Fallback: use shell open
                let process = Process()
                process.launchPath = "/usr/bin/open"
                process.arguments = ["-a", target]
                do {
                    try process.run()
                    process.waitUntilExit()
                    if process.terminationStatus != 0 {
                        throw NSError(domain: "ToolManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not open app: \(target)"])
                    }
                } catch {
                    throw NSError(domain: "ToolManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to open app: \(target)"])
                }
            }
        }
    }
    
    private func switchToApp(_ name: String) throws {
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if let appName = app.localizedName, appName.lowercased().contains(name.lowercased()) {
                app.activate()
                return
            }
        }
        throw NSError(domain: "ToolManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No running app found: \(name)"])
    }
    
    private func deepResearch(_ topic: String) {
        // Simple implementation: open a web search for the topic
        let query = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
        if let url = URL(string: "https://www.google.com/search?q=\(query)") {
            NSWorkspace.shared.open(url)
        }
    }
}

enum ToolArguments: Codable {
    case text(String)
    case none
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .text(x)
            return
        }
        if let x = try? container.decode([String:String].self) {
            // Handle dictionary args if complex, for now simplify
            if let val = x.values.first {
                self = .text(val)
                return
            }
        }
        self = .none
    }
    
    func encode(to encoder: Encoder) throws {}
}
