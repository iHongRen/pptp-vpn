//
//  HelperTool.h
//  com.cxy.PPTPVPN.HelpTool
//
//  Created by chen on 2018/8/5.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol HelperToolProtocol
- (void)executeShellPath:(NSString*)path arguments:(NSArray*)args withReply:(void(^)(NSError *error,NSString *outputString))reply;

- (void)executeShellCommand:(NSString*)command withReply:(void(^)(NSDictionary * errorInfo))reply;

- (void)executeShellSystemCommand:(NSString *)command withReply:(void (^)(NSInteger))reply;
@end

@interface HelperTool : NSObject
- (void)run;
@end
