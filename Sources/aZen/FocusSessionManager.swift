import AppKit
import Combine

enum SessionState {
    case idle
    case active
    case paused
    case completed
}

@MainActor
final class FocusSessionManager: ObservableObject {
    @Published var taskName: String = ""
    @Published var totalDuration: TimeInterval = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var state: SessionState = .idle

    private var timerCancellable: AnyCancellable?

    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(task: String, duration: TimeInterval) {
        taskName = task
        totalDuration = duration
        timeRemaining = duration
        state = .active
        startTimer()
    }

    func pause() {
        guard state == .active else { return }
        state = .paused
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func resume() {
        guard state == .paused else { return }
        state = .active
        startTimer()
    }

    func stop() {
        state = .idle
        taskName = ""
        totalDuration = 0
        timeRemaining = 0
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func continueSession(duration: TimeInterval) {
        totalDuration = duration
        timeRemaining = duration
        state = .active
        startTimer()
    }

    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.tick()
                }
            }
    }

    private func tick() {
        guard state == .active else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        if timeRemaining <= 0 {
            timeRemaining = 0
            state = .completed
            timerCancellable?.cancel()
            timerCancellable = nil
            NSSound.beep()
        }
    }
}
