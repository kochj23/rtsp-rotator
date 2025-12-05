//
//  main.m
//  RTSP Rotator
//
//  Standard macOS application entry point
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];

        // Set delegate
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [application setDelegate:delegate];

        // Set activation policy to regular app
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        // Activate app
        [NSApp activateIgnoringOtherApps:YES];

        // Run app
        [NSApp run];
    }
    return EXIT_SUCCESS;
}
