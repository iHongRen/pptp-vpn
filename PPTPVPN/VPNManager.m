//
//  VPNManager.m
//  PPTPVPN
//
//  Created by chen on 2018/8/4.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//  https://github.com/iHongRen/pptp-vpn

#import "VPNManager.h"

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "HelperTool.h"
#import "VPNFiler.h"

#define __SafeBlock(block, ...) (!block?:block(__VA_ARGS__))

#ifndef dispatch_block_main_async_safe
#define dispatch_block_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif


#define __SafeMainQueueBlock(block, ...)\
dispatch_block_main_async_safe(^{\
    __SafeBlock(block, __VA_ARGS__);\
NSLog(@"dfdafds");\
});

@interface VPNManager()

@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;
@property (nonatomic, copy) VPNConnectChangedBlock connectChangedBlock;
@end

@implementation VPNManager

+ (instancetype)shared {
    static VPNManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
        [shared getConfig];        
    });
    return shared;
}

- (void)getConfig {
    self.host = [[NSUserDefaults standardUserDefaults] objectForKey:@"pptp.vpn.host"]?:@"";
    self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"pptp.vpn.username"]?:@"";
    
    NSString *storedPassword = [[NSUserDefaults standardUserDefaults] objectForKey:@"pptp.vpn.password"]?:@"";
    self.password = storedPassword.length ? [storedPassword substringFromIndex:1] : @"";
    
    self.status = VPNStatusDisConnect;
}

- (void)setHost:(NSString *)host {
    _host = host;
    [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"pptp.vpn.host"];
}

- (void)setUsername:(NSString *)username {
    _username = username;
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"pptp.vpn.username"];
}

- (void)setPassword:(NSString *)password {
    _password = password;
    NSString *storePassword = [NSString stringWithFormat:@"a%@",password?:@""];
    [[NSUserDefaults standardUserDefaults] setObject:storePassword forKey:@"pptp.vpn.password"];
}

- (void)setStatus:(VPNStatus)status {
    _status = status;
    __SafeBlock(self.connectChangedBlock, status);
}

- (void)connect:(VPNConnectBlock)block {
    if (self.status == VPNStatusConnected) {
        [self disConnect:nil];
    }
    
    self.status = VPNStatusConnecting;
    [self executeShellPath:@"/usr/sbin/pppd" arguments:@[@"call",PPTPVPNConfigFileName] block:^(NSError *err, NSString *output) {
        if (output.length) {
            [self writeLog:output];
        }
        if ([output containsString:@"pptp_wait_input: Address added"]) {
            self.status = VPNStatusConnected;
            __SafeBlock(block, nil);

        } else {
            self.status = VPNStatusDisConnect;
            __SafeBlock(block, nil);
        }
    }];
}

- (void)disConnect:(VPNConnectBlock)block {
    self.status = VPNStatusConnecting;
    [self executeShellPath:@"/usr/bin/killall" arguments:@[@"pppd"] block:^(NSError *err, NSString *output) {
        if (!err) {
            self.status = VPNStatusDisConnect;
        }
        __SafeBlock(block, err);
    }];
}

- (void)connectChanged:(VPNConnectChangedBlock)block {
    self.connectChangedBlock = block;
}

- (void)openLog {
    [self executeShellPath:@"/usr/bin/open" arguments:@[PPTPVPNLogFileDirectory] block:^(NSError *err, NSString *output) {
        [self logErrorIfExist:err];
    }];
}

- (void)writeLog:(NSString*)log {
    NSString *args = [NSString stringWithFormat:@"echo \"%@\" >> %@",log,PPTPVPNLogFileDirectory];
    [self executeShellPath:@"/bin/bash" arguments:@[@"-c", args] block:^(NSError *err, NSString *output) {
        [self logErrorIfExist:err];
    }];
}

- (void)executeShellPath:(NSString*)path arguments:(NSArray*)args block:(void(^)(NSError *error,NSString *output))block {
    [self connectAndexecuteCommandBlock:^(NSError *err) {
        if (err) {
            [self logErrorIfExist:err];
            __SafeBlock(block, err, nil);
        } else {
            [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
                if (error) {
                    [self logErrorIfExist:error];
                    __SafeBlock(block, err, nil);
                }
            }] executeShellPath:path arguments:args withReply:^(NSError *errorInfo, NSString *outputString) {
                NSLog(@"output: %@", outputString);
                [self logErrorIfExist:errorInfo];
                dispatch_block_main_async_safe(^{
                    __SafeBlock(block,errorInfo, outputString);
                });
            }];
        }
    }];
}

- (void)connectToHelperTool
// Ensures that we're connected to our helper tool.
{
    assert([NSThread isMainThread]);
    if (self.helperToolConnection == nil) {
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.cxy.PPTPVPN.HelpTool" options:NSXPCConnectionPrivileged];
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        // We can ignore the retain cycle warning because a) the retain taken by the
        // invalidation handler block is released by us setting it to nil when the block
        // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
        // will be released when that operation completes and the operation itself is deallocated
        // (notably self does not have a reference to the NSBlockOperation).
        self.helperToolConnection.invalidationHandler = ^{
            // If the connection gets invalidated then, on the main thread, nil out our
            // reference to it.  This ensures that we attempt to rebuild it the next time around.
            self.helperToolConnection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.helperToolConnection = nil;
                NSLog(@"connection invalidated\n");
            }];
        };
#pragma clang diagnostic pop
        [self.helperToolConnection resume];
    }

}

- (void)connectAndexecuteCommandBlock:(void(^)(NSError *))commandBlock
// Connects to the helper tool and then executes the supplied command block on the
// main thread, passing it an error indicating if the connection was successful.
{
    assert([NSThread isMainThread]);
    
    // Ensure that there's a helper tool connection in place.
    
    [self connectToHelperTool];
    
    // Run the command block.  Note that we never error in this case because, if there is
    // an error connecting to the helper tool, it will be delivered to the error handler
    // passed to -remoteObjectProxyWithErrorHandler:.  However, I maintain the possibility
    // of an error here to allow for future expansion.
    
    commandBlock(nil);
}

- (void)logErrorIfExist:(NSError *)error
// Logs the error to the text view.
{
    // any thread
//    assert(error != nil);
    if ([error isKindOfClass:[NSError class]]) {
        NSLog(@"error: %@ /  %@ / %@\n", error.localizedDescription, [error domain], @([error code]));
    }
}
@end
