# RTSP Rotator API Documentation

This document provides detailed API documentation for the RTSP Rotator application classes and methods.

## Table of Contents

- [RTSPWallpaperWindow](#rtspwallpaperwindow)
- [RTSPWallpaperController](#rtspwallpapercontroller)
- [Functions](#functions)
- [Usage Examples](#usage-examples)

---

## RTSPWallpaperWindow

A custom `NSWindow` subclass that allows the RTSP viewer window to become key and main window while maintaining desktop-level display.

### Inheritance

```
NSObject → NSResponder → NSWindow → RTSPWallpaperWindow
```

### Overview

This window class overrides default window behavior to enable keyboard and mouse event handling while the window is displayed at the desktop level (behind other windows).

### Methods

#### canBecomeKeyWindow

```objc
- (BOOL)canBecomeKeyWindow;
```

**Returns:** `YES` to allow the window to receive keyboard events.

**Discussion:** By default, borderless windows at the desktop level cannot become key windows. This override enables keyboard input handling.

---

#### canBecomeMainWindow

```objc
- (BOOL)canBecomeMainWindow;
```

**Returns:** `YES` to allow the window to become the main window.

**Discussion:** Enables the window to appear as the active window in the application menu bar.

---

## RTSPWallpaperController

Main controller class that manages RTSP feed rotation, VLC media playback, and window lifecycle.

### Inheritance

```
NSObject → RTSPWallpaperController
```

### Protocols

- `VLCMediaPlayerDelegate`

### Properties

#### feeds

```objc
@property (nonatomic, strong) NSArray<NSString *> *feeds;
```

Array of RTSP feed URL strings. This property is immutable after initialization (array is copied).

---

#### currentIndex

```objc
@property (nonatomic, assign) NSUInteger currentIndex;
```

Zero-based index of the currently playing feed in the `feeds` array.

---

#### player

```objc
@property (nonatomic, strong) VLCMediaPlayer *player;
```

VLCKit media player instance used for RTSP stream playback.

---

#### window

```objc
@property (nonatomic, strong) RTSPWallpaperWindow *window;
```

The main application window displayed at desktop level.

---

#### isMuted

```objc
@property (nonatomic, assign) BOOL isMuted;
```

Audio mute state. `YES` indicates audio is muted, `NO` indicates audio is playing.

**Default:** `YES` (muted)

---

#### rotationTimer

```objc
@property (nonatomic, strong) NSTimer *rotationTimer;
```

Timer that triggers automatic feed rotation at the configured interval.

---

#### rotationInterval

```objc
@property (nonatomic, assign) NSTimeInterval rotationInterval;
```

Time interval in seconds between automatic feed rotations.

**Default:** 60.0 seconds

**Valid Range:** Must be greater than 0, otherwise defaults to 60.0

---

### Initialization Methods

#### initWithFeeds:rotationInterval:

```objc
- (instancetype)initWithFeeds:(NSArray<NSString *> *)feeds
             rotationInterval:(NSTimeInterval)interval;
```

Designated initializer for creating a controller with custom feeds and rotation interval.

**Parameters:**
- `feeds`: Array of RTSP URL strings. Pass `nil` or empty array to use default feeds.
- `interval`: Rotation interval in seconds. Must be greater than 0, otherwise defaults to 60.0.

**Returns:** Initialized `RTSPWallpaperController` instance.

**Discussion:**
- The feeds array is validated and copied internally
- Invalid or empty feeds array results in default feeds being used
- Invalid interval (≤ 0) results in default interval of 60 seconds

**Example:**
```objc
NSArray *feeds = @[
    @"rtsp://camera1.local/stream",
    @"rtsp://camera2.local/stream"
];
RTSPWallpaperController *controller =
    [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                   rotationInterval:30.0];
```

---

#### init

```objc
- (instancetype)init;
```

Convenience initializer that calls `initWithFeeds:rotationInterval:` with `nil` feeds and 60 second interval.

**Returns:** Initialized controller with default settings.

---

### Lifecycle Methods

#### start

```objc
- (void)start;
```

Starts the RTSP rotator by initializing the window, player, and rotation timer.

**Discussion:**
- All UI operations are dispatched to the main thread
- Window is created at desktop level
- VLC player is configured for the window's content view
- First feed begins playing immediately
- Rotation timer is started

**Must be called on:** Any thread (automatically dispatches to main queue)

**Example:**
```objc
RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] init];
[controller start];
```

---

#### stop

```objc
- (void)stop;
```

Stops the RTSP rotator and cleans up all resources.

**Discussion:**
- Invalidates and releases the rotation timer
- Stops VLC playback
- Removes player delegate
- Closes and releases the window
- All operations are dispatched to the main thread

**Must be called on:** Any thread (automatically dispatches to main queue)

**Example:**
```objc
[controller stop];
```

---

#### dealloc

```objc
- (void)dealloc;
```

Deallocates the controller and ensures cleanup.

**Discussion:** Automatically calls `stop` to ensure resources are released.

---

### Feed Management Methods

#### nextFeed

```objc
- (void)nextFeed;
```

Advances to the next feed in the rotation sequence.

**Discussion:**
- Increments `currentIndex` with wraparound
- Automatically calls `playCurrentFeed` to start playback
- Called automatically by the rotation timer

**Example:**
```objc
// Manually trigger feed rotation
[controller nextFeed];
```

---

#### playCurrentFeed

```objc
- (void)playCurrentFeed;
```

Plays the feed at the current index.

**Discussion:**
- Validates feed index
- Creates and validates NSURL from feed string
- Creates VLCMedia object with RTSP-optimized options:
  - `--network-caching=1000` (1 second buffer)
  - `--rtsp-tcp` (TCP transport)
- Configures audio based on `isMuted` state
- Comprehensive error logging for failures

**Error Handling:**
- Returns early if index is invalid
- Returns early if URL cannot be created
- Returns early if VLCMedia creation fails
- All errors are logged with `[ERROR]` prefix

---

### Audio Control Methods

#### toggleMute

```objc
- (void)toggleMute;
```

Toggles audio mute state and updates the player.

**Discussion:**
- Thread-safe (dispatches to main queue)
- Updates `isMuted` property
- Applies change to VLC player
- Logs state change

**Example:**
```objc
[controller toggleMute];
```

---

### VLCMediaPlayerDelegate Methods

#### mediaPlayerStateChanged:

```objc
- (void)mediaPlayerStateChanged:(NSNotification *)notification;
```

VLCMediaPlayerDelegate callback invoked when player state changes.

**Parameters:**
- `notification`: Notification containing state change information

**Discussion:**
- Logs state changes for debugging
- Logs errors when playback fails
- States: Stopped, Opening, Buffering, Playing, Paused, Error, Ended

---

### Helper Methods

#### stringForPlayerState:

```objc
- (NSString *)stringForPlayerState:(VLCMediaPlayerState)state;
```

Converts VLC player state enum to human-readable string.

**Parameters:**
- `state`: VLCMediaPlayerState enum value

**Returns:** String representation of the state

**Possible Return Values:**
- `"Stopped"` - Player is stopped
- `"Opening"` - Opening stream connection
- `"Buffering"` - Buffering data
- `"Playing"` - Actively playing
- `"Paused"` - Playback paused
- `"Error"` - Playback error occurred
- `"Ended"` - Playback completed
- `"Unknown"` - Unrecognized state

---

## Functions

### loadFeedsFromFile

```objc
NSArray<NSString *> *loadFeedsFromFile(NSString *filePath);
```

Loads RTSP feed URLs from a text configuration file.

**Parameters:**
- `filePath`: Absolute path to the configuration file

**Returns:**
- Array of feed URL strings on success
- `nil` if file cannot be read or doesn't exist

**File Format:**
- One URL per line
- Lines starting with `#` are treated as comments
- Empty lines are ignored
- Leading/trailing whitespace is trimmed

**Example File:**
```
# Camera feeds
rtsp://camera1.local/stream
rtsp://camera2.local/stream

# Backup camera
rtsp://camera3.local/stream
```

**Usage:**
```objc
NSString *path = [@"~/rtsp_feeds.txt" stringByExpandingTildeInPath];
NSArray *feeds = loadFeedsFromFile(path);

if (feeds && feeds.count > 0) {
    // Use feeds
} else {
    // Use default feeds
}
```

---

## Usage Examples

### Basic Usage

```objc
#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Initialize application
        NSApplication *app = [NSApplication sharedApplication];

        // Create controller
        RTSPWallpaperController *controller = [[RTSPWallpaperController alloc] init];

        // Start playback
        [controller start];

        // Run application
        [app run];

        // Cleanup
        [controller stop];
    }
    return 0;
}
```

---

### Custom Feed Configuration

```objc
// Load feeds from file
NSString *feedsPath = [@"~/rtsp_feeds.txt" stringByExpandingTildeInPath];
NSArray *feeds = loadFeedsFromFile(feedsPath);

// Fallback to hardcoded feeds
if (!feeds || feeds.count == 0) {
    feeds = @[
        @"rtsp://192.168.1.100:554/stream1",
        @"rtsp://192.168.1.101:554/stream2"
    ];
}

// Create controller with 2-minute rotation
RTSPWallpaperController *controller =
    [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                   rotationInterval:120.0];

[controller start];
```

---

### Console Input Handling

```objc
// Setup background thread for console input
dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    NSLog(@"[INFO] Press Enter to toggle mute");
    while (1) {
        getchar();  // Block until Enter is pressed
        [controller toggleMute];
    }
});
```

---

### Manual Feed Control

```objc
// Get controller reference
RTSPWallpaperController *controller = /* ... */;

// Manually advance to next feed
[controller nextFeed];

// Check current feed
NSLog(@"Playing feed %lu of %lu: %@",
      controller.currentIndex + 1,
      controller.feeds.count,
      controller.feeds[controller.currentIndex]);

// Toggle audio
[controller toggleMute];
NSLog(@"Audio is %@", controller.isMuted ? @"muted" : @"playing");
```

---

### Error Handling

```objc
// Load feeds with error handling
NSString *path = [@"~/rtsp_feeds.txt" stringByExpandingTildeInPath];
NSArray *feeds = loadFeedsFromFile(path);

if (!feeds) {
    NSLog(@"[WARNING] Could not load feeds from %@", path);
    NSLog(@"[INFO] Using default feeds");
    feeds = nil;  // Controller will use defaults
}

// Validate feed count
if (feeds && feeds.count == 0) {
    NSLog(@"[ERROR] No feeds configured");
    return 1;
}

// Create controller
RTSPWallpaperController *controller =
    [[RTSPWallpaperController alloc] initWithFeeds:feeds
                                   rotationInterval:60.0];

// Monitor logs for playback errors
// Player will log [ERROR] for failed streams
```

---

### Cleanup

```objc
// Proper cleanup on application termination
- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.controller stop];
}

// Or in main:
void signalHandler(int signal) {
    NSLog(@"[INFO] Caught signal %d, exiting", signal);
    [gController stop];
    exit(0);
}

int main(int argc, const char * argv[]) {
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    // ... rest of main
}
```

---

## Logging

All classes log to the system console using `NSLog` with the following format:

- `[INFO]` - Informational messages (startup, state changes, normal operations)
- `[WARNING]` - Non-critical issues (fallback to defaults, missing config)
- `[ERROR]` - Critical errors (playback failures, invalid URLs, missing resources)

**View logs:**
```bash
# Real-time log streaming
log stream --predicate 'process == "RTSP Rotator"' --level debug

# Or use Console.app and filter for "RTSP Rotator"
```

---

## Thread Safety

- **Main Thread Required:** All UI operations (window, player setup)
- **Thread-Safe Methods:** `start()`, `stop()`, `toggleMute()`
- **Automatic Dispatch:** These methods automatically dispatch to main queue
- **Not Thread-Safe:** Direct property access from background threads

**Best Practice:**
```objc
// Safe - automatically dispatches to main queue
[controller start];

// Unsafe - direct property access
controller.isMuted = YES;  // May cause crashes if not on main thread

// Safe alternative
dispatch_async(dispatch_get_main_queue(), ^{
    controller.isMuted = YES;
});

// Or use the provided method
[controller toggleMute];  // Automatically thread-safe
```

---

## Memory Management

The application uses ARC (Automatic Reference Counting):

- **Strong References:** feeds, player, window, rotationTimer
- **Weak References:** None (single controller, no retain cycles)
- **Cleanup:** Timer is invalidated in `stop()` to prevent retain cycle
- **Dealloc:** Automatically calls `stop()` for cleanup

**Memory Considerations:**
- VLC player holds media in memory during playback
- Each stream uses ~200-400MB depending on resolution
- Timer must be invalidated to break retain cycle
- Window must be explicitly closed

---

## Constants

### Default Values

```objc
// Default rotation interval
static const NSTimeInterval kDefaultRotationInterval = 60.0;

// Default feeds (used when no config provided)
static NSArray *kDefaultFeeds = @[
    @"rtsp://feed1.example.com/stream",
    @"rtsp://feed2.example.com/stream"
];

// Window level
kCGDesktopWindowLevel  // Places window at desktop level
```

### VLC Options

```objc
// Network caching (milliseconds)
@"--network-caching=1000"

// Force TCP transport for RTSP
@"--rtsp-tcp"

// Disable audio (conditional)
@"--no-audio"
```

---

## See Also

- [README.md](README.md) - General documentation and usage
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines
- [VLCKit Documentation](https://code.videolan.org/videolan/VLCKit)
