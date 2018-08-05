//
//  HelperTool.m
//  com.cxy.PPTPVPN.HelpTool
//
//  Created by chen on 2018/8/5.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//

#import "HelperTool.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

@interface HelperTool () <NSXPCListenerDelegate, HelperToolProtocol>

@property (atomic, strong, readwrite) NSXPCListener *listener;

@end

@implementation HelperTool

- (id)init {
    if (self = [super init]) {
        // Set up our XPC listener to handle requests on our Mach service.
        self.listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.cxy.PPTPVPN.HelpTool"];
        self.listener.delegate = self;
    }
    return self;
}

- (void)run {
    // Tell the XPC listener to start processing requests.
    
    [self.listener resume];
    
    // Run the run loop forever.
    
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
// Called by our XPC listener when a new connection comes in.  We configure the connection
// with our protocol and ourselves as the main object.
{
    assert(listener == self.listener);
#pragma unused(listener)
    assert(newConnection != nil);
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}


#pragma mark - protocol
- (void)executeShellCommand:(NSString*)command withReply:(void(^)(NSDictionary * errorInfo))reply {
    NSString *script = [NSString stringWithFormat:@"do shell script \"%@\"",command];
    
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    NSDictionary *dicError = @{};
    if([appleScript executeAndReturnError:&dicError]) {
        reply(dicError);
    } else {
        reply(dicError);
    }
}
@end
