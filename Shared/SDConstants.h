
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - General constants

FOUNDATION_EXPORT NSString *const SDDefaultVolumeName;
FOUNDATION_EXPORT NSString *const SDDefaultServerPath;
FOUNDATION_EXPORT NSString *const SDDefaultServerHostname;
FOUNDATION_EXPORT NSInteger const SDDefaultServerPort;

#pragma mark - NSUserDefaults keys

FOUNDATION_EXPORT NSString *const SDCurrentVolumeNameKey;
FOUNDATION_EXPORT NSString *const SDMountAtLaunchKey;


#pragma mark - SafeDrive API constants

FOUNDATION_EXPORT NSString *const SDAPIDomainTesting;
FOUNDATION_EXPORT NSString *const SDAPIDomain;
FOUNDATION_EXPORT NSString *const SDWebDomain;

#pragma mark - Common paths

FOUNDATION_EXPORT NSString *const SDDefaultSSHFSPath;
FOUNDATION_EXPORT NSString *const SDDefaultOSXFUSEFSPath;

FOUNDATION_EXPORT NSString *const SDDefaultRsyncPath;

#pragma mark - Keychain constants


FOUNDATION_EXPORT NSString *const SDServiceName;
FOUNDATION_EXPORT NSString *const SDServiceNameTesting;
FOUNDATION_EXPORT NSString *const SDSSHServiceName;
FOUNDATION_EXPORT NSString *const SDSessionServiceName;


#pragma mark - Custom NSNotifications

FOUNDATION_EXPORT NSString *const SDMountStateMountedNotification;
FOUNDATION_EXPORT NSString *const SDMountStateUnmountedNotification;
FOUNDATION_EXPORT NSString *const SDMountStateDetailsNotification;


FOUNDATION_EXPORT NSString *const SDVolumeDidMountNotification;
FOUNDATION_EXPORT NSString *const SDVolumeDidUnmountNotification;
FOUNDATION_EXPORT NSString *const SDVolumeShouldUnmountNotification;
FOUNDATION_EXPORT NSString *const SDVolumeSubprocessDidTerminateNotification;

FOUNDATION_EXPORT NSString *const SDApplicationShouldOpenPreferencesWindow;
FOUNDATION_EXPORT NSString *const SDApplicationShouldOpenAccountWindow;
FOUNDATION_EXPORT NSString *const SDApplicationShouldOpenAboutWindow;
FOUNDATION_EXPORT NSString *const SDApplicationShouldOpenSyncWindow;
FOUNDATION_EXPORT NSString *const SDApplicationShouldFinishLaunch;


FOUNDATION_EXPORT NSString *const SDAPIDidEnterMaintenancePeriod;
FOUNDATION_EXPORT NSString *const SDAPIDidBecomeReachable;
FOUNDATION_EXPORT NSString *const SDAPIDidBecomeUnreachable;

FOUNDATION_EXPORT NSString *const SDAccountSignInNotification;
FOUNDATION_EXPORT NSString *const SDAccountSignOutNotification;
FOUNDATION_EXPORT NSString *const SDAccountStatusNotification;
FOUNDATION_EXPORT NSString *const SDAccountDetailsNotification;

FOUNDATION_EXPORT NSString *const SDServiceStatusNotification;

NS_ASSUME_NONNULL_END

#pragma mark - Status Enums

