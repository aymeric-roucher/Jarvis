import SwiftUI
import AppKit

class ToastManager {
    static let shared = ToastManager()
    
    private var window: NSWindow?
    private var timer: Timer?
    
    func show(message: ChatMessage) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            let hosting = NSHostingView(rootView: ToastView(message: message))
            hosting.frame = NSRect(x: 0, y: 0, width: 360, height: 80)
            
            if self.window == nil {
                let screenFrame = NSScreen.main?.visibleFrame ?? .zero
                let origin = NSPoint(x: screenFrame.maxX - 380, y: screenFrame.maxY - 100)
                let win = NSWindow(
                    contentRect: NSRect(origin: origin, size: hosting.frame.size),
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                win.level = .floating
                win.isOpaque = false
                win.backgroundColor = .clear
                win.hasShadow = true
                win.ignoresMouseEvents = true
                self.window = win
            }
            
            self.window?.contentView = hosting
            self.window?.setFrameOrigin(self.window?.frame.origin ?? .zero)
            self.window?.orderFrontRegardless()
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                self.window?.orderOut(nil)
            }
        }
    }
}

private struct ToastView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(spacing: 8) {
            icon(for: message)
            Text(message.content)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
    }
    
    @ViewBuilder
    private func icon(for msg: ChatMessage) -> some View {
        switch msg.role {
        case .user:
            Image(systemName: "person").foregroundColor(.blue)
        case .assistant:
            Image(systemName: "sparkles").foregroundColor(.purple)
        case .tool:
            Image(systemName: "gearshape.fill").foregroundColor(.orange)
        case .system:
            Image(systemName: "info.circle").foregroundColor(.secondary)
        }
    }
}
