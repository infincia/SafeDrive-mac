
//  Copyright (c) 2014 Infincia LLC. All rights reserved.
//

import Cocoa
import FinderSync

import Realm
import RealmSwift

class FinderSync: FIFinderSync {

    var appConnection: NSXPCConnection!
    var serviceConnection: NSXPCConnection!
    
    let dbURL: NSURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.io.safedrive.db")!.URLByAppendingPathComponent("sync.realm")

    
    var syncFolders: Results<SyncFolder> {
        return try! Realm().objects(SyncFolder)
    }
    
    var token: RealmSwift.NotificationToken?
    
    override init() {
        super.init()
        
        // Set up images for our badge identifiers. For demonstration purposes, this uses off-the-shelf images.
        FIFinderSyncController.defaultController().setBadgeImage(NSImage(named: NSImageNameStatusAvailable)!, label: "Idle", forBadgeIdentifier: "idle")
        FIFinderSyncController.defaultController().setBadgeImage(NSImage(named: NSImageNameStatusPartiallyAvailable)!, label: "Syncing", forBadgeIdentifier: "syncing")
        FIFinderSyncController.defaultController().setBadgeImage(NSImage(named: NSImageNameStatusUnavailable)!, label: "Error", forBadgeIdentifier: "error")
        
        FIFinderSyncController.defaultController().directoryURLs = Set<NSURL>()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {() -> Void in
            self.serviceReconnectionLoop()
        })
        
        var config = Realm.Configuration()
        
        config.path = dbURL.path
        
        Realm.Configuration.defaultConfiguration = config
        
        guard let realm = try? Realm() else {
            print("failed to create realm!!!")
            return
        }
        
