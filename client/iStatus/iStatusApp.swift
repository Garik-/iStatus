import AppKit
import SwiftUI



@main
struct iStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView().environmentObject(appDelegate)
        }
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
        menu.addItem(createDataMenuItem(addData))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createSettingsMenuItem())

        menu.addItem(
            NSMenuItem(
                title: "Quit iStatus", action: #selector(quit),
                keyEquivalent: ""))

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
