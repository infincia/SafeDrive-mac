//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Foundation

let kServiceXPCProtocolVersion: Int = 4

@objc protocol ServiceXPCProtocol {
    func sendMessage(_ message: String, reply replyBlock: @escaping (_ reply: String) -> Void)
    func ping(_ replyBlock: @escaping (_ reply: String) -> Void)
    func protocolVersion(_ replyBlock: @escaping (_ version: Int) -> Void)
    func sendAppEndpoint(_ endpoint: NSXPCListenerEndpoint, reply replyBlock: @escaping (_ success: Bool) -> Void)
    func getAppEndpoint(_ replyBlock: @escaping (_ endpoint: NSXPCListenerEndpoint) -> Void)
    func addFinderConnection(_ endpoint: NSXPCListenerEndpoint, reply replyBlock: @escaping (_ success: Bool) -> Void)

    func didSignIn()
    func didSignOut()
    
    func applicationDidConfigureUser(_ email: String)
    func applicationDidConfigureClient(_ uniqueClientID: String)
    
    func syncEvent(_ folderID: UInt64)
    
    func mountStateMounted()
    func mountStateUnmounted()
}
