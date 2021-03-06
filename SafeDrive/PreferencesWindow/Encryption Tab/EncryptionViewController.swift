
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa

class EncryptionViewController: NSViewController {
    
    fileprivate let sdk = SafeDriveSDK.sharedSDK
    
    fileprivate var recoveryPhraseEntry: RecoveryPhraseWindowController!
    
    fileprivate weak var delegate: PreferencesViewDelegate!

    fileprivate var uniqueClientID: String?
    fileprivate var uniqueClientName: String?

    @IBOutlet fileprivate var copyRecoveryPhraseButton: NSButton!
    
    @IBOutlet fileprivate var recoveryPhraseField: NSTextField!
    
    @IBOutlet fileprivate var enterRecoveryPhraseButton: NSButton!

    var email: String?

    fileprivate let loadKeysQueue = DispatchQueue(label: "io.safedrive.loadKeysQueue")

    var _lastLoadKeysError: SDError?
    
    var lastLoadKeysError: SDError? {
        get {
            var s: SDError?
            loadKeysQueue.sync {
                s = self._lastLoadKeysError
            }
            return s
        }
        set (newValue) {
            loadKeysQueue.sync(flags: .barrier, execute: {
                self._lastLoadKeysError = newValue
            })
        }
    }
    
    override func viewDidLoad() {
        if #available(OSX 10.10, *) {
            super.viewDidLoad()
        } else {
            // Fallback on earlier versions
        }
        // Do view setup here.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(delegate: PreferencesViewDelegate) {

        self.init(nibName: NSNib.Name(rawValue: "EncryptionView"), bundle: nil)

            
        self.recoveryPhraseEntry = RecoveryPhraseWindowController(delegate: self)

        self.delegate = delegate

        // register SDAccountProtocol notifications
        NotificationCenter.default.addObserver(self, selector: #selector(SDAccountProtocol.didSignIn), name: Notification.Name.accountSignIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDAccountProtocol.didSignOut), name: Notification.Name.accountSignOut, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDAccountProtocol.didReceiveAccountStatus), name: Notification.Name.accountStatus, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDAccountProtocol.didReceiveAccountDetails), name: Notification.Name.accountDetails, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SDAccountProtocol.didRequireRecoveryPhrase), name: Notification.Name.accountNeedsRecoveryPhrase, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDAccountProtocol.didLoadRecoveryPhrase), name: Notification.Name.accountLoadedRecoveryPhrase, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDAccountProtocol.didCreateRecoveryPhrase), name: Notification.Name.accountCreatedRecoveryPhrase, object: nil)
        
        // register SDApplicationEventProtocol notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(SDApplicationEventProtocol.applicationDidConfigureClient), name: Notification.Name.applicationDidConfigureClient, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDApplicationEventProtocol.applicationDidConfigureUser), name: Notification.Name.applicationDidConfigureUser, object: nil)
    }
    
    @IBAction func copyRecoveryPhrase(_ sender: AnyObject) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.writeObjects([recoveryPhraseField.stringValue as NSString])
    }
    
    @IBAction func enterRecoveryPhrase(_ sender: AnyObject) {
        guard let w = self.recoveryPhraseEntry?.window else {
            SDLogError("EncryptionViewController", "No recovery phrase window available")
            
            let error = SDKError(message: "No recovery phrase window available in EncryptionViewController", kind: SDKErrorType.Internal)
            
            SDErrorHandlerReport(error)

            let title = NSLocalizedString("Internal error", comment: "")
            
            let notification = NSUserNotification()
            
            let message = NSLocalizedString("This has been automatically reported to SafeDrive, please contact support if you still need help", comment: "")

            notification.informativeText = message
            notification.title = title
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
            
            return
        }

        self.delegate.showModalWindow(w) { (_) in
            //
        }
    }
}

