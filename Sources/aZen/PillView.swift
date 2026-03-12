import SwiftUI

struct PillView: View {
    @ObservedObject var sessionManager: FocusSessionManager

    var body: some View {
        HStack(spacing: 0) {
            if sessionManager.state == .completed {
                completedContent
            } else {
                activeContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(minWidth: 300, maxWidth: 400)
        .background(pillBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }

    private var activeContent: some View {
        HStack {
            Text(sessionManager.taskName)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 16)

            Text(sessionManager.formattedTimeRemaining)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var completedContent: some View {
        HStack {
            Text("Time's up")
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.white)

            Spacer(minLength: 16)

            Text("⌘⇧F")
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var pillBackground: some View {
        Group {
            if sessionManager.state == .completed {
                Capsule().fill(.orange.opacity(0.85))
            } else if sessionManager.state == .paused {
                Capsule().fill(.gray.opacity(0.75))
            } else {
                Capsule().fill(.black.opacity(0.75))
            }
        }
        .background(.ultraThinMaterial, in: Capsule())
    }
}
