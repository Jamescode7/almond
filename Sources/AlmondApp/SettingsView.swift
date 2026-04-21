import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultAppearance") private var defaultAppearanceRaw: String = AppearanceMode.system.rawValue
    @AppStorage("defaultZoom") private var defaultZoom: Int = 100

    private let zoomChoices: [Int] = [80, 90, 100, 110, 120, 150, 200]

    var body: some View {
        Form {
            Section {
                Picker("Default appearance", selection: $defaultAppearanceRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Picker("Default zoom", selection: $defaultZoom) {
                    ForEach(zoomChoices, id: \.self) { percent in
                        Text("\(percent)%").tag(percent)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Appearance")
                    .font(.headline)
            }

            Section {
                MDVInstallerView()
            } header: {
                Text("almond CLI")
                    .font(.headline)
            } footer: {
                Text("Creates a symlink at /usr/local/bin/almond so you can open markdown files from Terminal: almond file.md")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 360)
    }
}

private struct MDVInstallerView: View {
    var body: some View {
        HStack {
            Button("Install symlink") {
                CLIInstaller.install()
            }
            Button("Remove symlink") {
                CLIInstaller.uninstall()
            }
            Spacer()
        }
    }
}