extension EncryptionViewController: RecoveryPhraseEntryDelegate {
    func checkRecoveryPhrase(_ phrase: String?, success: @escaping () -> Void, failure: @escaping (_ error: SDError) -> Void) {
        assert(Thread.current == Thread.main, "checkRecoveryPhrase called on background thread")
        
        guard let email = self.email else {
            return
        }
        
        self.sdk.loadKeys(phrase, completionQueue: DispatchQueue.main, storePhrase: { (newPhrase) in
            
            self.storeRecoveryPhrase(newPhrase, success: {
                
                NotificationCenter.default.post(name: Notification.Name.accountCreatedRecoveryPhrase, object: newPhrase)

            }, failure: { (error) in
                let se = SDError(message: error.localizedDescription, kind: SDErrorType.addKeychainItemFailed)
                failure(se)
            })
            
        }, issue: { (message) in
            SDLogWarn("EncryptionViewController", "\(message)")
            
            let notification = NSUserNotification()
            
            var userInfo = [String: Any]()
            
            userInfo["identifier"] = SDNotificationType.recoveryPhrase.rawValue

            notification.userInfo = userInfo
            
            notification.informativeText = message
            notification.title = NSLocalizedString("Account issue", comment: "")
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)

        }, success: {
            if let recoveryPhrase = try? self.sdk.getKeychainItem(withUser: email, service: recoveryKeyDomain()) {
                self.recoveryPhraseField.stringValue = recoveryPhrase
                self.copyRecoveryPhraseButton.isEnabled = true
                self.enterRecoveryPhraseButton.isHidden = true
            } else {
                self.recoveryPhraseField.stringValue = NSLocalizedString("Missing", comment: "")
                self.copyRecoveryPhraseButton.isEnabled = false
                self.enterRecoveryPhraseButton.isHidden = false
            }
            success()
            
        }, failure: { (error) in
            let error = SDError(message: error.message, kind: error.kind)

            var reportError = false
            var showError = false

            switch error.kind {
            case .authorization:
                break
            default:
                if let existingError = self.lastLoadKeysError {
                    if existingError != error {
                        self.lastLoadKeysError = error
                        reportError = true
                        showError = true
                    }
                } else {
                    self.lastLoadKeysError = error
                    reportError = true
                    showError = true
                }
            }
            
            if showError {
                SDLogError("EncryptionViewController", "SafeDrive loadKeys failure in encryption view controller (this message will only appear once): \(error.message)")

                let title = NSLocalizedString("SafeDrive keys unavailable", comment: "")
                
                let notification = NSUserNotification()
                
                var userInfo = [String: Any]()
                
                userInfo["identifier"] = SDNotificationType.recoveryPhrase.rawValue

                notification.userInfo = userInfo
                
                notification.informativeText = error.message
                notification.title = title
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.default.deliver(notification)
            }
            
            if reportError && error.kind != .networkUnavailable {
                SDErrorHandlerReport(error)
            }
            
            failure(error)
            
        })
    }
    
    func storeRecoveryPhrase(_ phrase: String, success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void) {
        assert(Thread.current == Thread.main, "storeRecoveryPhrase called on background thread")
        
        guard let email = self.email else {
            return
        }
        do {
            try self.sdk.setKeychainItem(withUser: email, service: recoveryKeyDomain(), secret: phrase)
        } catch let keychainError as NSError {
            SDErrorHandlerReport(keychainError)
            failure(keychainError)
            return
        }
        success()
    }
}


extension EncryptionViewController: SDApplicationEventProtocol {
    
    func applicationDidConfigureClient(notification: Notification) {
        assert(Thread.current == Thread.main, "applicationDidConfigureClient called on background thread")
        
        guard let uniqueClient = notification.object as? Client else {
            SDLogError("EncryptionViewController", "API contract invalid: applicationDidConfigureClient()")
            
            return
        }
        
        self.uniqueClientID = uniqueClient.uniqueClientId
        self.uniqueClientName = uniqueClient.uniqueClientName
    }
    
