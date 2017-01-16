
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

#import "SDConstants.h"

#pragma mark - General constants

NSString *const SDDefaultVolumeName = @"SafeDrive";
NSString *const SDDefaultServerPath = @"/storage";
NSInteger const SDDefaultServerPort = 22;

NSString *const SDBuildVersionLastKey = @"SDBuildVersionLastKey";


#pragma mark - NSUserDefaults keys

NSString *const SDCurrentVolumeNameKey = @"currentVolumeName";
NSString *const SDMountAtLaunchKey = @"mountAtLaunch";

#pragma mark - SafeDrive API constants

NSString *const SDAPIDomainStaging = @"staging.safedrive.io";
NSString *const SDAPIDomainProduction = @"safedrive.io";
NSString *const SDWebDomain = @"safedrive.io";

#pragma mark - Keychain constants


NSString *const SDServiceNameProduction = @"safedrive.io";
NSString *const SDServiceNameStaging = @"staging.safedrive.io";
NSString *const SDSSHServiceName = @"ssh.safedrive.io";
NSString *const SDSessionServiceName = @"session.safedrive.io";
NSString *const SDRecoveryKeyServiceName = @"recovery.safedrive.io";

#pragma mark - Errors

NSString *const SDErrorDomain = @"io.safedrive";
NSString *const SDErrorUIDomain = @"io.safedrive.ui";
NSString *const SDErrorSyncDomain = @"io.safedrive.sync";
NSString *const SDErrorSSHFSDomain = @"io.safedrive.sshfs";
NSString *const SDErrorAccountDomain = @"io.safedrive.account";
NSString *const SDErrorAPIDomain = @"io.safedrive.api";
NSString *const SDMountErrorDomain = @"io.safedrive.mount";



NSInteger const SDErrorNone = 0;

