//
//  SettingsView.swift
//  iStatus
//
//  Created by Гарик Джан on 09.02.2025.
//

import AppKit
import SwiftUI

let menuWidth = CGFloat(240)

struct MenuButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        isHovered
                            ? Color(nsColor: .selectedMenuItemColor)
                            : Color.clear)  // Используем цвет выделенного пункта меню

            )
            .contentShape(Rectangle())  // Чтобы увеличить область наведения
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct AdvancedSettingsButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack {
            Button("Open Settings…") {
                openSettings()
            }.buttonStyle(MenuButtonStyle())
                .font(Font(NSFont.menuFont(ofSize: NSFont.systemFontSize)))  // Используем системный шрифт меню
        }
        .padding(.horizontal, 5)
        .frame(width: menuWidth)
    }
}

struct SettingsView: View {
    @AppStorage(settingsPortFieldName) private var port: String = ""

    @EnvironmentObject var appDelegate: AppDelegate

    @Environment(\.dismiss) var dismiss

    var buttonWidth: CGFloat = 60

    var body: some View {
        VStack(spacing: 10) {

            Form {
                Section("Connection settings") {

                    TextField("Port", text: $port)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }

            Spacer()  // Отталкивает кнопки вниз

            HStack {
                Spacer()  // Отталкивает кнопки вправо

                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel").frame(width: buttonWidth)
                }

                Button(action: {
                    appDelegate.updateSettings(port: port)
                    dismiss()
                }) {
                    Text("OK").frame(width: buttonWidth)
                }

                .keyboardShortcut(.defaultAction)  // Enter = OK
            }
            .padding(.top, 10)
        }
        .padding(14)
        .frame(width: 300, height: 130)
    }
}

func createSettingsMenuItem() -> NSMenuItem {
    let settingsItem = NSMenuItem()
    let settingsHostingView = NSHostingView(rootView: AdvancedSettingsButton())
    settingsHostingView.setFrameSize(settingsHostingView.intrinsicContentSize)
    settingsItem.view = settingsHostingView

    return settingsItem
}

#Preview {
    SettingsView()
}