        self.token = realm.objects(SyncFolder).addNotificationBlock { results, error in
            
            guard let results = results else {
                return
            }
            
            var s = [NSURL]()
            
            for folder in results {
                let u = folder.url!
                s.append(u)
                // force update of badges when top level folders change
                self.requestBadgeIdentifierForURL(u)
                
            }
            
            FIFinderSyncController.defaultController().directoryURLs = Set<NSURL>(s)
        
            
        }
        
    }
    
    // MARK: - Service handling
    
    func serviceReconnectionLoop() {
        for ;;  {
            //self.ensureServiceIsRunning()
            if (self.serviceConnection == nil) {
                self.serviceConnection = self.createServiceConnection()
                
                let service = self.serviceConnection.remoteObjectProxyWithErrorHandler { error in
                    NSLog("remote proxy error: %@", error)
                } as! SDServiceXPCProtocol

                service.ping({ reply in
                    print("Ping reply from service: \(reply)")

                })
            }
            if (self.appConnection == nil) {
                FIFinderSyncController.defaultController().directoryURLs = Set<NSURL>()
                let service = self.serviceConnection.remoteObjectProxyWithErrorHandler { error in
                    print("remote proxy error: \(error)")
                } as! SDServiceXPCProtocol
                
                service.getAppEndpoint({ endpoint in
                    self.appConnection = self.createAppConnectionFromEndpoint(endpoint)
                    
                    let app = self.appConnection.remoteObjectProxyWithErrorHandler() { error in
                        print("remote proxy error: \(error)")
                    } as! SDAppXPCProtocol
                    
                    app.ping({ reply -> Void in
                        //print("Ping reply from app: \(reply)");  
                    })
                })

            }
            NSThread.sleepForTimeInterval(1)
        }
    }
    
    func createServiceConnection() -> NSXPCConnection {
        let newConnection: NSXPCConnection = NSXPCConnection(machServiceName: "io.safedrive.SafeDrive.Service", options: NSXPCConnectionOptions(rawValue: 0))
        
        let serviceInterface: NSXPCInterface = NSXPCInterface(withProtocol:SDServiceXPCProtocol.self)
        
        newConnection.remoteObjectInterface = serviceInterface
        
        newConnection.interruptionHandler = {() -> Void in
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                //print("Service connection interrupted")
            })
        }
        
        newConnection.invalidationHandler = {() -> Void in
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                //print("Service connection invalidated")
                self.serviceConnection = nil
            })
        }
        
        newConnection.resume()
        return newConnection
    }
    
    func createAppConnectionFromEndpoint(endpoint: NSXPCListenerEndpoint) -> NSXPCConnection {
        let newConnection: NSXPCConnection = NSXPCConnection(listenerEndpoint: endpoint)
        
        let appInterface: NSXPCInterface = NSXPCInterface(withProtocol:SDAppXPCProtocol.self)
        
        newConnection.remoteObjectInterface = appInterface

        
        newConnection.interruptionHandler = {() -> Void in
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                //print("App connection interrupted")
                
            })
        }
        newConnection.invalidationHandler = {() -> Void in
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                //print("App connection invalidated")
                self.appConnection = nil
                
            })
        }
        newConnection.resume()
        return newConnection
        
    }

    // MARK: - Primary Finder Sync protocol methods

    override func beginObservingDirectoryAtURL(url: NSURL) {
        // The user is now seeing the container's contents.
        // If they see it in more than one view at a time, we're only told once.
        NSLog("beginObservingDirectoryAtURL: %@", url.filePathURL!)
    }


    override func endObservingDirectoryAtURL(url: NSURL) {
        // The user is no longer seeing the container's contents.
        NSLog("endObservingDirectoryAtURL: %@", url.filePathURL!)
    }
    
    override func requestBadgeIdentifierForURL(url: NSURL) {
        guard let syncFolder = self.syncFolderForURL(url) else {
            print("error")
            return
        }

        var fileAttributes: [NSObject : AnyObject]
        
        do {
            try fileAttributes = NSFileManager.defaultManager().attributesOfItemAtPath(url.path!)
            print("Modified: \((fileAttributes[NSFileModificationDate] as! NSDate))")
            print("Using \(syncFolder.path!) for \( url.path!) status")
        }
        catch {
            print("error: \(error)")
        }
        var badgeIdentifier: String
        if syncFolder.syncing {
            badgeIdentifier = "syncing"
        }
        else {
            badgeIdentifier = "idle"
        }
        FIFinderSyncController.defaultController().setBadgeIdentifier(badgeIdentifier, forURL: url)
        
    }

    // MARK: - Menu and toolbar item support

    override var toolbarItemName: String {
        return "SafeDrive"
    }

    override var toolbarItemToolTip: String {
        return "SafeDrive"
    }

    override var toolbarItemImage: NSImage {
        return NSImage(named: NSImageNameLockLockedTemplate)!
    }

    override func menuForMenuKind(menuKind: FIMenuKind) -> NSMenu {
        var m: NSMenu? = nil
        switch menuKind {
        case .ContextualMenuForItems:
            /* contextual menu for one or more files/directories */
            m = NSMenu()
            m!.addItemWithTitle("SafeDrive: Restore Items", action: "restoreItems:", keyEquivalent: "")
        case .ContextualMenuForContainer:
            /* contextual menu for the directory being displayed */
            m = NSMenu()
            m!.addItemWithTitle("SafeDrive: Restore Folder", action: "restoreItems:", keyEquivalent: "")
        case .ContextualMenuForSidebar:
            /* contextual menu for an item in the sidebar */
            break
        case .ToolbarItemMenu:
            m = NSMenu()
            m!.addItemWithTitle("SafeDrive Support", action: "support:", keyEquivalent: "")
            m!.addItemWithTitle("SafeDrive Sync Preferences", action: "openRestoreWindow:", keyEquivalent: "")
            m!.addItemWithTitle("SafeDrive Preferences Window", action: "openPreferencesWindow:", keyEquivalent: "")
        }
        return m!
    }

    @IBAction func support(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://safedrive.io/support")!)
    }
    
    @IBAction func restoreItems(sender: AnyObject) {
        var target: NSURL = FIFinderSyncController.defaultController().targetedURL()!
        var items: [AnyObject] = FIFinderSyncController.defaultController().selectedItemURLs()!
    }
    
    @IBAction func openRestoreWindow(sender: AnyObject) {
        let app = self.appConnection.remoteObjectProxyWithErrorHandler { error in
            print("remote proxy error: \(error)")
        } as! SDAppXPCProtocol
        
        app.displayRestoreWindowForURLs([])
    }
    
    @IBAction func openPreferencesWindow(sender: AnyObject) {
        let app = self.appConnection.remoteObjectProxyWithErrorHandler { error in
            print("remote proxy error: \(error)")
        } as! SDAppXPCProtocol
        
       app.displayPreferencesWindow()
    }
    
    func showMessage(title: String, withBody body: String) {
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            let alert: NSAlert = NSAlert()
            alert.messageText = title
            alert.addButtonWithTitle("OK")
            alert.informativeText = body
            alert.runModal()
        })
    }
    
    func syncFolderForURL(url: NSURL) -> SyncFolder? {
        for item: SyncFolder in self.syncFolders {
            
            let registeredPath: String = item.path!
            let testPath: String = url.path!
            let options: NSStringCompareOptions = [.AnchoredSearch, .CaseInsensitiveSearch]
            
            // check if testPath is contained by this sync folder
            if testPath.rangeOfString(registeredPath, options: options) != nil {
                return item
            }
        }
        return nil
    }

}
