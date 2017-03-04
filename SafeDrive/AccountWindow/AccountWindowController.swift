
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

// swiftlint:disable force_cast


import Cocoa

import SafeDriveSDK

extension AccountWindowController: OpenFileWarningDelegate {
    func closeApplication(_ process: RunningProcess) {
        SDLog("attempting to close \(process.command) (\(process.pid))")
        
        if process.isUserApplication {
            for app in NSWorkspace.shared().runningApplications {
                if process.pid == Int(app.processIdentifier) {
                    SDLog("found \(process.pid), terminating")
                    app.terminate()
                }
            }
        } else {
            let r = RunningProcessCheck()
            r.close(pid: process.pid)
        }
    }
    
    func runningProcesses() -> [RunningProcess] {
        SDLog("checking running processes")
        let r = RunningProcessCheck()

        return r.runningProcesses()
    }
    
    func blockingProcesses(_ url: URL) -> [RunningProcess] {
        SDLog("checking blocking processes")
        let c = OpenFileCheck()

        return c.check(volume: url)
    }
    
    func tryAgain() {
        self.disconnectVolume(askForOpenApps: false)
    }
    
    func finished() {
        //self.openFileWarning?.window?.close()
        //self.openFileWarning = nil
    }
}

extension AccountWindowController: SleepReactor {
    func willSleep(_ notification: Notification) {
        if self.mountController.mounted {
            SDLog("machine going to sleep, unmounting SSHFS")
            self.disconnectVolume(askForOpenApps: true)
        }
    }
}

class AccountWindowController: NSWindowController, SDMountStateProtocol, SDVolumeEventProtocol {
    
    var sdk = SafeDriveSDK.sharedSDK
    var mountController = MountController.shared
    var sharedSystemAPI = SDSystemAPI.shared()
    
    var accountController = AccountController.sharedAccountController
    
    @IBOutlet var emailField: NSTextField!
    @IBOutlet var passwordField: NSTextField!
    @IBOutlet var volumeNameField: NSTextField!
    
    @IBOutlet var errorField: NSTextField!
    
    @IBOutlet var spinner: NSProgressIndicator!
    
    var currentlyDisplayedError: NSError?
    
