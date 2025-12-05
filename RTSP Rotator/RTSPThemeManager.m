//
//  RTSPThemeManager.m
//  RTSP Rotator
//

#import "RTSPThemeManager.h"

@implementation RTSPThemeManager

+ (instancetype)sharedManager {
    static RTSPThemeManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPThemeManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _themeMode = RTSPThemeModeSystem;
    }
    return self;
}

- (BOOL)isDarkMode {
    if (self.themeMode == RTSPThemeModeDark) return YES;
    if (self.themeMode == RTSPThemeModeLight) return NO;

    NSString *mode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    return [mode isEqualToString:@"Dark"];
}

- (void)applyTheme {
    if (self.themeMode == RTSPThemeModeSystem) {
        [NSApp setAppearance:nil];
    } else if (self.themeMode == RTSPThemeModeDark) {
        [NSApp setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
    } else {
        [NSApp setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
    }

    NSLog(@"[Theme] Applied theme mode: %ld", (long)self.themeMode);
}

- (NSColor *)backgroundColor {
    return self.isDarkMode ? [NSColor blackColor] : [NSColor whiteColor];
}

- (NSColor *)textColor {
    return self.isDarkMode ? [NSColor whiteColor] : [NSColor blackColor];
}

- (NSColor *)accentColor {
    return [NSColor systemBlueColor];
}

@end
