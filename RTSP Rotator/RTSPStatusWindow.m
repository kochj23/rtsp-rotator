//
//  RTSPStatusWindow.m
//  RTSP Rotator
//
//  Status window for showing real-time operation logs
//

#import "RTSPStatusWindow.h"

@interface RTSPStatusWindow ()
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;
@end

@implementation RTSPStatusWindow

+ (instancetype)sharedWindow {
    static RTSPStatusWindow *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPStatusWindow alloc] init];
    });
    return shared;
}

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 800, 500);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled |
                                                        NSWindowStyleMaskClosable |
                                                        NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];

    self = [super initWithWindow:window];
    if (self) {
        [self createWindowContents];
    }
    return self;
}

- (void)createWindowContents {
    self.window.title = @"UniFi Protect Status";
    self.window.minSize = NSMakeSize(400, 300);
    [self.window center];

    NSRect frame = self.window.frame;

    // Create scroll view
    self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.hasHorizontalScroller = YES;
    self.scrollView.autohidesScrollers = YES;
    self.scrollView.borderType = NSNoBorder;
    self.scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    // Create text view
    NSRect textFrame = NSMakeRect(0, 0, frame.size.width, frame.size.height);
    self.textView = [[NSTextView alloc] initWithFrame:textFrame];
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.font = [NSFont fontWithName:@"Menlo" size:11];
    self.textView.textColor = [NSColor textColor];
    self.textView.backgroundColor = [NSColor textBackgroundColor];
    self.textView.autoresizingMask = NSViewWidthSizable;

    self.scrollView.documentView = self.textView;
    self.window.contentView = self.scrollView;
}

- (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window makeKeyAndOrderFront:nil];
    });
}

- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window orderOut:nil];
    });
}

- (void)clearLog {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.string = @"";
    });
}

- (void)appendLog:(NSString *)message {
    [self appendLog:message level:@"INFO"];
}

- (void)appendLog:(NSString *)message level:(NSString *)level {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get timestamp
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        
        // Color-code based on level
        NSColor *color = [NSColor textColor];
        if ([level isEqualToString:@"ERROR"]) {
            color = [NSColor redColor];
        } else if ([level isEqualToString:@"WARNING"]) {
            color = [NSColor orangeColor];
        } else if ([level isEqualToString:@"SUCCESS"]) {
            color = [NSColor greenColor];
        }
        
        // Format message
        NSString *logLine = [NSString stringWithFormat:@"[%@] %@: %@\n", timestamp, level, message];
        
        // Create attributed string
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:logLine];
        [attrString addAttribute:NSForegroundColorAttributeName
                           value:color
                           range:NSMakeRange(0, logLine.length)];
        [attrString addAttribute:NSFontAttributeName
                           value:[NSFont fontWithName:@"Menlo" size:11]
                           range:NSMakeRange(0, logLine.length)];
        
        // Append to text view
        [[self.textView textStorage] appendAttributedString:attrString];
        
        // Auto-scroll to bottom
        [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];
    });
}

@end
