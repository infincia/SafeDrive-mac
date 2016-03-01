
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

@import Foundation;

@interface SDSyncController : NSObject

-(void)startSyncTaskWithLocalURL:(NSURL *)localURL serverURL:(NSURL *)serverURL password:(NSString *)password restore:(BOOL)restore success:(SDSyncResultBlock)successBlock failure:(SDSyncResultBlock)failureBlock;

@end