// This will be unnecessary once SDError enums are Swift w/String values, but it's safe as long as error.code is cast
// as a specific kind of SDError enum, the compiler will warn if any cases are missing
NSString * _Nonnull SDErrorToString(NSError *error) {
     switch ((enum SDSSHError)error.code) {
         case SDSSHErrorUnknown:
             return @"SDSSHErrorUnknown";
         case SDSSHErrorAuthorization:
             return @"SDSSHErrorAuthorization";
         case SDSSHErrorTimeout:
             return @"SDSSHErrorTimeout";
         case SDSSHErrorHostFingerprintChanged:
             return @"SDSSHErrorHostFingerprintChanged";
         case SDSSHErrorHostKeyVerificationFailed:
             return @"SDSSHErrorHostKeyVerificationFailed";
         case SDSSHErrorDirectoryMissing:
             return @"SDSSHErrorDirectoryMissing";
         case SDSSHErrorRemoteEnvironment:
             return @"SDSSHErrorRemoteEnvironment";
         case SDSSHErrorSFTPOperationFailure:
             return @"SDSSHErrorSFTPOperationFailure";
         case SDSSHErrorSFTPOperationFolderConflict:
             return @"SDSSHErrorSFTPOperationFolderConflict";

     }
    
     
     switch ((enum SDSystemError)error.code) {
         case SDSystemErrorUnknown:
             return @"SDSystemErrorUnknown";
         case SDSystemErrorAddLoginItemFailed:
             return @"SDSystemErrorAddLoginItemFailed";
         case SDSystemErrorRemoveLoginItemFailed:
             return @"SDSystemErrorRemoveLoginItemFailed";
         case SDSystemErrorAddKeychainItemFailed:
             return @"SDSystemErrorAddKeychainItemFailed";
         case SDSystemErrorRemoveKeychainItemFailed:
             return @"SDSystemErrorRemoveKeychainItemFailed";
         case SDSystemErrorFilePermissionDenied:
             return @"SDSystemErrorFilePermissionDenied";
         case SDSystemErrorOSXFUSEMissing:
             return @"SDSystemErrorOSXFUSEMissing";
         case SDSystemErrorSSHFSMissing:
             return @"SDSystemErrorSSHFSMissing";
         case SDSystemErrorAskpassMissing:
             return @"SDSystemErrorAskpassMissing";
         case SDSystemErrorRsyncMissing:
             return @"SDSystemErrorRsyncMissing";
     }
     
     
     switch ((enum SDAPIError)error.code) {
             // Client errors
         case SDAPIErrorUnknown:
             return @"SDAPIErrorUnknown";
         case SDAPIErrorBadRequest:
             return @"SDAPIErrorBadRequest";
         case SDAPIErrorUnauthorized:
             return @"SDAPIErrorUnauthorized";
         case SDAPIErrorPaymentRequired:
             return @"SDAPIErrorPaymentRequired";
         case SDAPIErrorForbidden:
             return @"SDAPIErrorForbidden";
         case SDAPIErrorNotFound:
             return @"SDAPIErrorNotFound";
         case SDAPIErrorMethodNotAllowed:
             return @"SDAPIErrorMethodNotAllowed";
         case SDAPIErrorProxyAuthenticationRequired:
             return @"SDAPIErrorProxyAuthenticationRequired";
         case SDAPIErrorRequestTimeout:
             return @"SDAPIErrorRequestTimeout";
         case SDAPIErrorConflict:
             return @"SDAPIErrorConflict";
         case SDAPIErrorGone:
             return @"SDAPIErrorGone";
         case SDAPIErrorLengthRequired:
             return @"SDAPIErrorLengthRequired";
         case SDAPIErrorPreconditionFailed:
             return @"SDAPIErrorPreconditionFailed";
         case SDAPIErrorPayloadTooLarge:
             return @"SDAPIErrorPayloadTooLarge";
         case SDAPIErrorURITooLong:
             return @"SDAPIErrorURITooLong";
         case SDAPIErrorUnsupportedMediaType:
             return @"SDAPIErrorUnsupportedMediaType";
         case SDAPIErrorRangeNotSatisfiable:
             return @"SDAPIErrorRangeNotSatisfiable";
         case SDAPIErrorExpectationFailed:
             return @"SDAPIErrorExpectationFailed";
         case SDAPIErrorImATeapot:
             return @"SDAPIErrorImATeapot";
         case SDAPIErrorMisdirectedRequest:
             return @"SDAPIErrorMisdirectedRequest";
         case SDAPIErrorUnprocessableEntity:
             return @"SDAPIErrorUnprocessableEntity";
         case SDAPIErrorLocked:
             return @"SDAPIErrorLocked";
         case SDAPIErrorFailedDependency:
             return @"SDAPIErrorFailedDependency";
         case SDAPIErrorUpgradeRequired:
             return @"SDAPIErrorUpgradeRequired";
         case SDAPIErrorPreconditionRequired:
             return @"SDAPIErrorPreconditionRequired";
         case SDAPIErrorTooManyRequests:
             return @"SDAPIErrorTooManyRequests";
         case SDAPIErrorRequestHeaderFieldsTooLarge:
             return @"SDAPIErrorRequestHeaderFieldsTooLarge";
         case SDAPIErrorUnavailableForLegalReasons:
             return @"SDAPIErrorUnavailableForLegalReasons";

             
             // Server errors
         case SDAPIErrorInternalServerError:
             return @"SDAPIErrorInternalServerError";
         case SDAPIErrorNotImplemented:
             return @"SDAPIErrorNotImplemented";
         case SDAPIErrorBadGateway:
             return @"SDAPIErrorBadGateway";
         case SDAPIErrorServiceUnavailable:
             return @"SDAPIErrorServiceUnavailable";
         case SDAPIErrorGatewayTimeout:
             return @"SDAPIErrorGatewayTimeout";
         case SDAPIErrorHTTPVersionNotSupported:
             return @"SDAPIErrorHTTPVersionNotSupported";
         case SDAPIErrorVariantAlsoNegotiates:
             return @"SDAPIErrorVariantAlsoNegotiates";
         case SDAPIErrorInsufficientStorage:
             return @"SDAPIErrorInsufficientStorage";
         case SDAPIErrorLoopDetected:
             return @"SDAPIErrorLoopDetected";
         case SDAPIErrorNotExtended:
             return @"SDAPIErrorNotExtended";
         case SDAPIErrorNetworkAuthenticationRequired:
             return @"SDAPIErrorNetworkAuthenticationRequired";
     }
    
     
     switch ((enum SDSyncError)error.code) {
         case SDSyncErrorUnknown:
             return @"SDSyncErrorUnknown";
         case SDSyncErrorTimeout:
             return @"SDSyncErrorTimeout";
         case SDSyncErrorDirectoryMissing:
             return @"SDSyncErrorDirectoryMissing";
         case SDSyncErrorSyncFailed:
             return @"SDSyncErrorSyncFailed";
         case SDSyncErrorAlreadyRunning:
             return @"SDSyncErrorAlreadyRunning";
         case SDSyncErrorRemoteEnvironment:
             return @"SDSyncErrorRemoteEnvironment";
         case SDSyncErrorFolderConflict:
             return @"SDSyncErrorFolderConflict";
         case SDSyncErrorCancelled:
             return @"SDSyncErrorCancelled";
     }
     
     
     switch ((enum SDMountError)error.code) {
         case SDMountErrorUnknown:
             return @"SDMountErrorUnknown";
         case SDMountErrorMountFailed:
             return @"SDMountErrorMountFailed";
         case SDMountErrorAlreadyMounted:
             return @"SDMountErrorAlreadyMounted";
         case SDMountErrorUnmountFailed:
             return @"SDMountErrorUnmountFailed";
     }
    switch ((enum SDDatabaseError)error.code) {
        case SDDatabaseErrorUnknown:
            return @"SDDatabaseErrorUnknown";
        case SDDatabaseErrorOpenFailed:
            return @"SDDatabaseErrorOpenFailed";
        case SDDatabaseErrorWriteFailed:
            return @"SDDatabaseErrorWriteFailed";
        case SDDatabaseErrorMigrationFailed:
            return @"SDDatabaseErrorMigrationFailed";
    }
     return @"Unknown";
}
