import SwiftUI

struct SettingsPageView: View {
    @ObservedObject var model: AppModel
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Ayarlar", theme: theme) {
                model.currentPage = .main
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Spacer()
                        Button {
                            model.resetSettingsToDefault()
                        } label: {
                            HoverCapsuleContent(helpText: "Varsayılan ayarlara dön") {
                                Text("Varsayılana dön")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    SettingsField(title: "Fake TTL", theme: theme) {
                        NativeStepperField(value: $model.settingsFakeTTL, minValue: 1, maxValue: 64)
                    }

                    SettingsField(title: "DoH", theme: theme) {
                        Toggle("Etkin", isOn: $model.settingsDoHEnabled)
                            .toggleStyle(.switch)
                    }

                    SettingsField(title: "Upstream", theme: theme) {
                        Picker("Upstream", selection: $model.settingsDoHUpstream) {
                            ForEach(AppModel.dohPresets, id: \.self) { preset in
                                Text(preset.capitalized).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SettingsField(title: "Interface", theme: theme) {
                        TextField("en0", text: $model.settingsInterface)
                            .textFieldStyle(.roundedBorder)
                    }

                    SettingsField(title: "Ports", theme: theme) {
                        TextField("443 veya 443,8443", text: $model.settingsPorts)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(16)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 18))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
