
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa

class ServiceManager: NSObject {
    static let sharedServiceManager = ServiceManager()
    
    override init() {
        super.init()
        
        // register SDApplicationEventProtocol notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(SDApplicationEventProtocol.applicationDidConfigureRealm), name: Notification.Name.applicationDidConfigureRealm, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDApplicationEventProtocol.applicationDidConfigureClient), name: Notification.Name.applicationDidConfigureClient, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDApplicationEventProtocol.applicationDidConfigureUser), name: Notification.Name.applicationDidConfigureUser, object: nil)
        
        self.serviceLoop()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    var serviceStatus: Bool {
        guard let _ = SMJobCopyDictionary(kSMDomainUserLaunchd, ("io.safedrive.SafeDrive.Service" as CFString)) else {
            return false
        }
        return true
        
    }
    
    fileprivate func serviceLoop() {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {() -> Void in
            while true {
                let serviceStatus: Bool = self.serviceStatus
                DispatchQueue.main.async(execute: {() -> Void in
                    NotificationCenter.default.post(name: Notification.Name.serviceStatus, object: serviceStatus)
                })
                Thread.sleep(forTimeInterval: 1)
            }
        })
    }
    
    func loadService() {
        let servicePlist: URL = Bundle.main.url(forResource: "io.safedrive.SafeDrive.Service", withExtension: "plist")!
        let jobDict = NSDictionary(contentsOfFile: servicePlist.path)
        var jobError: Unmanaged<CFError>? = nil
        
        if !SMJobSubmit(kSMDomainUserLaunchd, jobDict!, nil, &jobError) {
            if let error = jobError?.takeRetainedValue() {
                SDLog("Load service error: \(error)")
                SDErrorHandlerReport(error)
                
            }
        }
    }
    
    func unloadService() {
        var jobError: Unmanaged<CFError>? = nil
        if !SMJobRemove(kSMDomainUserLaunchd, ("io.safedrive.SafeDrive.Service" as CFString), nil, true, &jobError) {
            if let error = jobError?.takeRetainedValue() {
                SDLog("Unload service error: \(error)")
                SDErrorHandlerReport(error)
            }
        }
    }
}

extension ServiceManager: SDApplicationEventProtocol {
    func applicationDidConfigureRealm(notification: Notification) {
        
    }
    
    func applicationDidConfigureClient(notification: Notification) {
        guard let uniqueClientID = notification.object as? String else {
            SDLog("API contract invalid: applicationDidConfigureClient in ServiceManager")
            
            return
        }
        
    }
    
    func applicationDidConfigureUser(notification: Notification) {
        guard let user = notification.object as? User else {
            SDLog("API contract invalid: applicationDidConfigureUser in ServiceManager")
            
            return
        }
    }
}
