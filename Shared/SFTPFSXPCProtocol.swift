//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Foundation

let kSFTPFSXPCProtocolVersion: Int = 7

@objc protocol SFTPFSXPCProtocol {
    func create(_ mountpoint: String,
                label: String,
                user: String,
                password: String,
                host: String,
                port: UInt16)
    
    func connect()
    
    func disconnect()
    
    func setIcon(_ url: URL)

    func useCache(reply replyBlock: @escaping (Bool) -> Void)
    
    func setUseCache(_ state: Bool)
    
    func connected(reply replyBlock: @escaping (Bool) -> Void)
    
    func connecting(reply replyBlock: @escaping (Bool) -> Void)
    
    func setMountpoint(_ mountpoint: String)
    
    func setSFTPFingerprints(_ fingerprints: [String])
}
