import SwiftUI
import AppKit

struct MenuPopupView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 10) {
            if appState.isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.9)
            } else {
                WaveformView(recorder: appState.audioRecorder, isRecording: appState.isRecording)
                    .frame(height: 30)
                    .opacity(appState.isRecording ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

final class MenuPopupManager {
    private var panel: NSPanel?
    private weak var appState: AppState?
    
    func show(appState: AppState) {
        self.appState = appState
        
        let contentView = MenuPopupView().environmentObject(appState)
        let hosting = NSHostingController(rootView: contentView)
        let panel = NSPanel(contentViewController: hosting)
        panel.styleMask = [.nonactivatingPanel, .borderless, .fullSizeContentView, .hudWindow]
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        
        hosting.view.layoutSubtreeIfNeeded()
        // Compute desired width with waveform visible, then fix it.
        let waveformWidth = hosting.view.fittingSize.width
        let fixedWidth = max(waveformWidth, 220)
        let fitHeight = hosting.view.fittingSize.height
        let panelHeight = max(fitHeight, 60)
        panel.setFrame(NSRect(x: 0, y: 0, width: fixedWidth, height: panelHeight), display: false)
        positionPanel(panel)
        panel.orderFrontRegardless()
        self.panel = panel
    }
    
    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
    
    private func positionPanel(_ panel: NSPanel) {
        if let screen = NSScreen.main {
            let origin = NSPoint(x: screen.visibleFrame.maxX - panel.frame.width - 16,
                                 y: screen.visibleFrame.minY + 40)
            panel.setFrameOrigin(origin)
        }
    }
}
