import AppKit
import SwiftUI

let settingsIpFieldName = "ipAddress"
let settingsPortFieldName = "port"
let defaultIpAddress = "192.168.1.10"
let defaultPort = "9999"

@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView().environmentObject(appDelegate)
        }
    }

}

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
            Button("Open Advanced Settings…") {
                openSettings()
            }.buttonStyle(MenuButtonStyle())
                .font(Font(NSFont.menuFont(ofSize: NSFont.systemFontSize)))  // Используем системный шрифт меню
        }
        .padding(.horizontal, 5)
    }
}


struct SettingsView: View {
    @AppStorage(settingsIpFieldName) private var ipAddress: String = ""
    @AppStorage(settingsPortFieldName) private var port: String = ""

    @EnvironmentObject var appDelegate: AppDelegate

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 10) {

            Form {
                Section("Connection settings") {

                    TextField("IP Address", text: $ipAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Port", text: $port)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }

            Spacer()  // Отталкивает кнопки вниз

            HStack {
                Spacer()  // Отталкивает кнопки вправо

                Button("Cancel") {
                    dismiss()
                }

                Button("OK") {
                    print("Сохранено: IP = \(ipAddress), Port = \(port)")

                    appDelegate.updateSettings(ipAddress: ipAddress, port: port)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)  // Enter = OK
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}



class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject, UDPListener {
    private var statusItem: NSStatusItem?
    var udpReceiver: UDPReceiver?



    private var settings = AppSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        createMenu([])
        
        udpReceiver = UDPReceiver(port: 9999)
        udpReceiver?.delegate = self
    }
    
    func handleResponse(data: Data) {
        if let dataString = String(data: data, encoding: .utf8) {
            statusItem?.button?.title = dataString
        }
    }
    
    private func createMenu(_ data: [(String, String)]) {
        let menu = NSMenu()

        for (left, right) in data {
            let menuItem = NSMenuItem()
            let hostingView = NSHostingView(
                rootView: MunuItemView(title: left, value: right))
            hostingView.setFrameSize(hostingView.intrinsicContentSize)

            menuItem.view = hostingView

            menu.addItem(menuItem)
        }

        // Разделитель
        menu.addItem(NSMenuItem.separator())

        let menuItem = NSMenuItem()
        let hostingView = NSHostingView(rootView: AdvancedSettingsButton())
        hostingView.setFrameSize(hostingView.intrinsicContentSize)
        menuItem.view = hostingView

        menu.addItem(menuItem)

        menu.addItem(
            NSMenuItem(
                title: "Quit iStatus", action: #selector(quit),
                keyEquivalent: ""))

        statusItem?.menu = nil
        statusItem?.menu = menu
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength)

        statusItem?.button?.title = "0'C"
    }

   
    @objc func quit() {
        NSApp.terminate(nil)
    }

    func updateSettings(ipAddress: String, port: String) {
        settings.ipAddress = ipAddress
        settings.portString = port
        print("updateSettings \(ipAddress) \(port)")

        // startUDPClient()
    }
}

@ViewBuilder
func MunuItemView(title: String, value: String) -> some View {
    HStack {
        Text(title)
            .bold()
        Spacer()
        Text(value)  // TODO: можно реактивно менять через ObservableObject
            .opacity(0.75)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 4)
    .padding(.top, 4)

    .frame(minWidth: 200)
}