typedef NS_ENUM(NSUInteger, SDAccountStatus) {
    SDAccountStatusUnknown          = -1,   // invalid state, display error or halt
    SDAccountStatusActive           =  1,	// the SFTP connection will be continued by the client
    SDAccountStatusTrial            =  2,	// the SFTP connection will be continued by the client
    SDAccountStatusTrialExpired     =  3,	// trial expired, trial expiration date will be returned from the server and formatted with the user's locale format
    SDAccountStatusExpired          =  4,	// account expired, expiration date will be returned from the server and formatted with the user's locale format
    SDAccountStatusLocked           =  5,	// account locked, date will be returned from the server and formatted with the user's locale format
    SDAccountStatusResetPassword    =  6,	// password being reset
    SDAccountStatusPendingCreation  =  7,	// account not ready yet
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Errors

FOUNDATION_EXPORT NSString *const SDErrorDomain;
FOUNDATION_EXPORT NSString *const SDErrorUIDomain;
FOUNDATION_EXPORT NSString *const SDErrorSyncDomain;
FOUNDATION_EXPORT NSString *const SDErrorSSHFSDomain;
FOUNDATION_EXPORT NSString *const SDErrorAccountDomain;
FOUNDATION_EXPORT NSString *const SDErrorAPIDomain;
FOUNDATION_EXPORT NSString *const SDMountErrorDomain;


FOUNDATION_EXPORT NSUInteger const SDErrorNone;

NS_ASSUME_NONNULL_END

#pragma mark - SSH related errors

typedef NS_ENUM(NSInteger, SDSSHError) {
    SDSSHErrorUnknown                   = -1000,
    SDSSHErrorAuthorization             = 1001,
    SDSSHErrorTimeout                   = 1002,
    SDSSHErrorHostFingerprintChanged    = 1003,
    SDSSHErrorHostKeyVerificationFailed = 1004,
    SDSSHErrorDirectoryMissing          = 1005,
    SDSSHErrorRemoteEnvironment         = 1016
};

#pragma mark - System API related errors

typedef NS_ENUM(NSInteger, SDSystemError) {
    SDSystemErrorUnknown                  = -2000,
    SDSystemErrorAddLoginItemFailed       = 2001,
    SDSystemErrorRemoveLoginItemFailed    = 2002,
    SDSystemErrorAddKeychainItemFailed    = 2003,
    SDSystemErrorRemoveKeychainItemFailed = 2004,
    SDSystemErrorFilePermissionDenied     = 2005,
    SDSystemErrorOSXFUSEMissing           = 2006,
    SDSystemErrorSSHFSMissing             = 2007,
    SDSystemErrorAskpassMissing           = 2008

};

#pragma mark - SafeDrive API related errors

typedef NS_ENUM(NSInteger, SDAPIError) {
    // Client errors
    SDAPIErrorUnknown                       = -1,
    SDAPIErrorBadRequest                    = 400,
    SDAPIErrorUnauthorized                  = 401,
    SDAPIErrorPaymentRequired               = 402,
    SDAPIErrorForbidden                     = 403,
    SDAPIErrorNotFound                      = 404,
    SDAPIErrorMethodNotAllowed              = 406,
    SDAPIErrorProxyAuthenticationRequired   = 407,
    SDAPIErrorRequestTimeout                = 408,
    SDAPIErrorConflict                      = 409,
    SDAPIErrorGone                          = 410,
    SDAPIErrorLengthRequired                = 411,
    SDAPIErrorPreconditionFailed            = 412,
    SDAPIErrorPayloadTooLarge               = 413,
    SDAPIErrorURITooLong                    = 414,
    SDAPIErrorUnsupportedMediaType          = 415,
    SDAPIErrorRangeNotSatisfiable           = 416,
    SDAPIErrorExpectationFailed             = 417,
    SDAPIErrorImATeapot                     = 418, // yes, really...
    SDAPIErrorMisdirectedRequest            = 421,
    SDAPIErrorUnprocessableEntity           = 422,
    SDAPIErrorLocked                        = 423,
    SDAPIErrorFailedDependency              = 424,
    SDAPIErrorUpgradeRequired               = 426,
    SDAPIErrorPreconditionRequired          = 428,
    SDAPIErrorTooManyRequests               = 429,
    SDAPIErrorRequestHeaderFieldsTooLarge   = 431,
    SDAPIErrorUnavailableForLegalReasons    = 451,
    
    // Server errors
    SDAPIErrorInternalServerError           = 500,
    SDAPIErrorNotImplemented                = 501,
    SDAPIErrorBadGateway                    = 502,
    SDAPIErrorServiceUnavailable            = 503,
    SDAPIErrorGatewayTimeout                = 504,
    SDAPIErrorHTTPVersionNotSupported       = 505,
    SDAPIErrorVariantAlsoNegotiates         = 506,
    SDAPIErrorInsufficientStorage           = 507,
    SDAPIErrorLoopDetected                  = 508,
    SDAPIErrorNotExtended                   = 510,
    SDAPIErrorNetworkAuthenticationRequired = 511
};

#pragma mark - Sync errors

typedef NS_ENUM(NSInteger, SDSyncError) {
    SDSyncErrorUnknown                   = -4000,
    SDSyncErrorTimeout                   = 4001,
    SDSyncErrorDirectoryMissing          = 4002,
    SDSyncErrorSyncFailed                = 4003,
    SDSyncErrorAlreadyRunning            = 4004,
    SDSyncErrorRemoteEnvironment         = 4005,
    SDSyncErrorFolderConflict            = 4006,
};


typedef NS_ENUM(NSInteger, SDMountError) {
    SDMountErrorUnknown                  = -5000,
    SDMountErrorMountFailed              = 5001,
    SDMountErrorUnmountFailed            = 5002,
    SDMountErrorAlreadyMounted           = 5003
};

#pragma mark - Database errors

typedef NS_ENUM(NSInteger, SDDatabaseError) {
    SDDatabaseErrorUnknown                  = -6000,
    SDDatabaseErrorOpenFailed               = 6001,
    SDDatabaseErrorMigrationFailed          = 6002,
    SDDatabaseErrorWriteFailed              = 6003
};

#pragma mark - Sync state

typedef NS_ENUM(NSInteger, SDSyncState) {
    SDSyncStateUnknown = -1,
    SDSyncStateRunning =  0,
    SDSyncStateIdle    =  1
};

#pragma mark - Block definitions

typedef void(^SDSuccessBlock)();
typedef void(^SDFailureBlock)(NSError * _Nonnull apiError);

typedef void(^SDMountSuccessBlock)(NSURL * _Nonnull mountURL, NSError * _Nullable mountError);
typedef void(^SDMountFailureBlock)(NSURL * _Nonnull mountURL, NSError * _Nonnull mountError);

typedef void(^SDAPIClientRegistrationSuccessBlock)(NSString * _Nonnull sessionToken, NSString * _Nonnull clientID);

typedef void(^SDAPIAccountStatusBlock)(NSDictionary <NSString *, NSObject *>* _Nullable accountStatus);
typedef void(^SDAPIAccountDetailsBlock)(NSDictionary <NSString *, NSObject *>* _Nullable accountDetails);

typedef void(^SDAPIFingerprintListSuccessBlock)(NSDictionary * _Nonnull fingerprintPairs);

typedef void(^SDAPICreateSyncFolderSuccessBlock)(NSInteger folderID);
typedef void(^SDAPIReadSyncFoldersSuccessBlock)(NSArray<NSDictionary<NSString *, NSObject *>*> * _Nonnull folders);
typedef void(^SDAPIDeleteSyncFoldersSuccessBlock)();


typedef void(^SDSyncResultBlock)(NSURL * _Nonnull syncURL, NSError * _Nullable syncError);

#pragma mark - Global functions

NSString * _Nonnull SDErrorToString(NSError * _Nonnull error);