
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//


#import "SDServiceXPCRouter.h"
#import "SDServiceXPCProtocol.h"

#import "SafeDrive-Swift.h"
#import "SDAppXPCProtocol.h"

@import ServiceManagement;

@interface SDServiceXPCRouter ()
@property NSXPCConnection *serviceConnection;
@property NSXPCListener *appListener;

@property NSDecimalNumber *currentServiceVersion;

@property AppXPCDelegate *appXPCDelegate;

@end

@implementation SDServiceXPCRouter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.appXPCDelegate = [[AppXPCDelegate alloc] init];
        self.appListener = [self createAppListener];
        
        self.currentServiceVersion = [NSDecimalNumber decimalNumberWithString:@"0"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self serviceReconnectionLoop];
        });
    }
    return self;
}

-(NSXPCConnection *)createServiceConnection {
    NSXPCConnection *newConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"io.safedrive.SafeDrive.Service" options:0];
    NSXPCInterface *serviceInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SDServiceXPCProtocol)];
    newConnection.remoteObjectInterface = serviceInterface;
    __weak typeof(self) weakSelf = self;
    newConnection.interruptionHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf) {

            }
        });
    };
    newConnection.invalidationHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf) {
                weakSelf.serviceConnection = nil;
            }
        });
    };
    [newConnection resume];
    return newConnection;
}

-(BOOL)ensureServiceIsRunning {
    #if DEBUG
    // temporary kill/restart for background service until proper calls are implemented
    // NOTE: This should not happen in production! Background service should NOT be killed arbitrarily.
    //
    //[NSThread sleepForTimeInterval:5];
    #endif
    //CFDictionaryRef diref = SMJobCopyDictionary( kSMDomainUserLaunchd, (CFStringRef)@"io.safedrive.SafeDrive.Service");
    //NSLog(@"Job status: %@", (NSDictionary *)CFBridgingRelease(diref));
    //CFRelease(diref);
    return YES;
    //return 
}

-(void)serviceReconnectionLoop {
    for (;;) {
        //[self ensureServiceIsRunning];
        if (!self.serviceConnection) {

            self.serviceConnection = [self createServiceConnection];
            
            [[self.serviceConnection remoteObjectProxyWithErrorHandler:^(NSError * error) {

            }] sendAppEndpoint:self.appListener.endpoint reply:^(BOOL success) {

            }];
            [NSThread sleepForTimeInterval:1];
        }
        [[self.serviceConnection  remoteObjectProxyWithErrorHandler:^(NSError * error) {

        }] protocolVersion:^(NSNumber *version) {

            if ([version integerValue] != kSDServiceXPCProtocolVersion) {
                NSLog(@"Service needs to be updated!!!!!");
                [self.serviceConnection invalidate];
            }
        }];
        [NSThread sleepForTimeInterval:5];
    }
}




#pragma mark - App Listener Delegate

-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {

    NSXPCInterface *serviceInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SDAppXPCProtocol)];
    newConnection.exportedInterface = serviceInterface;
    newConnection.exportedObject = self.appXPCDelegate;
    
    [newConnection resume];
    return YES;
    
}

#pragma mark - App Listener Setup

-(NSXPCListener *)createAppListener {
    NSXPCListener *newListener = [NSXPCListener anonymousListener];
    newListener.delegate = self;
    [newListener resume];
    return newListener;
}

@end
