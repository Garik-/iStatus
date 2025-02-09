//
//  AppSettings.swift
//  iStatus
//
//  Created by Гарик Джан on 09.02.2025.
//

import AppKit

let settingsPortFieldName = "port"
let defaultPort = "9999"

class AppSettings {
    var portString: String =
        UserDefaults.standard.string(forKey: settingsPortFieldName)
        ?? defaultPort

    var port: UInt16 {
        // Преобразуем строку в UInt16
        return UInt16(portString) ?? 0
    }
}
