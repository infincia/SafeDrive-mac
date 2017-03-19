
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa
import SafeDriveSDK

class ValidateClientViewController: NSViewController {

    fileprivate var sdk = SafeDriveSDK.sharedSDK
    
    fileprivate weak var delegate: StateDelegate?
    
    @IBOutlet var spinner: NSProgressIndicator!
    
    @IBOutlet weak var clientList: NSTableView!
    
    @IBOutlet weak var newClientButton: NSButton!
    
    @IBOutlet weak var replaceClientButton: NSButton!
    
    var clients: [SoftwareClient]?
    
    fileprivate var prompted = false
    
    fileprivate var name: String?

    fileprivate var email: String?
    
    fileprivate var password: String?
    
    var hasRegisteredClients = NSNumber(value: 0)

    fileprivate var isClientRegistered = false
    
    override func viewDidLoad() {
        if #available(OSX 10.10, *) {
            super.viewDidLoad()
        } else {
            // Fallback on earlier versions
        }
        // Do view setup here.
    }
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(delegate: StateDelegate) {
        self.init(nibName: "ValidateClientView", bundle: nil)!
        self.delegate = delegate
    }
    
    func reset() {
        self.name = nil
        self.email = nil
        self.password = nil
        self.prompted = false
        self.spinner.stopAnimation(self)
        self.clients = nil
        self.hasRegisteredClients = NSNumber(value: 0)
        self.isClientRegistered = false
    }
    
    func check(email: String, password: String, clients: [SoftwareClient]) {
        self.reset()
        
        SDLog("checking client")

        self.email = email
        self.password = password
        
        self.clients = clients
        self.hasRegisteredClients = NSNumber(value: clients.count)
        SDLog("have clients: \(self.hasRegisteredClients)")
        self.clientList.reloadData()
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            
            let host = Host()
            let machineName = host.localizedName!
            
            if let uniqueClientID = try? SafeDriveSDK.sharedSDK.getKeychainItem(withUser: email, service: UCIDDomain()) {
                SDLog("valid client found, continuing")

                DispatchQueue.main.sync {
                    self.delegate?.didValidateClient(withEmail: email, password: password, name: machineName, uniqueClientID: uniqueClientID)
                }
                return
            }
            
            while !self.isClientRegistered {
                if !self.prompted {
                    self.prompted = true
                    DispatchQueue.main.sync {
                        self.delegate?.needsClient()
                    }
                }
                Thread.sleep(forTimeInterval: 1)
            }
            SDLog("valid client found, continuing")
        }
    }
    
    @IBAction func newClient(_ sender: AnyObject?) {
        SDLog("setting up client as new")
        guard let email = self.email,
              let password = self.password,
              let name = self.name else {
            self.delegate?.didFail(error: NSError(domain: SDErrorDomain, code: SDSystemError.unknown.rawValue, userInfo: nil), uniqueClientID: nil)
            return
        }
        
        let uniqueClientID = self.sdk.generateUniqueClientID()
        let host = Host()
        let machineName = host.localizedName!
        DispatchQueue.main.sync {
            self.delegate?.didValidateClient(withEmail: email, password: password, name: machineName, uniqueClientID: uniqueClientID)
        }
    }
    
    @IBAction func replaceClient(_ sender: AnyObject?) {
        SDLog("replacing client")

        guard let clients = self.clients else {
            return
        }
        
        let sindex = self.clientList.selectedRow
        
        guard sindex >= 0 else {
            return
        }
        
        let client = clients[sindex]
        
        SDLog("client \(client.uniqueClientID) being replaced")
        
        guard let email = self.email,
              let password = self.password,
              let name = self.name else {
            self.delegate?.didFail(error: NSError(domain: SDErrorInstallationDomain, code: SDInstallationError.unknown.rawValue, userInfo: nil), uniqueClientID: client.uniqueClientID)
            return
        }

        let host = Host()
        let machineName = host.localizedName!
        
        self.delegate?.didValidateClient(withEmail: email, password: password, name: machineName, uniqueClientID: client.uniqueClientID)
    }
}

extension ValidateClientViewController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0 else {
            return nil
        }
        guard let clients = self.clients else {
            return nil
        }
        
        let view = tableView.make(withIdentifier: "SoftwareClientTableCellView", owner: self) as! SoftwareClientTableCellView
        
        let client = clients[row]

        view.softwareClient = client
        view.uniqueClientID.stringValue = client.uniqueClientID
        //view.icon.image = client.icon
        
        return view
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let clients = self.clients else {
            return 0
        }
        return clients.count
    }
    
    func numberOfSections(in tableView: NSTableView) -> Int {
        return 1
    }
}

extension ValidateClientViewController:  NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let i = clientList.selectedRow
        
        guard let view = clientList.view(atColumn: 0, row: i, makeIfNecessary: false) as? SoftwareClientTableCellView else {
            return
        }
        
        let _ = view.softwareClient
        
    }
}
