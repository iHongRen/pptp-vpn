//
//  HelperTool.h
//  com.cxy.PPTPVPN.HelpTool
//
//  Created by chen on 2018/8/5.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol HelperToolProtocol
- (void)executeShellCommand:(NSString*)command withReply:(void(^)(NSDictionary * errorInfo))reply;
- (void)executeShellPath:(NSString*)path arguments:(NSArray*)args withReply:(void(^)(NSError *error))reply;
@end

@interface HelperTool : NSObject
- (void)run;

@end
