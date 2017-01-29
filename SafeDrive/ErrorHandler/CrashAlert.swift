
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa

extension Int {
    func toBool() -> Bool? {
        switch self {
        case 1:
            return true
        default:
            return false
        }
    }
}

class CrashAlert {
    class func show() {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {() -> Void in
            
            let suppressCrashAlerts = UserDefaults.standard.bool(forKey: "suppressCrashAlerts")
            if !suppressCrashAlerts {
                DispatchQueue.main.async(execute: {() -> Void in
                    let alert = NSAlert()
                    alert.addButton(withTitle: "OK")
                    alert.messageText = "SafeDrive crashed :("
                    alert.informativeText = "A crash report has been submitted automatically"
                    alert.alertStyle = .warning
                    alert.showsSuppressionButton = true
                    
                    alert.runModal()
                    
                    let shouldSuppressAlerts = alert.suppressionButton!.state.toBool()
                    
                    UserDefaults.standard.set(shouldSuppressAlerts, forKey: "suppressCrashAlerts")
                })
            }
        })
    }
}
