import SwiftUI

struct WaveformView: View {
    @ObservedObject var recorder: AudioRecorder
    var isRecording: Bool

    private let barCount = AudioRecorder.waveformBarCount
    private let barSpacing: CGFloat = 2
    private let barWidth: CGFloat = 3

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(Theme.textColor.opacity(0.7))
                    .frame(width: barWidth, height: barHeight(for: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let levels = recorder.audioLevels
        guard isRecording, !levels.isEmpty else {
            return 4 // Minimum height when not recording
        }

        // Data flows left to right: newest on left (index 0), oldest on right
        let levelIndex = levels.count - 1 - index
        if levelIndex >= 0 && levelIndex < levels.count {
            let level = CGFloat(levels[levelIndex])
            return max(4, level * 20)
        }
        return 4
    }
}
