
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let mounted = Notification.Name("mountedNotification")
    static let unmounted = Notification.Name("unmountedNotification")
    static let mountDetails = Notification.Name("mountDetailsNotification")


    static let volumeDidMount = Notification.Name("volumeDidMountNotification")
    static let volumeDidUnmount = Notification.Name("volumeDidUnmountNotification")
    static let volumeShouldUnmount = Notification.Name("volumeShouldUnmountNotification")
    static let volumeSubprocessDidTerminate = Notification.Name("volumeSubprocessDidTerminateNotification")

    static let applicationShouldOpenPreferencesWindow = Notification.Name("applicationShouldOpenPreferencesWindowNotification")
    static let applicationShouldOpenAccountWindow = Notification.Name("applicationShouldOpenAccountWindowNotification")
    static let applicationShouldOpenAboutWindow = Notification.Name("applicationShouldOpenAboutWindowNotification")
    static let applicationShouldOpenSyncWindow = Notification.Name("applicationShouldOpenSyncWindowNotification")
    static let applicationShouldFinishConfiguration = Notification.Name("applicationShouldFinishConfigurationNotification")


    static let apiDidEnterMaintenancePeriod = Notification.Name("apiDidEnterMaintenancePeriodNotification")
    static let apiDidBecomeReachable = Notification.Name("apiDidBecomeReachableNotification")
    static let apiDidBecomeUnreachable = Notification.Name("apiDidBecomeUnreachableNotification")

    static let accountAuthenticated = Notification.Name("accountAuthenticatedNotification")
    static let accountSignOut = Notification.Name("accountSignOutNotification")
    static let accountStatus = Notification.Name("accountStatusNotification")
    static let accountDetails = Notification.Name("accountDetailsNotification")

    static let serviceStatus = Notification.Name("serviceStatusNotification")
    
    static let sdkReady = Notification.Name("sdkReadyNotification")

}
