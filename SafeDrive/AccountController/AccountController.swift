
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Foundation
import Crashlytics


class AccountController: NSObject {
    static let sharedAccountController = AccountController()
    
    var accountStatus: SDAccountStatus = .Unknown
    
    var email: String?
    var internalUserName: String?
    var password: String?
    
    var remoteHost: String?
    var remotePort: NSNumber?
    
    var hasCredentials: Bool = false
    var signedIn: Bool = false
    
    private var sharedSystemAPI = SDSystemAPI.sharedAPI()
    private var sharedSafedriveAPI = API.sharedAPI
    
    
    override init() {
        super.init()
        if let credentials = self.sharedSystemAPI.retrieveCredentialsFromKeychainForService(SDServiceName) {
            self.email = credentials["account"]
            self.password = credentials["password"]
            
            Crashlytics.sharedInstance().setUserEmail(self.email)
            
            SDErrorHandlerSetUser(self.email)
            self.hasCredentials = true
        }
        self.accountLoop()

    }
    
    func signInWithSuccess(successBlock: SDSuccessBlock, failure failureBlock: SDFailureBlock) {
        guard let email = self.email, password = self.password else {
            return
        }
        let keychainError: NSError? = self.sharedSystemAPI.insertCredentialsInKeychainForService(SDServiceName, account: email, password: password)
        
        if let keychainError = keychainError {
            SDErrorHandlerReport(keychainError)
            failureBlock(keychainError)
            return
        }
        Crashlytics.sharedInstance().setUserEmail(email)
        SDErrorHandlerSetUser(email)
        
        self.sharedSafedriveAPI.registerMachineWithUser(email, password: password, success: { (sessionToken: String) -> Void in
            self.sharedSafedriveAPI.accountStatusForUser(email, success: { (accountStatus: [String : NSObject]?) -> Void in
                SDLog("SafeDrive accountStatusForUser success in account controller")
                self.signedIn = true
                if let accountStatus = accountStatus {
                    SDLog("Account status: %@", accountStatus)
                    self.internalUserName = accountStatus["userName"] as? String
                    
                    self.remotePort = accountStatus["port"] as! Int
                    
                    self.remoteHost = accountStatus["host"] as? String
                
                    let keychainError: NSError? = self.sharedSystemAPI.insertCredentialsInKeychainForService(SDSSHServiceName, account: self.internalUserName!, password: self.password!)
                    if let keychainError = keychainError {
                        SDErrorHandlerReport(keychainError)
                        failureBlock(keychainError)
                        return
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName(SDAccountSignInNotification, object: nil)
                    successBlock()
                }
            }, failure: { (error: NSError) -> Void in
                failureBlock(error);

            })
        }, failure: { (error: NSError) -> Void in
            failureBlock(error);
        })
    }
    
    func signOutWithSuccess(successBlock: SDSuccessBlock, failure failureBlock: SDFailureBlock) {
        self.sharedSystemAPI.removeCredentialsInKeychainForService(SDSessionServiceName)
        self.sharedSystemAPI.removeCredentialsInKeychainForService(SDSSHServiceName)
        self.sharedSystemAPI.removeCredentialsInKeychainForService(SDServiceName)

        // reset crashlytics email and telemetry API username
        Crashlytics.sharedInstance().setUserEmail(nil)
        SDErrorHandlerSetUser(nil)

    }
    
    // MARK: Private
    
    private func accountStatusFromString(string: String) -> SDAccountStatus {
        switch string {
        case "active":
            return .Active
        case "trial":
            return .Trial
        case "trial-expired":
            return .TrialExpired
        case "expired":
            return .Expired
        case "locked":
            return .Locked
        case "reset-password":
            return .ResetPassword
        case "pending-creation":
            return .PendingCreation
        default:
            return .Unknown
        }
    }
    
    private func accountLoop() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {() -> Void in
            for ;; {
                guard let email = self.email else {
                    NSThread.sleepForTimeInterval(1)
                    continue
                }
                if !self.signedIn {
                    NSThread.sleepForTimeInterval(1)
                    continue
                }
                self.sharedSafedriveAPI.accountStatusForUser(email, success: {(accountStatus: [String : NSObject]?) -> Void in

                    if let accountStatus = accountStatus {
                        dispatch_async(dispatch_get_main_queue(), {() -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName(SDAccountStatusNotification, object: accountStatus)
                        })
                        
                        SDLog("Account status: %@", accountStatus)
                        self.internalUserName = accountStatus["userName"] as? String
                        
                        self.remotePort = accountStatus["port"] as! Int
                        
                        self.remoteHost = accountStatus["host"] as? String
                    }
                    
                }, failure: {(apiError: NSError) -> Void in
                    #if DEBUG
                    SDLog("Account status retrieval failed: %@", apiError.localizedDescription)
                    // don't report these for now, they're almost always going to be network failures
                    // SDErrorHandlerReport(apiError);
                    #endif
                })
                
                self.sharedSafedriveAPI.accountDetailsForUser(email, success: {(accountDetails: [String : NSObject]?) -> Void in
                    if let accountDetails = accountDetails {
                        dispatch_async(dispatch_get_main_queue(), {() -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName(SDAccountDetailsNotification, object: accountDetails)
                        })
                    }

                }, failure: {(apiError: NSError) -> Void in
                    #if DEBUG
                    SDLog("Account details retrieval failed: %@", apiError.localizedDescription)
                    // don't report these for now, they're almost always going to be network failures
                    // SDErrorHandlerReport(apiError);
                    #endif
                })
                NSThread.sleepForTimeInterval(60 * 5) // 5 minutes
            }
        })
    }
    
}