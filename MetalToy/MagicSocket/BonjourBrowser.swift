//
//  BonjourBrowser.swift
//  MagicSocket
//
//  Created by Chris Zelazo on 7/31/19.
//  Copyright © 2019 Pinterest ACT. All rights reserved.
//

import Foundation

@objc enum BrowserOperation: Int {
    case searchStopped
    case didNotSearch
    case notResolved
}

@objc protocol BonjourBrowserDelegate {
    func browser(browser: BonjourBrowser, didFailedAt operation: BrowserOperation, withErrorDict errorDict: [String: NSNumber]?)
    func browser(browser: BonjourBrowser, didFindService service: NetService, atHosts host: [String])
    func browser(browser: BonjourBrowser, didRemovedService service: NetService)
    
    @objc optional func browserDidStart(browser: BonjourBrowser)
    @objc optional func browserDidStopped(browser: BonjourBrowser)
    @objc optional func browser(browser: BonjourBrowser, serviceDidUpdateTXT service: NetService, TXT txt: NSData)
}

class BonjourBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private let svr = NetServiceBrowser()
    
    public let type: String
    public let proto: String
    public let domain: String
    
    weak var delegate: BonjourBrowserDelegate?
    
    var services = Set<NetService>()
    
    init(type: String, proto: String, domain: String = "") {
        self.type = type
        self.proto = proto
        self.domain = domain
        
        super.init()
        
        svr.delegate = self
    }
    
    func start() {
        svr.searchForServices(ofType: "_\(type)._\(proto)", inDomain: domain)
        svr.schedule(in: .current, forMode: .default)
    }
    
    func stop() {
        svr.stop()
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        self.services.remove(service)
    }
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        delegate?.browserDidStart?(browser: self)
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        delegate?.browserDidStopped?(browser: self)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        delegate?.browser(browser: self, didFailedAt: .didNotSearch, withErrorDict: errorDict)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        service.resolve(withTimeout: 0.0)
        service.schedule(in: .current, forMode: .default)
        
        services.insert(service)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses else {
            return
        }
        
        let ips: [String] = addresses.compactMap { address in
            var addr = address
            let ptr: sockaddr_in = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    $0.pointee
                }
            }
            return String(cString: inet_ntoa(ptr.sin_addr), encoding: .ascii)
        }
        delegate?.browser(browser: self, didFindService: sender, atHosts: ips)
    }
    
    func netService(sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        delegate?.browser(browser: self, didFailedAt: .notResolved, withErrorDict: errorDict)
    }
    
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        delegate?.browser?(browser: self, serviceDidUpdateTXT: sender, TXT: data as NSData)
    }
}
