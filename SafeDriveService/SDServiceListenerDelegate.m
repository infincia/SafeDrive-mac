
//  Copyright (c) 2014 Infincia LLC. All rights reserved.
//


#import "SDServiceListenerDelegate.h"

@interface SDServiceListenerDelegate ()
@property NSXPCListenerEndpoint *appEndpoint;
@end

@implementation SDServiceListenerDelegate

-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    NSLog(@"SafeDrive service accepted connection: %@", newConnection);
    NSXPCInterface *serviceInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SDServiceXPCProtocol)];
    newConnection.exportedInterface = serviceInterface;
    newConnection.exportedObject = self;
    
    [newConnection resume];
    return YES;
    
}


-(void)sendMessage:(NSString *)message reply:(void (^)(NSString *reply))replyBlock {
    NSLog(@"Helper got message: %@", message);
    replyBlock([NSString stringWithFormat:@"Got message: %@", message]);
}

-(void)ping:(void (^)(NSString *reply))replyBlock {
    replyBlock(@"ack");
}

-(void)protocolVersion:(void (^)(NSNumber *version))replyBlock {
    NSLog(@"Helper got service version request");
    replyBlock(@(kSDServiceXPCProtocolVersion));
}

-(void)getAppEndpoint:(void (^)(NSXPCListenerEndpoint *endpoint))replyBlock {
    replyBlock(self.appEndpoint);
}


-(void)sendAppEndpoint:(NSXPCListenerEndpoint *)endpoint reply:(void (^)(BOOL success))replyBlock {
    self.appEndpoint = endpoint;
    replyBlock(YES);
}

@end
