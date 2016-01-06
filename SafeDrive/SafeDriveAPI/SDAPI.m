
//  Copyright (c) 2014 Infincia LLC. All rights reserved.
//

#import "SDAPI.h"
#import "SDSystemAPI.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

#import "HKTHashProvider.h"

@interface SDAPI ()
@property (nonatomic, readonly) AFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic, readonly) AFHTTPRequestOperationManager *apiManager;

@property SDSystemAPI *sharedSystemAPI;
@property NSURL *baseURL;
@end

@implementation SDAPI

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.sharedSystemAPI = [SDSystemAPI sharedAPI];
        


        _reachabilityManager = [AFNetworkReachabilityManager managerForDomain:SDAPIDomainTesting];

        [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown: {
                    //
                    break;
                }
                case AFNetworkReachabilityStatusNotReachable: {
                    //
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWWAN: {
                    //
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWiFi: {
                    //
                    break;
                }
                default: {
                    //
                    break;
                }
            }
        }];

        self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/1/", SDAPIDomainTesting]];

        _apiManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        self.apiManager.requestSerializer = [[AFJSONRequestSerializer alloc] init];
        [self.apiManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [self.apiManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        self.apiManager.responseSerializer = [[AFJSONResponseSerializer alloc] init];
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

-(void)setSessionToken:(NSString *)sessionToken {
    _privateSessionToken = sessionToken;
    [self.apiManager.requestSerializer setValue:_privateSessionToken forHTTPHeaderField:@"SD-Auth-Token"];
}

-(NSString *)sessionToken {
    NSDictionary *session = [self.sharedSystemAPI retrieveCredentialsFromKeychainForService:SDSessionServiceName];
    if (session) {
        [self.apiManager.requestSerializer setValue:session[@"password"] forHTTPHeaderField:@"SD-Auth-Token"];
        return session[@"password"];
    }
    return _privateSessionToken;
}

#pragma mark - Client registration

-(void)registerMachineWithUser:(NSString *)user password:(NSString *)password success:(SDAPIClientRegistrationSuccessBlock)successBlock failure:(SDFailureBlock)failureBlock {
    NSString *languageCode = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *os = [NSString stringWithFormat:@"OS X %@", self.sharedSystemAPI.currentOSVersion];
    NSString *macAddress = [self.sharedSystemAPI en0MAC];
    NSString *machineIdConcatenation = [macAddress stringByAppendingString:user];
    NSString *identifier = [HKTHashProvider sha256:[machineIdConcatenation dataUsingEncoding:NSUTF8StringEncoding]];

    
    NSDictionary *postParameters = @{ @"email": user, @"password": password, @"operatingSystem": os,   @"language": languageCode, @"uniqueClientId": identifier };
    
    [self.apiManager.requestSerializer setValue:nil forHTTPHeaderField:@"SD-Auth-Token"];

    [self.apiManager POST:@"client/register" parameters:postParameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        NSLog(@"Client registered: %@", response);
        self.sessionToken = response[@"token"];
        [self.sharedSystemAPI insertCredentialsInKeychainForService:SDSessionServiceName account:user password:response[@"token"]];
        successBlock(self.sessionToken);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSDictionary *responseObject = (NSDictionary *)operation.responseObject;
        if (responseObject) {
            NSString *message = responseObject[@"message"];
            NSError *responseError = [NSError errorWithDomain:SDErrorDomain code:SDAPIErrorUnknown userInfo:@{NSLocalizedDescriptionKey:  message}];
            failureBlock(responseError); 
            return;       
        }
        failureBlock(error);
    }];
}

-(void)accountStatusForUser:(NSString *)user success:(SDAPIAccountStatusBlock)successBlock failure:(SDFailureBlock)failureBlock {
    [self.apiManager GET:@"account/status" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *accountStatus = (NSDictionary *)responseObject;
        successBlock(accountStatus);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSDictionary *responseObject = (NSDictionary *)operation.responseObject;
        if (responseObject) {
            NSString *message = responseObject[@"message"];
            NSError *responseError = [NSError errorWithDomain:SDErrorDomain code:SDAPIErrorUnknown userInfo:@{NSLocalizedDescriptionKey:  message}];
            failureBlock(responseError); 
            return;       
        }
        failureBlock(error);
    }];
}

-(void)accountDetailsForUser:(NSString *)user success:(SDAPIAccountDetailsBlock)successBlock failure:(SDFailureBlock)failureBlock {
    [self.apiManager GET:@"account/details" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *accountDetails = (NSDictionary *)responseObject;
        successBlock(accountDetails);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSDictionary *responseObject = (NSDictionary *)operation.responseObject;
        if (responseObject) {
            NSString *message = responseObject[@"message"];
            NSError *responseError = [NSError errorWithDomain:SDErrorDomain code:SDAPIErrorUnknown userInfo:@{NSLocalizedDescriptionKey:  message}];
            failureBlock(responseError); 
            return;       
        }
        failureBlock(error);
    }];
}

#pragma mark - Unused 

-(void)getHostFingerprintList:(SDAPIFingerprintListSuccessBlock)successBlock failure:(SDFailureBlock)failureBlock {
    [self.apiManager GET:@"fingerprints" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        successBlock(response[@"fingerprints"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(error);
    }];
}


-(void)apiStatus:( SDSuccessBlock)successBlock failure:(SDFailureBlock)failureBlock {
    [self.apiManager GET:@"status" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        successBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(error);
    }];
}

@end
