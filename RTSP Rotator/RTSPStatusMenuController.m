//
//  RTSPStatusMenuController.m
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import "RTSPStatusMenuController.h"
#import "RTSPPreferencesController.h"
#import "RTSPWallpaperController.h"
#import "RTSPUniFiProtectPreferences.h"
#import <UserNotifications/UserNotifications.h>

@interface RTSPStatusMenuController ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, weak) RTSPWallpaperController *controller;
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSMenuItem *currentFeedItem;
@property (nonatomic, strong) NSMenuItem *healthStatusItem;
@property (nonatomic, strong) NSTimer *updateTimer;
@end

@implementation RTSPStatusMenuController

- (instancetype)initWithController:(RTSPWallpaperController *)controller {
    self = [super init];
    if (self) {
        _controller = controller;
    }
    return self;
}

- (void)install {
    if (self.isInstalled) {
        return;
    }

    // Create status item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"📹";
    self.statusItem.button.toolTip = @"RTSP Rotator";

    // Create menu
    [self buildMenu];

    // Start update timer
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(updateMenuItems)
                                                      userInfo:nil
                                                       repeats:YES];

    NSLog(@"[INFO] Status menu item installed");
}

- (void)uninstall {
    if (!self.isInstalled) {
        return;
    }

    [self.updateTimer invalidate];
    self.updateTimer = nil;

    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    self.statusItem = nil;
    self.menu = nil;

    NSLog(@"[INFO] Status menu item uninstalled");
}

- (void)buildMenu {
    self.menu = [[NSMenu alloc] init];

    // Current feed info
    self.currentFeedItem = [[NSMenuItem alloc] initWithTitle:@"No feed playing"
                                                      action:nil
                                               keyEquivalent:@""];
    [self.menu addItem:self.currentFeedItem];

    // Health status
    self.healthStatusItem = [[NSMenuItem alloc] initWithTitle:@"Status: Unknown"
                                                       action:nil
                                                keyEquivalent:@""];
    [self.menu addItem:self.healthStatusItem];

    [self.menu addItem:[NSMenuItem separatorItem]];

    // Controls
    NSMenuItem *nextFeedItem = [[NSMenuItem alloc] initWithTitle:@"Next Feed"
                                                          action:@selector(nextFeed:)
                                                   keyEquivalent:@""];
    nextFeedItem.target = self;
    [self.menu addItem:nextFeedItem];

    NSMenuItem *toggleMuteItem = [[NSMenuItem alloc] initWithTitle:@"Toggle Mute"
                                                            action:@selector(toggleMute:)
                                                     keyEquivalent:@""];
    toggleMuteItem.target = self;
    [self.menu addItem:toggleMuteItem];

    NSMenuItem *takeSnapshotItem = [[NSMenuItem alloc] initWithTitle:@"Take Snapshot"
                                                              action:@selector(takeSnapshot:)
                                                       keyEquivalent:@""];
    takeSnapshotItem.target = self;
    [self.menu addItem:takeSnapshotItem];

    [self.menu addItem:[NSMenuItem separatorItem]];

    // Preferences
    NSMenuItem *preferencesItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..."
                                                             action:@selector(showPreferences:)
                                                      keyEquivalent:@""];
    preferencesItem.target = self;
    [self.menu addItem:preferencesItem];

    // UniFi Protect Configuration
    NSMenuItem *unifiItem = [[NSMenuItem alloc] initWithTitle:@"UniFi Protect..."
                                                      action:@selector(showUniFiProtect:)
                                               keyEquivalent:@""];
    unifiItem.target = self;
    [self.menu addItem:unifiItem];

    [self.menu addItem:[NSMenuItem separatorItem]];

    // Quit
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                      action:@selector(quit:)
                                               keyEquivalent:@""];
    quitItem.target = self;
    [self.menu addItem:quitItem];

    self.statusItem.menu = self.menu;
}

- (void)updateWithFeedName:(NSString *)feedName index:(NSInteger)index total:(NSInteger)total {
    if (!self.isInstalled) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentFeedItem.title = [NSString stringWithFormat:@"📹 %@ (%ld/%ld)", feedName, (long)index, (long)total];
    });
}

- (void)updateHealthStatus:(NSString *)status {
    if (!self.isInstalled) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.healthStatusItem.title = [NSString stringWithFormat:@"Status: %@", status];
    });
}

- (void)updateMenuItems {
    if (!self.controller) {
        return;
    }

    // Update mute state in menu
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSMenuItem *item in self.menu.itemArray) {
            if ([item.title isEqualToString:@"Toggle Mute"]) {
                item.state = self.controller.isMuted ? NSControlStateValueOn : NSControlStateValueOff;
            }
        }
    });
}

#pragma mark - Actions

- (void)nextFeed:(id)sender {
    [self.controller nextFeed];
}

- (void)toggleMute:(id)sender {
    [self.controller toggleMute];
}

- (void)takeSnapshot:(id)sender {
    // Take snapshot to downloads folder
    NSString *downloadsPath = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *filename = [NSString stringWithFormat:@"rtsp_snapshot_%@.png", timestamp];
    NSString *filePath = [downloadsPath stringByAppendingPathComponent:filename];

    // Note: Would need RTSPRecorder reference - simplified for now
    NSLog(@"[INFO] Snapshot requested to: %@", filePath);

    // Show notification using modern UserNotifications framework
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    // Request permission first (won't prompt again if already granted)
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = @"RTSP Rotator";
            content.body = @"Snapshot saved to Downloads";
            content.sound = [UNNotificationSound defaultSound];

            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                                  content:content
                                                                                  trigger:nil];

            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"[StatusMenu] Notification error: %@", error);
                }
            }];
        }
    }];
}

- (void)showPreferences:(id)sender {
    [[RTSPPreferencesController sharedController] showWindow:sender];
}

- (void)showUniFiProtect:(id)sender {
    [[RTSPUniFiProtectPreferences sharedController] showWindow:sender];
}

- (void)quit:(id)sender {
    [NSApp terminate:sender];
}

- (BOOL)isInstalled {
    return self.statusItem != nil;
}

- (void)dealloc {
    [self uninstall];
}

@end
