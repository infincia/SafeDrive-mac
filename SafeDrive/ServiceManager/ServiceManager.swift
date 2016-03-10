
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa

class ServiceManager: NSObject {
    static let sharedServiceManager = ServiceManager()
    
    override init() {
        super.init()
        self.serviceLoop()
    }
    
    
    var serviceStatus: Bool {
        get {
            guard let _ = SMJobCopyDictionary(kSMDomainUserLaunchd, ("io.safedrive.SafeDrive.Service" as CFString)) else {
                return false
            }
            return true
        }
    }
    
    private func serviceLoop() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {() -> Void in
            for ; ;  {
                let serviceStatus: Bool = self.serviceStatus
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(SDServiceStatusNotification, object: serviceStatus)
                })
                NSThread.sleepForTimeInterval(1)
            }
        })
    }

    
    func deployService() {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        
        let libraryURL = try! fileManager.URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        
        let launchAgentsURL = libraryURL.URLByAppendingPathComponent("LaunchAgents", isDirectory: true)

        let applicationSupportURL = try! fileManager.URLForDirectory(.ApplicationSupportDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

        let safeDriveApplicationSupportURL = applicationSupportURL.URLByAppendingPathComponent("SafeDrive", isDirectory: true)
        
        let serviceDestinationURL = safeDriveApplicationSupportURL.URLByAppendingPathComponent("SafeDriveService.app", isDirectory: true)
        
        let serviceSourceURL = NSBundle.mainBundle().URLForResource("SafeDriveService", withExtension: "app", subdirectory: "../PlugIns")!
        
        // copy launch agent to ~/Library/LaunchAgents/
        let launchAgentDestinationURL = launchAgentsURL.URLByAppendingPathComponent("io.safedrive.SafeDrive.Service.plist", isDirectory: false)
        let launchAgentSourceURL: NSURL = NSBundle.mainBundle().URLForResource("io.safedrive.SafeDrive.Service", withExtension: "plist")!
        if NSFileManager.defaultManager().fileExistsAtPath(launchAgentDestinationURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(launchAgentDestinationURL)
            }
            catch {
                SDErrorHandlerReport(((error as Any) as! NSError))
                SDLog("Error removing old launch agent: \(error)")
            }
        }
        do {
            try fileManager.copyItemAtURL(launchAgentSourceURL, toURL: launchAgentDestinationURL)
        }
        catch {
            SDErrorHandlerReport(((error as Any) as! NSError))
            SDLog("Error copying launch agent: \(error)")
        }

        // copy background service to ~/Library/Application Support/SafeDrive/
        do {
            try fileManager.createDirectoryAtURL(safeDriveApplicationSupportURL, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            SDErrorHandlerReport(((error as Any) as! NSError))
            SDLog("Error creating support directory: \(error)")
        }

        if fileManager.fileExistsAtPath(serviceDestinationURL.path!) {
            do {
                try fileManager.removeItemAtURL(serviceDestinationURL)
            }
            catch {
                SDErrorHandlerReport(((error as Any) as! NSError))
                SDLog("Error removing old service: \(error)")
            }
        }
        do {
            try fileManager.copyItemAtURL(serviceSourceURL, toURL: serviceDestinationURL)
        }
        catch {
            SDErrorHandlerReport(((error as Any) as! NSError))
            SDLog("Error copying service: \(error)")
        }

    }
    
    func loadService() {
        let servicePlist: NSURL = NSBundle.mainBundle().URLForResource("io.safedrive.SafeDrive.Service", withExtension: "plist")!
        let jobDict = NSDictionary(contentsOfFile: servicePlist.path!)
        let jobError: UnsafeMutablePointer<Unmanaged<CFError>?> = nil

        if !SMJobSubmit(kSMDomainUserLaunchd, jobDict!, nil, jobError) {
            if let error = jobError.memory?.takeRetainedValue() {
                SDErrorHandlerReport(((error as Any) as! NSError))
                SDLog("Load service error: \(error)")
            }
        }
    }
    
    func unloadService() {
        let jobError: UnsafeMutablePointer<Unmanaged<CFError>?> = nil
        if !SMJobRemove(kSMDomainUserLaunchd, ("io.safedrive.SafeDrive.Service" as CFString), nil, false, jobError) {
            if let error = jobError.memory?.takeRetainedValue() {
                SDErrorHandlerReport(((error as Any) as! NSError))
                SDLog("Unload service error: \(error)")
            }
        }
    }
}
