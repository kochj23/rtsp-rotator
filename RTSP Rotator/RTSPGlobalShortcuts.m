//
//  RTSPGlobalShortcuts.m
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import "RTSPGlobalShortcuts.h"

// Shortcut IDs
typedef NS_ENUM(OSType, RTSPShortcutID) {
    RTSPShortcutIDNextFeed = 'next',
    RTSPShortcutIDPreviousFeed = 'prev',
    RTSPShortcutIDToggleMute = 'mute',
    RTSPShortcutIDTakeSnapshot = 'snap',
    RTSPShortcutIDPauseRotation = 'paus'
};

// Shortcut handler
OSStatus RTSPGlobalShortcutHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData);

@interface RTSPGlobalShortcuts ()
@property (nonatomic, assign) EventHotKeyRef nextFeedHotKeyRef;
@property (nonatomic, assign) EventHotKeyRef previousFeedHotKeyRef;
@property (nonatomic, assign) EventHotKeyRef toggleMuteHotKeyRef;
@property (nonatomic, assign) EventHotKeyRef takeSnapshotHotKeyRef;
@property (nonatomic, assign) EventHotKeyRef pauseRotationHotKeyRef;
@property (nonatomic, assign) EventHandlerRef handlerRef;
@end

@implementation RTSPGlobalShortcuts

+ (instancetype)sharedManager {
    static RTSPGlobalShortcuts *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RTSPGlobalShortcuts alloc] init];
    });
    return sharedInstance;
}

- (void)registerShortcuts {
    [self unregisterShortcuts];

    // Install event handler
    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;

    InstallEventHandler(GetApplicationEventTarget(),
                       &RTSPGlobalShortcutHandler,
                       1,
                       &eventType,
                       (__bridge void *)self,
                       &_handlerRef);

    // Register shortcuts
    // Ctrl+Cmd+Right Arrow - Next Feed
    [self registerHotKey:&_nextFeedHotKeyRef
                  keyCode:124  // Right arrow
               modifiers:(controlKey | cmdKey)
                      id:RTSPShortcutIDNextFeed];

    // Ctrl+Cmd+Left Arrow - Previous Feed
    [self registerHotKey:&_previousFeedHotKeyRef
                  keyCode:123  // Left arrow
               modifiers:(controlKey | cmdKey)
                      id:RTSPShortcutIDPreviousFeed];

    // Ctrl+Cmd+M - Toggle Mute
    [self registerHotKey:&_toggleMuteHotKeyRef
                  keyCode:46  // M
               modifiers:(controlKey | cmdKey)
                      id:RTSPShortcutIDToggleMute];

    // Ctrl+Cmd+S - Take Snapshot
    [self registerHotKey:&_takeSnapshotHotKeyRef
                  keyCode:1  // S
               modifiers:(controlKey | cmdKey)
                      id:RTSPShortcutIDTakeSnapshot];

    // Ctrl+Cmd+P - Pause Rotation
    [self registerHotKey:&_pauseRotationHotKeyRef
                  keyCode:35  // P
               modifiers:(controlKey | cmdKey)
                      id:RTSPShortcutIDPauseRotation];

    NSLog(@"[INFO] Global shortcuts registered");
    NSLog(@"[INFO]   Ctrl+Cmd+Right: Next Feed");
    NSLog(@"[INFO]   Ctrl+Cmd+Left: Previous Feed");
    NSLog(@"[INFO]   Ctrl+Cmd+M: Toggle Mute");
    NSLog(@"[INFO]   Ctrl+Cmd+S: Take Snapshot");
    NSLog(@"[INFO]   Ctrl+Cmd+P: Pause Rotation");
}

- (void)registerHotKey:(EventHotKeyRef *)hotKeyRef
               keyCode:(UInt32)keyCode
             modifiers:(UInt32)modifiers
                    id:(OSType)hotKeyID {

    EventHotKeyID hotKeyIDStruct;
    hotKeyIDStruct.signature = 'rtsp';
    hotKeyIDStruct.id = hotKeyID;

    RegisterEventHotKey(keyCode,
                       modifiers,
                       hotKeyIDStruct,
                       GetApplicationEventTarget(),
                       0,
                       hotKeyRef);
}

- (void)unregisterShortcuts {
    if (self.nextFeedHotKeyRef) {
        UnregisterEventHotKey(self.nextFeedHotKeyRef);
        self.nextFeedHotKeyRef = NULL;
    }

    if (self.previousFeedHotKeyRef) {
        UnregisterEventHotKey(self.previousFeedHotKeyRef);
        self.previousFeedHotKeyRef = NULL;
    }

    if (self.toggleMuteHotKeyRef) {
        UnregisterEventHotKey(self.toggleMuteHotKeyRef);
        self.toggleMuteHotKeyRef = NULL;
    }

    if (self.takeSnapshotHotKeyRef) {
        UnregisterEventHotKey(self.takeSnapshotHotKeyRef);
        self.takeSnapshotHotKeyRef = NULL;
    }

    if (self.pauseRotationHotKeyRef) {
        UnregisterEventHotKey(self.pauseRotationHotKeyRef);
        self.pauseRotationHotKeyRef = NULL;
    }

    if (self.handlerRef) {
        RemoveEventHandler(self.handlerRef);
        self.handlerRef = NULL;
    }

    NSLog(@"[INFO] Global shortcuts unregistered");
}

- (void)handleShortcutWithID:(OSType)hotKeyID {
    switch (hotKeyID) {
        case RTSPShortcutIDNextFeed:
            NSLog(@"[INFO] Global shortcut: Next Feed");
            if (self.onNextFeed) self.onNextFeed();
            break;

        case RTSPShortcutIDPreviousFeed:
            NSLog(@"[INFO] Global shortcut: Previous Feed");
            if (self.onPreviousFeed) self.onPreviousFeed();
            break;

        case RTSPShortcutIDToggleMute:
            NSLog(@"[INFO] Global shortcut: Toggle Mute");
            if (self.onToggleMute) self.onToggleMute();
            break;

        case RTSPShortcutIDTakeSnapshot:
            NSLog(@"[INFO] Global shortcut: Take Snapshot");
            if (self.onTakeSnapshot) self.onTakeSnapshot();
            break;

        case RTSPShortcutIDPauseRotation:
            NSLog(@"[INFO] Global shortcut: Pause Rotation");
            if (self.onPauseRotation) self.onPauseRotation();
            break;
    }
}

- (void)dealloc {
    [self unregisterShortcuts];
}

@end

#pragma mark - Global Handler Function

OSStatus RTSPGlobalShortcutHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
    EventHotKeyID hotKeyID;
    GetEventParameter(event,
                     kEventParamDirectObject,
                     typeEventHotKeyID,
                     NULL,
                     sizeof(hotKeyID),
                     NULL,
                     &hotKeyID);

    RTSPGlobalShortcuts *manager = (__bridge RTSPGlobalShortcuts *)userData;
    [manager handleShortcutWithID:hotKeyID.id];

    return noErr;
}
