
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
            while true {
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

        let serviceDestinationURL = safeDriveApplicationSupportURL!.URLByAppendingPathComponent("SafeDriveService.app", isDirectory: true)

        let serviceSourceURL = NSBundle.mainBundle().bundleURL.URLByAppendingPathComponent("Contents/PlugIns/SafeDriveService.app", isDirectory: true)!

        // copy launch agent to ~/Library/LaunchAgents/
        let launchAgentDestinationURL = launchAgentsURL!.URLByAppendingPathComponent("io.safedrive.SafeDrive.Service.plist", isDirectory: false)!
        let launchAgentSourceURL: NSURL = NSBundle.mainBundle().URLForResource("io.safedrive.SafeDrive.Service", withExtension: "plist")!
        if NSFileManager.defaultManager().fileExistsAtPath(launchAgentDestinationURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(launchAgentDestinationURL)
            } catch let error as NSError {
                SDLog("Error removing old launch agent: \(error)")
                SDErrorHandlerReport(error)
            }
        }
        do {
            try fileManager.copyItemAtURL(launchAgentSourceURL, toURL: launchAgentDestinationURL)
        } catch let error as NSError {
            SDLog("Error copying launch agent: \(error)")
            SDErrorHandlerReport(error)
        }

        // copy background service to ~/Library/Application Support/SafeDrive/
        do {
            try fileManager.createDirectoryAtURL(safeDriveApplicationSupportURL!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            SDLog("Error creating support directory: \(error)")
            SDErrorHandlerReport(error)
        }

        if fileManager.fileExistsAtPath(serviceDestinationURL!.path!) {
            do {
                try fileManager.removeItemAtURL(serviceDestinationURL!)
            } catch let error as NSError {
                SDLog("Error removing old service: \(error)")
                SDErrorHandlerReport(error)
            }
        }
        do {
            try fileManager.copyItemAtURL(serviceSourceURL, toURL: serviceDestinationURL!)
        } catch let error as NSError {
            SDLog("Error copying service: \(error)")
            SDErrorHandlerReport(error)
        }

    }

    func loadService() {
        let servicePlist: NSURL = NSBundle.mainBundle().URLForResource("io.safedrive.SafeDrive.Service", withExtension: "plist")!
        let jobDict = NSDictionary(contentsOfFile: servicePlist.path!)
        var jobError: Unmanaged<CFError>? = nil

        if !SMJobSubmit(kSMDomainUserLaunchd, jobDict!, nil, &jobError) {
            if let error = jobError?.takeRetainedValue() as NSError? {
                SDLog("Load service error: \(error)")
                SDErrorHandlerReport(error)
            }
        }
    }

    func unloadService() {
        var jobError: Unmanaged<CFError>? = nil
        if !SMJobRemove(kSMDomainUserLaunchd, ("io.safedrive.SafeDrive.Service" as CFString), nil, true, &jobError) {
            if let error = jobError?.takeRetainedValue() as NSError? {
                SDLog("Unload service error: \(error)")
                SDErrorHandlerReport(error)
            }
        }
    }
}
