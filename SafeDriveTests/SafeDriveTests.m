
//  Copyright (c) 2014 Infincia LLC. All rights reserved.
//

@import Cocoa;
@import XCTest;

#import "SDConstants.h"
#import "SDTestConstants.h"

#import "SDAPI.h"
#import "SDMountController.h"
#import "SDSyncController.h"
#import "SDSystemAPI.h"

#import "SDSyncItem.h"

#import "SDErrorHandler.h"

#import "NSURL+SFTP.h"


@interface SafeDriveTests : XCTestCase

@end

@implementation SafeDriveTests

+ (void)setUp {
    NSError *keychainInsertError = [[SDSystemAPI sharedAPI] insertCredentialsInKeychainForService:SDServiceName account:SDTestCredentialsUser password:SDTestCredentialsPassword];
    if (keychainInsertError) {
        NSLog(@"+setUp failed: %@", keychainInsertError.localizedDescription);
    }
    else {
        NSLog(@"+setUp succeeded");
    }
}



- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


// NOTE: this test is expected to fail in Xcode as ~/ resolves to something other than
-(void)test_SDSyncItem_hasConflictingFolderRegistered_tildeInPath {
    SDSyncItem *machine = [SDSyncItem itemWithLabel:@"Mac" localFolder:nil isMachine:YES uniqueID:-1];
    XCTAssertNotNil(machine);
    
    NSURL *url = [NSURL fileURLWithPath:@"/Users/user" isDirectory:YES];
    SDSyncItem *homeSyncFolder = [SDSyncItem itemWithLabel:@"Home" localFolder:url isMachine:NO uniqueID:1];
    XCTAssertNotNil(homeSyncFolder);
    
    [machine appendSyncFolder:homeSyncFolder];
    
    NSURL *relativeHome = [NSURL fileURLWithPath:@"~/user"];
    XCTAssertTrue([machine hasConflictingFolderRegistered:relativeHome]);
}

-(void)test_SDSyncItem_hasConflictingFolderRegistered_otherUser {
    SDSyncItem *machine = [SDSyncItem itemWithLabel:@"Mac" localFolder:nil isMachine:YES uniqueID:-1];
    XCTAssertNotNil(machine);
    
    NSURL *url = [NSURL fileURLWithPath:@"/Users/user" isDirectory:YES];
    SDSyncItem *homeSyncFolder = [SDSyncItem itemWithLabel:@"Home" localFolder:url isMachine:NO uniqueID:1];
    XCTAssertNotNil(homeSyncFolder);
    
    [machine appendSyncFolder:homeSyncFolder];
    
    NSURL *otherUserHome = [NSURL fileURLWithPath:@"/Users/otheruser"];
    XCTAssertFalse([machine hasConflictingFolderRegistered:otherUserHome]);
}

-(void)test_SDSyncItem_hasConflictingFolderRegistered_subDirectory {
    SDSyncItem *machine = [SDSyncItem itemWithLabel:@"Mac" localFolder:nil isMachine:YES uniqueID:-1];
    XCTAssertNotNil(machine);

    NSURL *url = [NSURL fileURLWithPath:@"/Users/user" isDirectory:YES];
    SDSyncItem *homeSyncFolder = [SDSyncItem itemWithLabel:@"Home" localFolder:url isMachine:NO uniqueID:1];
    XCTAssertNotNil(homeSyncFolder);
    
    [machine appendSyncFolder:homeSyncFolder];

    NSURL *documents = [NSURL fileURLWithPath:@"/Users/user/Documents"];
    XCTAssertTrue([machine hasConflictingFolderRegistered:documents]);
}

