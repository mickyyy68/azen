import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var sessionManager: FocusSessionManager
    @State private var taskInput: String = ""
    @State private var customMinutes: String = ""

    var body: some View {
        VStack(spacing: 16) {
            switch sessionManager.state {
            case .idle:
                idleView
            case .active, .paused:
                activeView
            case .completed:
                completedView
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 14) {
            Text("aZen")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField("What are you working on?", text: $taskInput)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            VStack(spacing: 8) {
                Text("Duration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    ForEach([15, 25, 45, 60], id: \.self) { minutes in
                        Button("\(minutes)m") {
                            customMinutes = "\(minutes)"
                        }
                        .buttonStyle(.bordered)
                        .tint(customMinutes == "\(minutes)" ? .accentColor : nil)
                    }
                }

                HStack {
                    TextField("Custom", text: $customMinutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: startSession) {
                Text("Start Focus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(taskInput.trimmingCharacters(in: .whitespaces).isEmpty || duration == nil)
            .keyboardShortcut(.return, modifiers: [])
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 14) {
            Text(sessionManager.taskName)
                .font(.headline)
                .lineLimit(2)

            Text(sessionManager.formattedTimeRemaining)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.medium)

            HStack(spacing: 12) {
                Button(sessionManager.state == .paused ? "Resume" : "Pause") {
                    if sessionManager.state == .paused {
                        sessionManager.resume()
                    } else {
                        sessionManager.pause()
                    }
                }
                .buttonStyle(.bordered)

                Button("End Session") {
                    sessionManager.stop()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 14) {
            Text("Time's up!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)

            Text(sessionManager.taskName)
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            VStack(spacing: 8) {
                Button(action: { continueSession() }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { newTask() }) {
                    Text("New Task")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: { sessionManager.stop() }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Actions

    private var duration: TimeInterval? {
        guard let minutes = Int(customMinutes), minutes > 0 else { return nil }
        return TimeInterval(minutes * 60)
    }

    private func startSession() {
        guard let duration else { return }
        let task = taskInput.trimmingCharacters(in: .whitespaces)
        guard !task.isEmpty else { return }
        sessionManager.start(task: task, duration: duration)
    }

    private func continueSession() {
        customMinutes = ""
        taskInput = sessionManager.taskName
        sessionManager.state = .idle
    }

    private func newTask() {
        taskInput = ""
        customMinutes = ""
        sessionManager.state = .idle
    }
}
