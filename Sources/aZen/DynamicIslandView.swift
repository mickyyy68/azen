import SwiftUI

// MARK: - Theme

private enum IslandTheme {
    static let teal = Color(hue: 0.52, saturation: 0.7, brightness: 0.9)
    static let amber = Color.orange
    static let bg = Color.black.opacity(0.75)
    static let setupBg = Color.black.opacity(0.72)
    static let completedBg = Color.orange.opacity(0.85)
}

// MARK: - Dynamic Island View

struct DynamicIslandView: View {
    @ObservedObject var sessionManager: FocusSessionManager
    @State private var appeared = false
    @State private var checkmarkProgress: CGFloat = 0
    @State private var checkDrawn = false

    // Setup form state
    @State private var taskInput: String = ""
    @State private var selectedMinutes: Int? = nil
    @State private var customMinutes: String = ""

    var onInteractionModeChanged: ((Bool) -> Void)?

    private var isVisible: Bool {
        sessionManager.state != .idle
    }

    private var isInteractive: Bool {
        sessionManager.state == .setup || sessionManager.state == .completed
    }

    private var currentSize: CGSize {
        switch sessionManager.state {
        case .idle: return CGSize(width: 120, height: 36)
        case .setup: return CGSize(width: 320, height: 200)
        case .active, .paused: return CGSize(width: 240, height: 36)
        case .completed: return CGSize(width: 280, height: 120)
        }
    }

    private var cornerRadius: CGFloat {
        switch sessionManager.state {
        case .idle, .active, .paused: return 18
        case .setup: return 26
        case .completed: return 20
        }
    }

    private var backgroundFill: Color {
        switch sessionManager.state {
        case .idle, .active, .paused: return IslandTheme.bg
        case .setup: return IslandTheme.setupBg
        case .completed: return IslandTheme.completedBg
        }
    }

    var body: some View {
        Group {
            switch sessionManager.state {
            case .idle:
                EmptyView()
            case .setup:
                setupContent
            case .active, .paused:
                compactContent
            case .completed:
                expandedContent
            }
        }
        .frame(width: currentSize.width, height: currentSize.height)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundFill)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: sessionManager.state)
        .onChange(of: isVisible) { _, visible in
            if visible {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appeared = true
                }
            } else {
                withAnimation(.easeIn(duration: 0.25)) {
                    appeared = false
                }
                resetCheckmark()
            }
        }
        .onChange(of: sessionManager.state) { oldState, newState in
            onInteractionModeChanged?(isInteractive)

            if newState == .completed {
                resetCheckmark()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        checkmarkProgress = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            checkDrawn = true
                        }
                    }
                }
            }

            if newState == .setup {
                if oldState == .completed && !sessionManager.taskName.isEmpty {
                    taskInput = sessionManager.taskName
                }
            }
        }
    }

    private func resetCheckmark() {
        checkmarkProgress = 0
        checkDrawn = false
    }

    // MARK: - Setup Content

    private var setupContent: some View {
        VStack(spacing: 12) {
            Text("aZen")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(3)

            IslandTextField(text: $taskInput, placeholder: "What are you focusing on?")
                .onSubmit { startIfReady() }

            // Duration presets
            HStack(spacing: 6) {
                ForEach([15, 25, 45, 60], id: \.self) { mins in
                    IslandPresetButton(
                        label: "\(mins)m",
                        isSelected: selectedMinutes == mins
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedMinutes = mins
                            customMinutes = ""
                        }
                    }
                }

                Rectangle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 1, height: 20)

                IslandCustomDuration(text: $customMinutes, onChanged: {
                    if !customMinutes.isEmpty {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedMinutes = nil
                        }
                    }
                })
            }

            IslandStartButton(disabled: !canStart) {
                startIfReady()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var canStart: Bool {
        let hasTask = !taskInput.trimmingCharacters(in: .whitespaces).isEmpty
        let hasDuration = selectedMinutes != nil || Int(customMinutes) ?? 0 > 0
        return hasTask && hasDuration
    }

    private func startIfReady() {
        guard canStart else { return }
        let minutes = selectedMinutes ?? (Int(customMinutes) ?? 0)
        let task = taskInput.trimmingCharacters(in: .whitespaces)
        sessionManager.start(task: task, duration: TimeInterval(minutes * 60))
    }

    // MARK: - Compact Content

    private var compactContent: some View {
        HStack(spacing: 8) {
            PulsingDot(isPaused: sessionManager.state == .paused)

            Text(sessionManager.taskName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(sessionManager.state == .paused ? 0.7 : 1.0))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(sessionManager.formattedTimeRemaining)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(sessionManager.state == .paused ? 0.7 : 1.0))
                .contentTransition(.numericText())
                .animation(.default, value: sessionManager.formattedTimeRemaining)
        }
        .padding(.horizontal, 12)
        .transition(.opacity)
    }

    // MARK: - Expanded (Completed) Content

    private var expandedContent: some View {
        VStack(spacing: 8) {
            CheckmarkRing(circleProgress: checkmarkProgress, checkProgress: checkDrawn ? 1.0 : 0)
                .frame(width: 28, height: 28)

            Text(sessionManager.taskName)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("Time's up")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 8) {
                IslandActionButton(label: "Continue", style: .primary) {
                    taskInput = sessionManager.taskName
                    selectedMinutes = nil
                    customMinutes = ""
                    sessionManager.beginContinue()
                }

                IslandActionButton(label: "New Task", style: .secondary) {
                    taskInput = ""
                    selectedMinutes = nil
                    customMinutes = ""
                    sessionManager.beginNewTask()
                }

                IslandActionButton(label: "Done", style: .muted) {
                    sessionManager.stop()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Island Text Field

private struct IslandTextField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.4)))
            .textFieldStyle(.plain)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isFocused ? IslandTheme.teal.opacity(0.5) : .white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: isFocused ? IslandTheme.teal.opacity(0.15) : .clear, radius: 8)
            )
            .focused($isFocused)
            .onAppear { isFocused = true }
    }
}