-(void)test_SDSyncItem_hasConflictingFolderRegistered_subDirectory_trailingSlash {
    SDSyncItem *machine = [SDSyncItem itemWithLabel:@"Mac" localFolder:nil isMachine:YES uniqueID:-1];
    XCTAssertNotNil(machine);
    
    NSURL *url = [NSURL fileURLWithPath:@"/Users/user" isDirectory:YES];
    SDSyncItem *homeSyncFolder = [SDSyncItem itemWithLabel:@"Home" localFolder:url isMachine:NO uniqueID:1];
    XCTAssertNotNil(homeSyncFolder);
    
    [machine appendSyncFolder:homeSyncFolder];
    
    NSURL *documents = [NSURL fileURLWithPath:@"/Users/user/Documents/"];
    XCTAssertTrue([machine hasConflictingFolderRegistered:documents]);
}

-(void)test_SDSyncItem_hasConflictingFolderRegistered_parentDirectory {
    SDSyncItem *machine = [SDSyncItem itemWithLabel:@"Mac" localFolder:nil isMachine:YES uniqueID:-1];
    XCTAssertNotNil(machine);
    
    NSURL *url = [NSURL fileURLWithPath:@"/Users/user" isDirectory:YES];
    SDSyncItem *homeSyncFolder = [SDSyncItem itemWithLabel:@"Home" localFolder:url isMachine:NO uniqueID:1];
    XCTAssertNotNil(homeSyncFolder);
    
    [machine appendSyncFolder:homeSyncFolder];
    
    NSURL *root = [NSURL fileURLWithPath:@"/"];
    XCTAssertTrue([machine hasConflictingFolderRegistered:root]);
}


-(void)test_SDErrorHandler_reportError {
    XCTAssertNotNil([SDAPI sharedAPI]);

    NSError *testError = [NSError errorWithDomain:SDErrorDomain code:SDErrorNone userInfo:@{NSLocalizedDescriptionKey:  NSLocalizedString(@"TEST: IGNORE THIS ERROR REPORT", nil)}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_SDAPI_registerMachine"];

    dispatch_queue_t queue = dispatch_get_main_queue();
    [[SDAPI sharedAPI] reportError:testError forUser:SDTestCredentialsUser withLog:@[@"test"] completionQueue:queue success:^{
        [expectation fulfill];
    } failure:^(NSError *apiError) {
        XCTFail(@"%@", apiError.localizedDescription);
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"test_SDErrorHandler_reportError error: %@", error.localizedDescription);
        }
    }];
}

-(void)test_SDSystemAPI_en0MAC {
    XCTAssertNotNil([SDSystemAPI sharedAPI]);
    NSString *mac = [[SDSystemAPI sharedAPI] en0MAC];
    XCTAssertNotNil(mac);
    NSLog(@"MAC en0: %@", mac);
}

-(void)test_SDAPI_registerMachine {
    XCTAssertNotNil([SDAPI sharedAPI]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_SDAPI_registerMachine"];
    
    [[SDAPI sharedAPI] registerMachineWithUser:SDTestCredentialsUser password:SDTestCredentialsPassword success:^(NSString *sessionToken) {
        XCTAssertNotNil(sessionToken);
        [expectation fulfill];
    } failure:^(NSError *apiError) {
        XCTFail(@"%@", apiError.localizedDescription);
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"test_SDAPI_registerMachine error: %@", error.localizedDescription);    
        }
    }];
}

-(void)test_SDAPI_accountStatusForUser {
    XCTAssertNotNil([SDAPI sharedAPI]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_SDAPI_accountStatusForUser"];
    [[SDAPI sharedAPI] registerMachineWithUser:SDTestCredentialsUser password:SDTestCredentialsPassword success:^(NSString *sessionToken) {
        XCTAssertNotNil(sessionToken);
        [[SDAPI sharedAPI] accountStatusForUser:SDTestCredentialsUser success:^(NSDictionary *accountStatus) {
            XCTAssertNotNil(accountStatus);
            XCTAssertNotNil(accountStatus[@"host"]);
            XCTAssertNotNil(accountStatus[@"port"]);
            XCTAssertNotNil(accountStatus[@"status"]);
            XCTAssertNotNil(accountStatus[@"userName"]);
            NSLog(@"Account status: %@", accountStatus);
            [expectation fulfill];
        } failure:^(NSError *apiError) {
            XCTFail(@"%@", apiError.localizedDescription);
        }];
    } failure:^(NSError *apiError) {
        XCTFail(@"%@", apiError.localizedDescription);
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"test_SDAPI_accountStatusForUser error: %@", error.localizedDescription);    
        }
    }];
}

