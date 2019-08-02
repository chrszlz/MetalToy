//
//  MagicSocket.swift
//  MagicSocket
//
//  Created by Chris Zelazo on 7/31/19.
//  Copyright © 2019 Pinterest ACT. All rights reserved.
//

import Foundation
import UIKit
import SocketIO

public protocol MagicSocketDelegate {
    func socket(recieved event: SocketClientEvent)
}

// Simple object for automatically connecting to SocketIO
// with a specified id.
open class MagicSocket: NSObject {
    
    // Debug mode enables verbose logging.
    private static let isDebug: Bool = true
    
    // Setting this overrides and rebuilds the socket connection.
    // This also stops bonjour services, if running.
    // By default, bonjour will provide the host.
    public var hostUrl: URL? {
        get {
            return manager?.socketURL
        }
        set {
            guard let url = newValue else {
                return
            }
            rebuildSocketConnection(with: url)
        }
    }
    
    public var delegate: MagicSocketDelegate?
    
    /// Sockets
    
    private var manager: SocketManager?
    
    public private(set) var socket: SocketIOClient?
    
    /// Bonjour
    
    private let bonjourBrowser: BonjourBrowser
    
    public init(_ type: String, proto: String) {
        bonjourBrowser = BonjourBrowser(type: type, proto: proto)
        
        super.init()
        
        bonjourBrowser.delegate = self
    }
    
    // MARK: - Control
    
    // Begins bonjour browsing and socket connection
    public func start() {
        bonjourBrowser.start()
    }
    
    // Stops all services and disconnects sockets.
    public func disconnect() {
        bonjourBrowser.stop()
        
        socket?.disconnect()
        manager?.disconnect()
    }
    
    deinit {
        disconnect()
    }
    
}

// MARK: - Bonjour

extension MagicSocket: BonjourBrowserDelegate {
    
    func browser(browser: BonjourBrowser, didFindService service: NetService, atHosts host: [String]) {
        guard var host = service.hostName else {
            return
        }
        
        if host.last == "." {
            host.removeLast()
        }
        
        let urlString = "http://\(host):\(service.port)"
        guard urlString != manager?.socketURL.absoluteString,
            let url = URL(string: urlString) else {
                return
        }
        rebuildSocketConnection(with: url)
    }
    
    func browser(browser: BonjourBrowser, didRemovedService service: NetService) {
        // no-op
    }
    
    func browser(browser: BonjourBrowser, didFailedAt operation: BrowserOperation, withErrorDict errorDict: [String : NSNumber]?) {
        // no-op
    }
    
}

// MARK: -  Sockets

extension MagicSocket {
    
    private func rebuildSocketConnection(with url: URL) {
        socket?.disconnect()
        socket = nil
        
        manager?.disconnect()
        manager = buildManager(with: url)
        guard let manager = manager else {
            assertionFailure(debugPrefix + "Unable to build SocketIO Manager")
            return
        }
        
        socket = buildSocketClient(with: manager)
        socket?.connect()
    }
    
    private func buildManager(with url: URL) -> SocketManager {
        return SocketManager(socketURL: url, config: [.log(true), .compress])
    }
    
    private func buildSocketClient(with manager: SocketManager) -> SocketIOClient {
        let socket = manager.defaultSocket
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            self?.debugPrint("Connected - \(data)")
            self?.bonjourBrowser.stop()
            self?.delegate?.socket(recieved: .connect)
        }
        socket.on(clientEvent: .reconnect) { [weak self] data, ack in
            self?.debugPrint("Reconnected - \(data)")
            self?.bonjourBrowser.stop()
            self?.delegate?.socket(recieved: .reconnect)
        }
        socket.on(clientEvent: .reconnectAttempt) { [weak self] data, ack in
            self?.debugPrint("Reconnect Attempt - \(data)")
            self?.delegate?.socket(recieved: .reconnectAttempt)
        }
        socket.on(clientEvent: .ping) { [weak self] data, ack in
            self?.debugPrint("Ping - \(data)")
            self?.delegate?.socket(recieved: .ping)
        }
        socket.on(clientEvent: .pong) { [weak self] data, ack in
            self?.debugPrint("Pong - \(data)")
            self?.delegate?.socket(recieved: .pong)
        }
        socket.on(clientEvent: .error) { [weak self] data, ack in
            self?.debugPrint("Disconnected - \(data)")
            self?.bonjourBrowser.start()
            self?.delegate?.socket(recieved: .error)
        }
        return socket
    }
    
    private func debugPrint(_ text: String) {
        guard MagicSocket.isDebug else { return }
        print(debugPrefix + text)
    }
    
    private var debugPrefix: String {
        return ">> " + bonjourBrowser.type + ": "
    }
    
}

