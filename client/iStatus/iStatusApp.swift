import AppKit
import SwiftUI
import Foundation


// {"temp":"34.6°C","cpu":"1.87%","mem":{"total":3882924,"used":471124,"available":3372412,"usage":"12.13%"}}

//   let packet = try? JSONDecoder().decode(Packet.self, from: jsonData)

// MARK: - Packet
struct Packet: Codable {
    let temp, cpu: String
    let mem: Mem
}

// MARK: - Mem
struct Mem: Codable {
    let total, used, available: Int
    let usage: String
}


var defaultTemp = "--.-'C"
var defaultPercent = "--.--%"

class AppData: ObservableObject {
    @Published var packet: Packet = Packet(
        temp: defaultTemp, cpu: defaultPercent,
        mem: Mem(
            total: 0, used: 0, available: 0,
            usage: defaultPercent
        )
    )
}

@main
struct iStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView().environmentObject(appDelegate)
        }
    }
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
        updateSettings(port: settings.portString)
    }
    
    func handleResponse(data: Data) {
        let pack = try? JSONDecoder().decode(Packet.self, from: data)
        
        statusItem?.button?.title = pack?.temp ?? defaultTemp
        addData.packet = pack!
        
        
        /*if let dataString = String(data: data, encoding: .utf8) {
            
            print(dataString) // TODO: sdsdf
            
            
            
            
            // addData.someText = dataString
            // statusItem?.button?.title = dataString
        }*/
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
        // TODO: addData set default object
        
        udpReceiver = UDPReceiver(port: settings.port)
        udpReceiver?.delegate = self
    }
}
