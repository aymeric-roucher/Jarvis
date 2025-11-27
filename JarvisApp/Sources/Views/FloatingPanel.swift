import SwiftUI
import AppKit

final class FloatingPanel<Content: View>: NSPanel {
    private let didClose: () -> Void
    
    init(view: @escaping () -> Content, contentRect: NSRect, didClose: @escaping () -> Void) {
        self.didClose = didClose
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel, .titled, .fullSizeContentView], backing: .buffered, defer: false)
        
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        becomesKeyOnlyIfNeeded = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        animationBehavior = .utilityWindow
        setFrame(contentRect, display: false)
        contentView = NSHostingView(rootView: view())
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    override func cancelOperation(_ sender: Any?) {
        close()
    }
    
    override func resignKey() {
        super.resignKey()
        close()
    }
    
    override func close() {
        super.close()
        didClose()
    }
}

final class FloatingPanelHandler {
    private var panel: FloatingPanel<AnyView>?
    private var onClose: (() -> Void)?
    private weak var appState: AppState?
    private var escMonitor: Any?
    private var clickMonitor: Any?
    
    func configureOnClose(_ onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func toggle(appState: AppState) {
        if panel == nil {
            show(appState: appState)
        } else {
            hide()
        }
    }
    
    func show(appState: AppState) {
        if panel != nil { return }
        self.appState = appState
        let panel = FloatingPanel(view: {
            AnyView(SpotlightView().environmentObject(appState))
        }, contentRect: NSRect(x: 0, y: 0, width: 740, height: 260), didClose: { [weak self] in
            self?.panel = nil
            Task { @MainActor in
                self?.onClose?()
            }
        })
        
        DispatchQueue.main.async {
            panel.orderFrontRegardless()
            panel.center()
            self.installMonitors()
        }
        
        self.panel = panel
        Task { @MainActor in appState.isSpotlightVisible = true }
    }
    
    func hide() {
        if let panel = panel {
            panel.orderOut(nil)
            self.panel = nil
            Task { @MainActor in self.onClose?() }
        }
        removeMonitors()
    }
    
    private func installMonitors() {
        removeMonitors()
        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
                self?.hide()
            }
        }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let panel = self?.panel else { return }
            let locInScreen: NSPoint
            if let win = event.window {
                locInScreen = win.convertPoint(toScreen: event.locationInWindow)
            } else {
                locInScreen = event.locationInWindow
            }
            if !panel.frame.contains(locInScreen) {
                self?.hide()
            }
        }
    }
    
    private func removeMonitors() {
        if let escMonitor = escMonitor {
            NSEvent.removeMonitor(escMonitor)
            self.escMonitor = nil
        }
        if let clickMonitor = clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
    }
}
