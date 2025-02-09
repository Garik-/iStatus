//
//  UDPReceiver.swift
//  iStatus
//
//  Created by Гарик Джан on 09.02.2025.
//

import Foundation
import Network

protocol UDPListener {
    func handleResponse(data: Data)
}

class UDPReceiver {
    private var listener: NWListener?
    var delegate: UDPListener?

    init(port: UInt16) {
        print("init UDPReceiver on \(port)")

        do {
            listener = try NWListener(
                using: .udp, on: NWEndpoint.Port(rawValue: port)!)
        } catch {
            print("Failed to create listener: \(error)")
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in

            print("newConnectionHandler")

            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    print("State: Ready")

                    self?.receive(connection)
                    return
                case .setup:
                    print("State: Setup")
                case .cancelled:
                    print("State: Cancelled")
                case .preparing:
                    print("State: Preparing")
                default:
                    print("ERROR! State not defined!\n")
                }
            }

            connection.start(queue: .main)
        }

        listener?.start(queue: .main)
        print("Listener started.")
    }

    func receive(_ connection: NWConnection) {
        connection.receiveMessage {
            [weak self] data, context, isComplete, error in
            print("Receive isComplete: " + isComplete.description)
            guard let data = data else {
                print("Error: Received nil Data")
                return
            }

            guard self?.delegate != nil else {
                print("Error: UDPClient response handler is nil")
                return
            }

            self?.delegate?.handleResponse(data: data)
            // print(String(data: data, encoding: .utf8))

            connection.cancel()
        }
    }

    deinit {
        print("destroy UDPReceiver")
        listener?.cancel()
    }
}
