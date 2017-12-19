
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa

class GeneralViewController: NSViewController {

    fileprivate var sharedSystemAPI = SDSystemAPI.shared()
    
    @IBOutlet fileprivate var volumeNameField: NSTextField!
    @IBOutlet fileprivate var volumeNameWarningField: NSTextField!

    fileprivate weak var delegate: PreferencesViewDelegate!
    
    var autostart: Bool {
        get {
            return self.sharedSystemAPI.autostart()
        }
        set(newValue) {
            if newValue == true {
                do {
                    try self.sharedSystemAPI.enableAutostart()
                } catch let error as NSError {
                    SDErrorHandlerReport(error)
                }
            } else {
                do {
                    try self.sharedSystemAPI.disableAutostart()
                } catch let error as NSError {
                    SDErrorHandlerReport(error)
                }
            }
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

        self.init(nibName: NSNib.Name(rawValue: "GeneralView"), bundle: nil)

        
        self.delegate = delegate
        
        // register SDMountStateProtocol notifications
        NotificationCenter.default.addObserver(self, selector: #selector(SDMountStateProtocol.mountState), name: Notification.Name.mountState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SDMountStateProtocol.mountStateDetails), name: Notification.Name.mountDetails, object: nil)
    }
    
}

extension GeneralViewController: SDMountStateProtocol {
    
    func mountState(notification: Foundation.Notification) {
        guard let mounted = notification.object as? Bool else {
            return
        }

        assert(Thread.current == Thread.main, "mountState called on background thread")
        
        if mounted {
            self.volumeNameField.isEnabled = false
            self.volumeNameWarningField.isHidden = false
        } else {
            self.volumeNameField.isEnabled = true
            self.volumeNameWarningField.isHidden = true
        }
    }
    
    func mountStateDetails(notification: Foundation.Notification) {
        assert(Thread.current == Thread.main, "mountStateDetails called on background thread")

    }
}
