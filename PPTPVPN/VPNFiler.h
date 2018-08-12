//
//  VPNFiler.h
//  PPTPVPN
//
//  Created by chen on 2018/8/6.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString *const PPTPVPNConfigFileName;
extern NSString *const PPTPVPNLogFileDirectory;

@interface VPNFiler : NSObject

/**
 --- config ---
 remoteaddress \"vpn.ihongren.com\"\n\
 user \"ihongren\"\n\
 password \"12345678\"\n\
 */
+ (void)writeVPNFileHost:(NSString*)remoteaddress
                    user:(NSString*)user
                password:(NSString*)password
                   block:(void(^)(NSError *error))complete;
@end
