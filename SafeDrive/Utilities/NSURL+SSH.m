
//  Copyright (c) 2015 Infincia LLC. All rights reserved.
//

#import "NSURL+SSH.h"

@implementation NSURL (SSH)

+(NSURL *)SSHURLForAccount:(NSString *)account
                  password:(NSString *)password
                      host:(NSString *)host
                      port:(NSNumber *)port
                      path:(NSString *)path {
    // ssh://user:password@host.domain.org

    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSString *escapedAccount = [account stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSString *escapedPassword = [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];


    NSString *urlString = [NSString stringWithFormat:@"ssh://%@:%@@%@:%@/%@",escapedAccount, escapedPassword, host, port, escapedPath];
    return [NSURL URLWithString:urlString];
}

@end