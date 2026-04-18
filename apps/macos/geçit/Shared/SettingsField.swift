import SwiftUI

struct SettingsField<Content: View>: View {
    let title: String
    let theme: AppTheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.textMuted)
            content()
        }
    }
}
