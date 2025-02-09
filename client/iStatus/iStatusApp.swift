import AppKit
import SwiftUI

let settingsPortFieldName = "port"
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
            Button("Open Settings…") {
                openSettings()
            }.buttonStyle(MenuButtonStyle())
                .font(Font(NSFont.menuFont(ofSize: NSFont.systemFontSize)))  // Используем системный шрифт меню
        }
        .padding(.horizontal, 5)
        //.frame(width: 200)
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
                    Text("Cancel").frame(width:buttonWidth)
                }

                Button(action: {
                    appDelegate.updateSettings(port: port)
                    dismiss()
                }) {
                    Text("OK").frame(width:buttonWidth)
                }

                .keyboardShortcut(.defaultAction)  // Enter = OK
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 300, height: 120)
    }
}

var defaultTemp = "--.-'C"

class AppData: ObservableObject {
    @Published var someText: String = "Initial Text"
    
    
}



class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject, UDPListener {
    private var statusItem: NSStatusItem?
    private var udpReceiver: UDPReceiver?
    private var settings = AppSettings()
    private var addData = AppData()

    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength)
        
        createMenu()
        
        self.updateSettings(port: settings.portString)
    }
    
    func handleResponse(data: Data) {
        if let dataString = String(data: data, encoding: .utf8) {
            
            print(dataString)
            addData.someText = dataString
            // statusItem?.button?.title = dataString
        }
    }
    
    private func createMenu() {
        let menu = NSMenu()

        
    let menuItem = NSMenuItem()
    let hostingView = NSHostingView(
            rootView: MunuItemView().environmentObject(addData) )
            hostingView.setFrameSize(hostingView.intrinsicContentSize)

            menuItem.view = hostingView

            menu.addItem(menuItem)
        

        // Разделитель
        menu.addItem(NSMenuItem.separator())

        
        let settingsItem = NSMenuItem()
        let settingsHostingView = NSHostingView(rootView: AdvancedSettingsButton())
        settingsHostingView.setFrameSize(settingsHostingView.intrinsicContentSize)
        settingsItem.view = settingsHostingView

        menu.addItem(settingsItem)

        menu.addItem(
            NSMenuItem(
                title: "Quit iStatus", action: #selector(quit),
                keyEquivalent: ""))

        statusItem?.menu = nil
        statusItem?.menu = menu
    }
   
    @objc func quit() {
        NSApp.terminate(nil)
    }

    func updateSettings(port: String) {
        settings.portString = port
        
        udpReceiver = nil
        statusItem?.button?.title = defaultTemp
        
        udpReceiver = UDPReceiver(port: settings.port)
        udpReceiver?.delegate = self
    }
}


struct MunuItemView: View {
    @EnvironmentObject var data: AppData
    
    var body: some View {
        VStack {
            HStack {
                Text("test")
                    .bold()
                Spacer()
                Text("test")
                    .opacity(0.75)
            }
            Text(data.someText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .padding(.top, 4)
        
        .frame(minWidth: 200)
    }
}
