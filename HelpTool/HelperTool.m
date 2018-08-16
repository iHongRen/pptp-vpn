//
//  HelperTool.m
//  com.cxy.PPTPVPN.HelpTool
//
//  Created by chen on 2018/8/5.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//

#import "HelperTool.h"

@interface HelperTool () <NSXPCListenerDelegate, HelperToolProtocol>
@property (atomic, strong, readwrite) NSXPCListener *listener;

@end

@implementation HelperTool

- (id)init {
    if (self = [super init]) {
        // Set up our XPC listener to handle requests on our Mach service.
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.cxy.PPTPVPN.HelpTool"];
        self->_listener.delegate = self;                
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
- (void)executeShellPath:(NSString*)path arguments:(NSArray*)args withReply:(void(^)(NSError *error, NSString *outputString))reply {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSTask *task = [NSTask new];
        task.launchPath = path;
        task.arguments = args;

        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];

        [task setStandardError:[NSPipe pipe]];
        NSError *err;
        [task launchAndReturnError:&err];
        [task waitUntilExit];

        NSData *outputData = [[task.standardOutput fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding: NSUTF8StringEncoding];
        !reply?:reply(err, output);
    });
}


- (void)executeShellCommand:(NSString*)command withReply:(void(^)(NSDictionary * errorInfo))reply {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *script = [NSString stringWithFormat:@"do shell script \"%@\"",command];
        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
        NSDictionary *dicError = nil;
        [appleScript executeAndReturnError:&dicError];
        !reply?:reply(dicError);
    });
}

- (void)executeShellSystemCommand:(NSString *)command withReply:(void (^)(NSInteger))reply {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int res = system([command UTF8String]);
        !reply?:reply(res);
    });
}

@end
