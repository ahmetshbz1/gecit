import SwiftUI

struct PageHeader: View {
    let title: String
    let theme: AppTheme
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onBack) {
                    Label("Geri", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()

                Spacer()
            }

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
        }
    }
}
