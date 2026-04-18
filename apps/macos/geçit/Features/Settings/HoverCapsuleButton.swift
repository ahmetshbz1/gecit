import SwiftUI

struct HoverCapsuleButton<Label: View>: View {
    let helpText: String
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(isHovered ? Color.primary : Color.primary.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(backgroundColor, in: Capsule())
                .animation(.easeOut(duration: 0.14), value: isHovered)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .overlay(alignment: .bottom) {
            if isHovered {
                Text(helpText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
                    .offset(y: 34)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        isHovered ? Color.primary.opacity(0.10) : Color.primary.opacity(0.06)
    }
}