// MARK: - Island Preset Button

private struct IslandPresetButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? IslandTheme.teal : .white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(isSelected ? 0 : 0.06), lineWidth: 1)
                        )
                )
                .shadow(color: isSelected ? IslandTheme.teal.opacity(0.3) : .clear, radius: 6)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Island Custom Duration

private struct IslandCustomDuration: View {
    @Binding var text: String
    var onChanged: () -> Void
    @FocusState private var isFocused: Bool

    private var hasValue: Bool { !text.isEmpty }

    var body: some View {
        HStack(spacing: 3) {
            TextField("", text: $text, prompt: Text("00").foregroundStyle(.white.opacity(0.20)))
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 26)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onChange(of: text) { _, _ in onChanged() }

            Text("m")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(hasValue || isFocused ? IslandTheme.teal.opacity(0.10) : .white.opacity(0.06))
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Island Start Button

private struct IslandStartButton: View {
    let disabled: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text("Start Focus")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(disabled ? .white.opacity(0.35) : .black.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(disabled ? .white.opacity(0.08) : IslandTheme.teal)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(disabled ? 0.06 : 0), lineWidth: 1)
                )
                .shadow(color: disabled ? .clear : IslandTheme.teal.opacity(0.2), radius: 8)
                .scaleEffect(isHovering && !disabled ? 1.02 : 1.0)
                .brightness(isHovering && !disabled ? 0.05 : 0)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
                .animation(.easeInOut(duration: 0.2), value: disabled)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Island Action Button

private enum IslandButtonStyle {
    case primary, secondary, muted
}

private struct IslandActionButton: View {
    let label: String
    let style: IslandButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(bgColor)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .black
        case .secondary: return .white.opacity(0.9)
        case .muted: return .white.opacity(0.6)
        }
    }

    private var bgColor: Color {
        switch style {
        case .primary: return .white.opacity(0.9)
        case .secondary: return .white.opacity(0.15)
        case .muted: return .white.opacity(0.08)
        }
    }
}

// MARK: - Pulsing Dot

struct PulsingDot: View {
    let isPaused: Bool
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
            .shadow(color: glowColor, radius: pulsing ? 8 : 3)
            .opacity(isPaused ? 0.5 : (pulsing ? 1.0 : 0.4))
            .onAppear {
                guard !isPaused else { return }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
            .onChange(of: isPaused) { _, paused in
                if paused {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pulsing = false
                    }
                } else {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                }
            }
    }

    private var dotColor: Color {
        isPaused ? .gray : IslandTheme.teal
    }

    private var glowColor: Color {
        isPaused ? .clear : IslandTheme.teal.opacity(0.6)
    }
}

// MARK: - Checkmark Ring

struct CheckmarkRing: View {
    var circleProgress: CGFloat
    var checkProgress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: circleProgress)
                .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))

            CheckmarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .padding(6)
        }
    }
}

// MARK: - Checkmark Shape

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.28))
        return path
    }
}
