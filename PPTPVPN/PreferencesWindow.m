//
//  ServerWindowController.m
//  PPTPVPN
//
//  Created by chen on 2018/8/4.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//

#import "PreferencesWindow.h"
#import "VPNManager.h"

@interface PreferencesWindow ()

@property (weak) IBOutlet NSTextField *host;
@property (weak) IBOutlet NSTextField *username;
@property (weak) IBOutlet NSSecureTextField *password;
@property (weak) IBOutlet NSTextField *errorTip;

@end

@implementation PreferencesWindow

- (void)windowDidLoad {
    [super windowDidLoad];
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:self];
    
    [self.host becomeFirstResponder];
    self.host.stringValue = [VPNManager shared].host;
    self.username.stringValue = [VPNManager shared].username;;
    self.password.stringValue = [VPNManager shared].password;;
}

- (IBAction)confirmClick:(id)sender {
    VPNManager *shared = [VPNManager shared];
    shared.host = self.host.stringValue;
    shared.username = self.username.stringValue;
    shared.password = self.password.stringValue;
    [shared connect:^(NSError *err) {
        if (err) {
            self.errorTip.hidden = NO;
            self.errorTip.stringValue = err.localizedDescription;
        } else {
            self.errorTip.hidden = YES;
            self.errorTip.stringValue = @"";
            [self.window performClose:self];
        }
    }];
}


- (IBAction)cancelClick:(id)sender {
    [self.window performClose:self];
}

@end
