import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

struct HoverCapsuleContent<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let helpText: String
    @ViewBuilder let label: () -> Label
    @State private var isHovered = false

    var body: some View {
        label()
            .foregroundStyle(isHovered ? Color.primary : Color.primary.opacity(0.92))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundColor, in: Capsule())
            .contentShape(Capsule())
            .overlay(alignment: .bottom) {
                if isHovered {
                    Text(helpText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tooltipBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(tooltipBorder, lineWidth: 1))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.10 : 0.24), radius: 8, y: 4)
                        .offset(y: 38)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeOut(duration: 0.14), value: isHovered)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
    }

    private var backgroundColor: Color {
        isHovered ? Color.primary.opacity(0.10) : Color.primary.opacity(0.06)
    }

    private var tooltipBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.96) : Color.black.opacity(0.88)
    }

    private var tooltipBorder: Color {
        colorScheme == .dark ? Color.black.opacity(0.08) : Color.white.opacity(0.08)
    }
}