    fileprivate var openFileWarning: OpenFileWarningWindowController?

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    convenience init() {
        self.init(windowNibName: "AccountWindow")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        let window = self.window as! FlatWindow
        
        window.keepOnTop = true
        
        self.passwordField.focusRingType = .none
        
        // reset error field to empty before display
        self.resetErrorDisplay()
        
        // register SDMountStateProtocol notifications
        NotificationCenter.default.addObserver(self, selector: #selector(SDMountStateProtocol.mountStateMounted), name: Notification.Name.mounted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDMountStateProtocol.mountStateUnmounted), name: Notification.Name.unmounted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDMountStateProtocol.mountStateDetails), name: Notification.Name.mountDetails, object: nil)
        // register SDVolumeEventProtocol notifications
        NotificationCenter.default.addObserver(self, selector: #selector(SDVolumeEventProtocol.volumeDidMount), name: Notification.Name.volumeDidMount, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDVolumeEventProtocol.volumeDidUnmount), name: Notification.Name.volumeDidUnmount, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDVolumeEventProtocol.volumeShouldUnmount), name: Notification.Name.volumeShouldUnmount, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDVolumeEventProtocol.volumeShouldMount), name: Notification.Name.volumeShouldMount, object: nil)
        
        
        let nc = NSWorkspace.shared().notificationCenter
        nc.addObserver(self, selector: #selector(willSleep(_:)), name: Notification.Name.NSWorkspaceWillSleep, object: nil)
        
    }
    
    @IBAction func signIn(_ sender: AnyObject) {
        self.resetErrorDisplay()
        
        let e: NSError = NSError(domain: SDErrorDomain, code: SDErrorNone, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Signing in to SafeDrive", comment: "String informing the user that they are being signed in to SafeDrive")])
        
        
        self.displayError(e, forDuration: 120)
        self.spinner.startAnimation(self)
        
        self.accountController.signInWithSuccess({() -> Void in
            self.resetErrorDisplay()
            self.spinner.stopAnimation(self)
            
            // only mount SSHFS automatically if the user set it to automount or clicked the button, in which case sender will
            // be the NSButton in the account window labeled "next"
            
            if self.mountController.automount || sender is NSButton {
                self.mountController.checkMount(at: self.mountController.currentMountURL, timeout: 30, mounted: {

                }, notMounted: {
                    self.connectVolume()
                })
            }
        }, failure: {(apiError: SDKError) -> Void in
            switch apiError.kind {
            case .StateMissing:
                break
            case .Internal:
                break
            case .RequestFailure:
                break
            case .NetworkFailure:
                break
            case .Conflict:
                break
            case .BlockMissing:
                break
            case .SessionMissing:
                break
            case .RecoveryPhraseIncorrect:
                break
            case .InsufficientFreeSpace:
                break
            case .Authentication:
                break
            case .UnicodeError:
                break
            case .TokenExpired:
                break
            case .CryptoError:
                break
            case .IO:
                break
            case .SyncAlreadyInProgress:
                break
            case .RestoreAlreadyInProgress:
                break
            case .ExceededRetries:
                break
            case .KeychainError:
                break
            case .BlockUnreadable:
                break
            case .SessionUnreadable:
                break
            case .ServiceUnavailable:
                break
            case .Cancelled:
                break
            }

            let ns = NSError(domain: SDErrorUIDomain, code: apiError.kind.rawValue, userInfo: [NSLocalizedDescriptionKey: apiError.message])
            
            SDErrorHandlerReport(ns)
            
            self.displayError(ns, forDuration: 10)
            self.spinner.stopAnimation(self)
            self.showWindow(nil)
        })
    }
    
    // MARK: Internal API
    
    func connectVolume() {
        self.resetErrorDisplay()
        self.mountController.mounting = true
        let displayMessage = NSError(domain: SDErrorDomain, code: SDErrorNone, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Mounting SafeDrive", comment: "String informing the user their safedrive is being mounted")])
        self.displayError(displayMessage, forDuration: 120)
        self.spinner.startAnimation(self)
        
        var urlComponents = URLComponents()
        urlComponents.user = self.accountController.internalUserName
        urlComponents.host = self.accountController.remoteHost
        urlComponents.path = SDDefaultServerPath
        urlComponents.port = Int(self.accountController.remotePort!)
        let sshURL: URL = urlComponents.url!
        
        self.mountController.startMountTask(sshURL: sshURL, success: { mountURL in
            
            /*
             now check for a successful mount. if after 30 seconds there is no volume
             mounted, it is a fair bet that an error occurred in the meantime
             */
            
            self.mountController.checkMount(at: mountURL, timeout: 30, mounted: {
                NotificationCenter.default.post(name: Notification.Name.volumeDidMount, object: nil)
                self.resetErrorDisplay()
                self.spinner.stopAnimation(self)
                self.mountController.mounting = false
            }, notMounted: {
                SDLog("SafeDrive checkForMountedVolume failure in account window")
                let error = NSError(domain:SDErrorDomain, code:SDSSHError.timeout.rawValue, userInfo:[NSLocalizedDescriptionKey: "Volume mount timeout"])
                self.displayError(error as NSError, forDuration: 10)
                self.spinner.stopAnimation(self)
                self.mountController.mounting = false
            })
            
            
        }, failure: { (_, mountError) in
            SDLog("SafeDrive startMountTaskWithVolumeName failure in account window")
            SDErrorHandlerReport(mountError)
            self.displayError(mountError as NSError, forDuration: 10)
            self.spinner.stopAnimation(self)
            self.mountController.mounting = false
            // NOTE: This is a workaround for an issue in SSHFS where a volume can both fail to mount but still end up in the mount table
            self.mountController.unmount(success: { _ in
                //
            }, failure: { (_, _) in
                //
            })
        })
    }
    
        
    fileprivate func disconnectVolume(askForOpenApps: Bool) {
        let volumeName: String = self.mountController.currentVolumeName
        SDLog("Dismounting volume: %@", volumeName)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
            self.mountController.unmount(success: { _ -> Void in
                //
            }, failure: { (url, error) -> Void in
                
                let message = "SafeDrive could not be unmounted\n\n \(error.localizedDescription)"
                
                SDLog(message)
                
                let notification = NSUserNotification()
                
                notification.title = "SafeDrive unmount failed"
                notification.informativeText = NSLocalizedString("Please close any open files on your SafeDrive", comment: "")
                
                notification.soundName = NSUserNotificationDefaultSoundName
                
                NSUserNotificationCenter.default.deliver(notification)
                
                if askForOpenApps {
                    let c = OpenFileCheck()
                    
                    let processes = c.check(volume: url)
                    
                    if processes.count <= 0 {
                        return
                    }
                    DispatchQueue.main.async(execute: {() -> Void in
                        self.openFileWarning = OpenFileWarningWindowController(delegate: self, url: url, processes: processes)
                        
                        NSApp.activate(ignoringOtherApps: true)
                        
                        self.openFileWarning!.showWindow(self)
                    })
                    
                }
                
            })
        }
        
    }
    
    // MARK: Error display
    
    func resetErrorDisplay() {
        self.currentlyDisplayedError = nil
        self.errorField.stringValue = ""
    }
    
    func displayError(_ error: Swift.Error, forDuration duration: TimeInterval) {
        assert(Thread.isMainThread, "Error display called on background thread")
        self.currentlyDisplayedError = error as NSError
        NSApp.activate(ignoringOtherApps: true)
        self.errorField.stringValue = error.localizedDescription
        let fadedRed: NSColor = NSColor(calibratedRed: 1.0, green: 0.25098, blue: 0.25098, alpha: 0.73)
        let fadedBlue: NSColor = NSColor(calibratedRed: 0.25098, green: 0.25098, blue: 1.0, alpha: 0.73)
        if error._code > 0 {
            self.errorField.textColor = fadedRed
        } else {
            self.errorField.textColor = fadedBlue
        }
        weak var weakSelf: AccountWindowController? = self
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(duration) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {() -> Void in
            if self.currentlyDisplayedError == error as NSError {
                weakSelf?.resetErrorDisplay()
            }
        })
    }
    
    // MARK: SDVolumeEventProtocol methods
    
    
    func volumeDidMount(notification: Notification) {
        self.close()
        NSWorkspace.shared().open((self.mountController.mountURL)!)
        //var mountSuccess: NSError = NSError(domain: SDErrorDomain, code: SDErrorNone, userInfo: [NSLocalizedDescriptionKey: "Volume mounted"])
        //self.displayError(mountSuccess, forDuration: 10)
        
    }
    
    func volumeDidUnmount(notification: Notification) {
        //self.openFileWarning?.window?.close()
        //self.openFileWarning = nil
    }
    
    func volumeSubprocessDidTerminate(notification: Notification) {
    
    }
    
    func volumeShouldMount(notification: Notification) {
        self.connectVolume()
    }
    
    func volumeShouldUnmount(notification: Notification) {
        self.disconnectVolume(askForOpenApps: true)
    }
    
    // MARK: SDMountStateProtocol methods
    
    
    func mountStateMounted(notification: Notification) {
    
    }
    
    func mountStateUnmounted(notification: Notification) {
    
    }
    
    func mountStateDetails(notification: Notification) {
    
    }
}
