
//  Copyright (c) 2014 Infincia LLC. All rights reserved.
//

#import "SDAPI.h"

@implementation SDAPI

- (instancetype)init {
    self = [super init];
    if (self) {
        //
    }
    return self;
}

- (void)dealloc {
    // never
}





# pragma mark
# pragma mark Public API

+(SDAPI *)sharedAPI {
    static SDAPI *localInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localInstance = [[SDAPI alloc] init];
    });
    return localInstance;
}

-(void)authenticateWithUser:(NSString *)user password:(NSString *)password success:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock {
}



@end