-(void)test_SDAPI_accountDetailsForUser {
    XCTAssertNotNil([SDAPI sharedAPI]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_SDAPI_accountDetailsForUser"];
    [[SDAPI sharedAPI] registerMachineWithUser:SDTestCredentialsUser password:SDTestCredentialsPassword success:^(NSString *sessionToken) {
        XCTAssertNotNil(sessionToken);
        [[SDAPI sharedAPI] accountDetailsForUser:SDTestCredentialsUser success:^(NSDictionary *accountDetails) {
            XCTAssertNotNil(accountDetails);

            NSLog(@"Account details: %@", accountDetails);
            [expectation fulfill];
        } failure:^(NSError *apiError) {
            XCTFail(@"%@", apiError.localizedDescription);
        }];
    } failure:^(NSError *apiError) {
        XCTFail(@"%@", apiError.localizedDescription);
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"test_SDAPI_accountDetailsForUser error: %@", error.localizedDescription);    
        }
    }];
}


- (void)test_SDMountController_startMountTaskWithVolumeName {
    XCTAssertNotNil([SDMountController sharedAPI]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_SDMountController_startMountTaskWithVolumeName"];

    [[SDAPI sharedAPI] registerMachineWithUser:SDTestCredentialsUser password:SDTestCredentialsPassword success:^(NSString *sessionToken) {
        XCTAssertNotNil(sessionToken);
        [[SDAPI sharedAPI] accountStatusForUser:SDTestCredentialsUser success:^(NSDictionary *accountStatus) {
            XCTAssertNotNil(accountStatus);
            XCTAssertNotNil(accountStatus[@"host"]);
            XCTAssertNotNil(accountStatus[@"port"]);
            XCTAssertNotNil(accountStatus[@"status"]);
            XCTAssertNotNil(accountStatus[@"userName"]);
            
            NSLog(@"Account status: %@", accountStatus);
            
            NSURL *url = [NSURL SFTPURLForAccount:accountStatus[@"userName"] host:accountStatus[@"host"] port:accountStatus[@"port"] path:SDDefaultServerPath];

            [[SDMountController sharedAPI] startMountTaskWithVolumeName:@"SafeDrive" sshURL:url success:^(NSURL *mountURL, NSError *mountError) {
                /*  
                 now check for a successful mount. if after 30 seconds there is no volume
                 mounted, it is a fair bet that an error occurred in the meantime
                 
                 */
                XCTAssertNotNil(mountURL);
                
                [[SDSystemAPI sharedAPI] checkForMountedVolume:mountURL withTimeout:30 success:^{
                    NSDictionary *mountDetails = [[SDSystemAPI sharedAPI] detailsForMount:mountURL];
                    XCTAssertNotNil(mountDetails);
                    XCTAssertTrue(mountDetails[NSFileSystemSize]);
                    XCTAssertTrue(mountDetails[NSFileSystemFreeSize]);
                    [[SDMountController sharedAPI] unmountVolumeWithName:@"SafeDrive" success:^(NSURL *mountURL, NSError *mountError) {
                        [expectation fulfill];
                    } failure:^(NSURL *mountURL, NSError *mountError) {
                        XCTFail(@"%@", mountError.localizedDescription);
                    }];
                    
                } failure:^(NSError *error) {
                    XCTFail(@"%@", error.localizedDescription);
                }];
            } failure:^(NSURL *mountURL, NSError *mountError) {
                XCTFail(@"%@", mountError.localizedDescription);
            }];
        } failure:^(NSError *apiError) {
            XCTFail(@"%@", apiError.localizedDescription);
        }];
    } failure:^(NSError *apiError) {
        XCTFail(@"%@", apiError.localizedDescription);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"test_SDMountController_startMountTaskWithVolumeName error: %@", error.localizedDescription);    
        }
    }];
}

