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
    
    NSTask *task = [NSTask new];
    task.launchPath = path;
    task.arguments = args;

    NSPipe *pipe = [NSPipe pipe];
//    __block NSString *outputString = @"";
//    pipe.fileHandleForReading.readabilityHandler = ^ (NSFileHandle *fileHandle) {
//        NSData *data = [fileHandle availableData];
//        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"read: %@", str);
//        outputString = [outputString stringByAppendingString:str];
//        !reply?:reply(nil, str);
//
//        if ([str containsString:@"pptp_wait_input: Address added"]) {
//            !reply?:reply(nil, @"ss");
//        }
//    };
    [task setStandardOutput:pipe];

    [task setStandardError:[NSPipe pipe]];
    NSError *err;
    [task launchAndReturnError:&err];
    [task waitUntilExit];

    NSData *outputData = [[task.standardOutput fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding: NSUTF8StringEncoding];
    !reply?:reply(err, output);
}


- (void)executeShellCommand:(NSString*)command withReply:(void(^)(NSDictionary * errorInfo))reply {
    NSString *script = [NSString stringWithFormat:@"do shell script \"%@\"",command];
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    NSDictionary *dicError = nil;
    [appleScript executeAndReturnError:&dicError];
    if (dicError) {
        !reply?:reply(dicError);
    } else {
        !reply?:reply(nil);
    }
}

- (void)executeShellSystemCommand:(NSString *)command withReply:(void (^)(NSInteger))reply {
    int res = system([command UTF8String]);
    !reply?:reply(res);
}

@end