    func applicationDidConfigureUser(notification: Notification) {
        assert(Thread.current == Thread.main, "applicationDidConfigureUser called on background thread")
        
        guard let currentUser = notification.object as? User else {
            SDLogError("EncryptionViewController", "API contract invalid: applicationDidConfigureUser()")
            
            return
        }
        
        self.email = currentUser.email
    }
}

extension EncryptionViewController: SDAccountProtocol {

    func didSignIn(notification: Foundation.Notification) {
        assert(Thread.current == Thread.main, "didSignIn called on background thread")

        guard let _ = self.uniqueClientID,
              let email = self.email else {
            SDLogError("EncryptionViewController", "API contract invalid: didSignIn()")
            return
        }
        
        let recoveryPhrase = try? self.sdk.getKeychainItem(withUser: email, service: recoveryKeyDomain())
        
        self.checkRecoveryPhrase(recoveryPhrase, success: {
            NotificationCenter.default.post(name: Notification.Name.accountLoadedRecoveryPhrase, object: nil)
        }, failure: { (error) in
            let error = SDError(message: error.message, kind: error.kind)

            switch error.kind {
            case .networkUnavailable:
                break
            case .recoveryPhraseIncorrect:
                NotificationCenter.default.post(name: Notification.Name.accountNeedsRecoveryPhrase, object: nil)
            case .keyCorrupted, .cryptoError:
                let alert = NSAlert()
                alert.addButton(withTitle: "OK")
                
                alert.messageText = "Warning: keys corrupted"
                alert.informativeText = "The keys in your account are corrupted, please restore the from backup or contact SafeDrive support for help"
                alert.alertStyle = .critical
                
                
                self.delegate.setTab(Tab.encryption)
                self.delegate.showAlert(alert) { (_) in
                    //
                }
            default:
                break
            }
        })
    }
    
    func didSignOut(notification: Foundation.Notification) {
        assert(Thread.current == Thread.main, "didSignOut called on background thread")
        self.email = nil
        self.uniqueClientID = nil
        self.uniqueClientName = nil
    }
    
    func didReceiveAccountStatus(notification: Foundation.Notification) {
        assert(Thread.current == Thread.main, "didReceiveAccountStatus called on background thread")
    }
    
    func didReceiveAccountDetails(notification: Foundation.Notification) {
        assert(Thread.current == Thread.main, "didReceiveAccountDetails called on background thread")
    }
    
    func didLoadRecoveryPhrase(notification: Notification) {
        assert(Thread.current == Thread.main, "didLoadRecoveryPhrase called on background thread")

    }
    
    func didCreateRecoveryPhrase(notification: Notification) {
        assert(Thread.current == Thread.main, "didCreateRecoveryPhrase called on background thread")
        
        guard let newPhrase = notification.object as? String else {
            SDLogError("EncryptionViewController", "API contract invalid: didSignIn()")
            return
        }
        
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        
        alert.messageText = "New recovery phrase"
        alert.informativeText = "A recovery phrase has been generated for your account, please write it down and keep it in a safe place:\n\n\(newPhrase)"
        alert.alertStyle = .informational
        
        
        self.delegate.setTab(Tab.encryption)
        self.delegate.showAlert(alert) { (_) in
            //
        }
    }
    
    func didRequireRecoveryPhrase(notification: Notification) {
        assert(Thread.current == Thread.main, "didRequireRecoveryPhrase called on background thread")

        self.recoveryPhraseField.stringValue = NSLocalizedString("Missing", comment: "")
        self.copyRecoveryPhraseButton.isEnabled = false
        self.enterRecoveryPhraseButton.isHidden = false

        guard let w = self.recoveryPhraseEntry?.window else {
            SDLogError("EncryptionViewController", "no recovery phrase window available")
            return
        }
        self.delegate.setTab(Tab.encryption)
        self.delegate.showModalWindow(w) { (_) in
            //
        }
    }
}
