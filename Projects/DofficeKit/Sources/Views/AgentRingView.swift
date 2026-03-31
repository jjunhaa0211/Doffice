import SwiftUI
import DesignSystem

// ═══════════════════════════════════════════════════════
// MARK: - Agent Notification Ring
// ═══════════════════════════════════════════════════════

/// Pulsing ring that indicates an AI agent is waiting for user input.
/// Inspired by cmux's blue ring notification system.
public struct AgentRingView: View {
    public let color: Color
    public let size: CGFloat
    @State private var isPulsing = false

    public var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(color.opacity(isPulsing ? 0.0 : 0.6), lineWidth: 1.5)
                .frame(width: size * (isPulsing ? 1.8 : 1.0), height: size * (isPulsing ? 1.8 : 1.0))
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0 : 0.8)

            // Inner steady ring
            Circle()
                .stroke(color.opacity(0.8), lineWidth: 1.5)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

/// Blue glow border overlay for terminal panes when agent needs input
public struct AgentWaitingOverlay: View {
    public let isWaiting: Bool
    @State private var glowPhase: CGFloat = 0

    public var body: some View {
        if isWaiting {
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.blue.opacity(0.2),
                            Color.cyan.opacity(0.6),
                            Color.blue.opacity(0.2),
                            Color.blue.opacity(0.8)
                        ]),
                        center: .center,
                        startAngle: .degrees(glowPhase),
                        endAngle: .degrees(glowPhase + 360)
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: Color.blue.opacity(0.4), radius: 6)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        glowPhase = 360
                    }
                }
        }
    }
}

/// Notification badge with unread count
public struct NotificationBadge: View {
    public let count: Int

    public var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, count > 9 ? 4 : 3)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.blue))
                .fixedSize()
        }
    }
}