- (void)test_SDSyncController_startSyncTaskWithFileURL {
    XCTAssertNotNil([SDSyncController sharedAPI]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_SDSyncController_startSyncTaskWithFileURL"];

    [[SDAPI sharedAPI] registerMachineWithUser:SDTestCredentialsUser password:SDTestCredentialsPassword success:^(NSString *sessionToken) {
        XCTAssertNotNil(sessionToken);
        [[SDAPI sharedAPI] accountStatusForUser:SDTestCredentialsUser success:^(NSDictionary *accountStatus) {
            XCTAssertNotNil(accountStatus);
            XCTAssertNotNil(accountStatus[@"host"]);
            XCTAssertNotNil(accountStatus[@"port"]);
            XCTAssertNotNil(accountStatus[@"status"]);
            XCTAssertNotNil(accountStatus[@"userName"]);
            
            NSLog(@"Account status: %@", accountStatus);
            
            NSString *remotePath = [NSString stringWithFormat:SDTestRemoteRsyncPath, [[NSHost currentHost] localizedName]];
            NSURL *serverURL = [NSURL SFTPURLForAccount:accountStatus[@"userName"] host:accountStatus[@"host"] port:accountStatus[@"port"] path:remotePath];
            
            NSURL *localURL = [NSURL fileURLWithPath:[SDTestLocalRsyncPath stringByStandardizingPath] isDirectory:YES];
            NSLog(@"Syncing: %@", localURL);
            
            [[SDSyncController sharedAPI] startSyncTaskWithLocalURL:localURL serverURL:serverURL password:SDTestCredentialsPassword restore:NO success:^(NSURL *syncURL, NSError *syncError) {
                XCTAssertNotNil(syncURL);
                [expectation fulfill];
            } failure:^(NSURL *syncURL, NSError *syncError) {
                XCTFail(@"%@", syncError.localizedDescription);
            }];
        } failure:^(NSError *apiError) {
            XCTFail(@"%@", apiError.localizedDescription);
        }];
    } failure:^(NSError *apiError) {
        XCTFail(@"%@", apiError.localizedDescription);
    }];
    [self waitForExpectationsWithTimeout:300 handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"test_SDSyncController_startSyncTaskWithLocalURL error: %@", error.localizedDescription);    
        }
    }];
}


- (void)test_SDSystemAPI_statusForMountpoint {
    XCTAssertNotNil([SDSystemAPI sharedAPI]);
    // test root since it should always work as a URL
    NSDictionary *mountDetails = [[SDSystemAPI sharedAPI] detailsForMount:[NSURL fileURLWithFileSystemRepresentation:"/\0" isDirectory:YES relativeToURL:nil]];
    XCTAssertNotNil(mountDetails);
    XCTAssertTrue(mountDetails[NSFileSystemSize]);
    XCTAssertTrue(mountDetails[NSFileSystemFreeSize]);
    NSLog(@"test_SDSystemAPI_statusForMountpoint: %@", mountDetails);
}

- (void)test_SDSystemAPI_insertCredentialsInKeychainForService {
    XCTAssertNotNil([SDSystemAPI sharedAPI]);
    NSError *keychainInsertError = [[SDSystemAPI sharedAPI] insertCredentialsInKeychainForService:SDServiceNameTesting account:SDTestCredentialsUser password:SDTestCredentialsPassword];
    if (keychainInsertError) {
        XCTFail(@"%@", keychainInsertError.localizedDescription);
        NSLog(@"test_SDSystemAPI_insertCredentialsInKeychainForService: %@", keychainInsertError.localizedDescription);
    }
    NSError *keychainRemoveError = [[SDSystemAPI sharedAPI] removeCredentialsInKeychainForService:SDServiceNameTesting account:SDTestCredentialsUser];
    if (keychainRemoveError) {
        XCTFail(@"%@", keychainRemoveError.localizedDescription);
        NSLog(@"test_SDSystemAPI_insertCredentialsInKeychainForService: %@", keychainRemoveError.localizedDescription);
    }
}


@end
