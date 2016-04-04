
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa

import Fabric
import Crashlytics

import RealmSwift
import Realm


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SDApplicationControlProtocol, SDAccountProtocol, CrashlyticsDelegate {
    private var dropdownMenuController: DropdownController!
    private var accountWindowController: AccountWindowController!
    private var preferencesWindowController: PreferencesWindowController!
    
    private var aboutWindowController: DCOAboutWindowController!
    private var serviceRouter: SDServiceXPCRouter!
    private var serviceManager: ServiceManager!
    private var syncManagerWindowController: SyncManagerWindowController?
    
    private var syncScheduler: SyncScheduler?
    private var installWindowController: InstallerWindowController?

    
    var CFBundleVersion = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String

    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSUserDefaults.standardUserDefaults().registerDefaults(["NSApplicationCrashOnExceptions": true])
        Crashlytics.sharedInstance().delegate = self
        Fabric.with([Crashlytics.self])
        
        // initialize error handler, from this point on SDLog() and SDErrorHandlerReport() should be safe to use
        SDErrorHandlerInitialize()
        SDLog("SafeDrive build \(CFBundleVersion)")

        
        PFMoveToApplicationsFolderIfNecessary()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SDApplicationControlProtocol.applicationShouldFinishConfiguration(_:)), name: SDApplicationShouldFinishConfiguration, object: nil)

        self.installWindowController = InstallerWindowController()
        _ = self.installWindowController!.window!

    }

    
    func applicationWillTerminate(aNotification: NSNotification) {
        SDLog("SafeDrive build \(CFBundleVersion), protocol version \(kSDAppXPCProtocolVersion) exiting")
        NSNotificationCenter.defaultCenter().postNotificationName(SDVolumeShouldUnmountNotification, object: nil)
        
    }
    
    // MARK: SDApplicationControlProtocol methods

    
    func applicationShouldOpenAccountWindow(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            NSApp.activateIgnoringOtherApps(true)
            self.accountWindowController.showWindow(nil)
        })
    }
    
    func applicationShouldOpenPreferencesWindow(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            NSApp.activateIgnoringOtherApps(true)
            self.preferencesWindowController.showWindow(nil)
        })
    }
    
    func applicationShouldOpenAboutWindow(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            NSApp.activateIgnoringOtherApps(true)
            self.aboutWindowController.showWindow(nil)
        })
    }
    
    func applicationShouldOpenSyncWindow(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            NSApp.activateIgnoringOtherApps(true)
            self.syncManagerWindowController?.showWindow(nil)
        })
    }
    
    func applicationShouldFinishConfiguration(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            
            guard let groupURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.io.safedrive.db") else {
                SDLog("Failed to obtain group container, this is a fatal error")
                Crashlytics.sharedInstance().crash()
                return
            }
            
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(groupURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                SDLog("Failed to create group container, this is a fatal error")
                Crashlytics.sharedInstance().crash()
            }
            
            self.serviceManager = ServiceManager.sharedServiceManager
            self.serviceManager.unloadService()

            let dbURL = groupURL.URLByAppendingPathComponent("sync.realm")
            let newdbURL = dbURL.URLByAppendingPathExtension("new")
            
            let config = Realm.Configuration(
                path: dbURL.path,
                // Set the new schema version. This must be greater than the previously used
                // version (if you've never set a schema version before, the version is 0).
                schemaVersion: 7,
                migrationBlock: { migration, oldSchemaVersion in
                    SDLog("Migrating db version \(oldSchemaVersion) to 7")
                    migration.enumerate(Machine.className()) { oldObject, newObject in
                        if oldSchemaVersion < 6 {
                            migration.delete(newObject!)
                        }
                    }
                    migration.enumerate(SyncFolder.className()) { oldObject, newObject in
                        if oldSchemaVersion < 6 {
                            migration.delete(newObject!)
                        }
                    }
                    migration.enumerate(SyncTask.className()) { oldObject, newObject in
                        if oldSchemaVersion < 6 {
                            migration.delete(newObject!)
                        }
                    }
            })
            
            Realm.Configuration.defaultConfiguration = config
            
            autoreleasepool {
                let fileManager = NSFileManager.defaultManager()
                
                do {
                    try fileManager.removeItemAtURL(newdbURL)
                }
                catch {
                    // ignored, file may not exist at all, but if it does and we can't remove it we'll crash next and get a report
                }
                let realm = try! Realm(path: dbURL.path!)
                try! realm.writeCopyToPath(newdbURL.path!)
                try! fileManager.removeItemAtURL(dbURL)
                try! fileManager.moveItemAtURL(newdbURL, toURL: dbURL)
            }

            self.serviceManager.deployService()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {() -> Void in
                self.serviceManager.loadService()
                self.serviceRouter = SDServiceXPCRouter()
            })
            self.syncScheduler = SyncScheduler.sharedSyncScheduler

            self.dropdownMenuController = DropdownController()
            
            self.accountWindowController = AccountWindowController()
            _ = self.accountWindowController.window!
            
            self.preferencesWindowController = PreferencesWindowController()
            _ = self.preferencesWindowController.window!
            
            
            self.aboutWindowController = DCOAboutWindowController()
            self.aboutWindowController.useTextViewForAcknowledgments = true
            let websiteURLPath: String = "https://\(SDWebDomain)"
            self.aboutWindowController.appWebsiteURL = NSURL(string: websiteURLPath)!

            
            // register SDApplicationControlProtocol notifications
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SDApplicationControlProtocol.applicationShouldOpenAccountWindow(_:)), name: SDApplicationShouldOpenAccountWindow, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SDApplicationControlProtocol.applicationShouldOpenPreferencesWindow(_:)), name: SDApplicationShouldOpenPreferencesWindow, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SDApplicationControlProtocol.applicationShouldOpenAboutWindow(_:)), name: SDApplicationShouldOpenAboutWindow, object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName(SDApplicationShouldOpenAboutWindow, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.applicationShouldOpenSyncWindow(_:)), name: SDApplicationShouldOpenSyncWindow, object: nil)
            
            // register SDAccountProtocol notifications
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SDAccountProtocol.didSignIn(_:)), name: SDAccountSignInNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SDAccountProtocol.didSignOut(_:)), name: SDAccountSignOutNotification, object: nil)
        })
    }
    
    // MARK: SDAccountProtocol
    
    func didSignIn(notification: NSNotification) {
        guard let uniqueClientID = notification.object as? String else {
            return
        }
        assert(NSThread.isMainThread(), "Not main thread!!!")
        self.syncScheduler!.running = true
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            do {
                try self.syncScheduler?.syncSchedulerLoop(uniqueClientID)
            }
            catch {
                SDLog("Error starting scheduler: \(error)")
                Crashlytics.sharedInstance().crash()
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.syncScheduler?.syncRunLoop()
        }
        self.syncManagerWindowController = SyncManagerWindowController(uniqueClientID: uniqueClientID)
        _ = self.syncManagerWindowController!.window!
    }
    
    func didSignOut(notification: NSNotification) {
        assert(NSThread.isMainThread(), "Not main thread!!!")
        self.syncScheduler?.stop()
        self.syncManagerWindowController?.close()
        self.syncManagerWindowController = nil
    }
    
    func didReceiveAccountDetails(notification: NSNotification) {
    }
    
    func didReceiveAccountStatus(notification: NSNotification) {
    }
    
    // MARK: CrashlyticsDelegate
    
    func crashlyticsDidDetectReportForLastExecution(report: CLSReport, completionHandler: (Bool) -> Void) {
        //
        // always submit the report to Crashlytics
        completionHandler(true)
        
        // show an alert telling the user a crash report was generated, allow them to opt out of seeing more alerts
        CrashAlert.show()
        
    }
    
}