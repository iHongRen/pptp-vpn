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
- (void)executeShellPath:(NSString*)path arguments:(NSArray*)args withReply:(void(^)(NSError *error, NSString *outputString, BOOL success))reply {
//    NSURL *url = [NSURL fileURLWithPath:path];
//    NSError *err;
//    [NSTask launchedTaskWithExecutableURL:url arguments:args error:&err terminationHandler:nil];
//    reply(err);
    
    
//    NSTask *task = [NSTask new];
//
//    [task setLaunchPath:path];
////    [task setCurrentDirectoryPath:pppdFolder];
//    [task setArguments:args];
//
//    NSPipe *pipe = [NSPipe pipe];
//    [task setStandardOutput:pipe];
//    //    [task setStandardError:pipe];
//    [task setStandardInput:[NSPipe pipe]];
//
//    NSMutableString *output = [NSMutableString string];
//    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle * _Nonnull file) {
//        NSData *data = [file availableData];
//        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        [output appendString:str];
//
//        reply(nil,str, 0);
//
//    }];
//
//    [task launch];
//    return;
//    bool connected = false;
//    while (!connected) {
//        reply(nil,output, connected);
//
//        if ([output containsString:@"pptp_wait_input: Address added"]) {
//            connected = true;
//        }
//
//        if (![task isRunning]) {
//            connected = false;
//            break;
//        }
//
//        usleep(500);
//    }
//
//    reply(nil,output, connected);
    
    NSPipe* pipe = [NSPipe pipe];
    
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath: path];
    [task setArguments:args];
    [task setStandardOutput:pipe];
    
    NSFileHandle* file = [pipe fileHandleForReading];
    [task launch];
    
    NSString *s = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    reply(nil, s, 0);
}

- (void)executeShellCommand:(NSString*)command withReply:(void(^)(NSDictionary * errorInfo))reply {

//    int res = system([command UTF8String]);
    

//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        reply(@{@"x":@(1)});
//        NSString *script = [NSString stringWithFormat:@"do shell script \"%@\"",command];
//        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
//        NSDictionary *dicError;
//        if([appleScript executeAndReturnError:&dicError]) {
//            reply(nil);
//        } else {
//            reply(dicError);
//        }
//    });
  
}


@end
