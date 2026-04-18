import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var model: AppModel

    private var theme: AppTheme {
        AppTheme.current(for: colorScheme)
    }

    var body: some View {
        ZStack {
            theme.backgroundBase.ignoresSafeArea()
            LinearGradient(colors: [theme.backgroundAccent, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Group {
                switch model.currentPage {
                case .main:
                    MainPageView(model: model, theme: theme)
                case .logs:
                    LogsPageView(model: model, theme: theme)
                case .settings:
                    SettingsPageView(model: model, theme: theme)
                }
            }
            .padding(20)
        }
        .frame(width: 360, height: 500)
        .focusable(false)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: model.status.state)
        .animation(.easeInOut(duration: 0.2), value: model.currentPage)
    }
}

#Preview {
    ContentView(model: AppModel())
}
