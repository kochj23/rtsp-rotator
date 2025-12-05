//
//  RTSPThemeManager.h
//  RTSP Rotator
//
//  Dark mode and theme management
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPThemeMode) {
    RTSPThemeModeSystem,
    RTSPThemeModeLight,
    RTSPThemeModeDark
};

@interface RTSPThemeManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) RTSPThemeMode themeMode;
@property (nonatomic, assign, readonly) BOOL isDarkMode;

- (void)applyTheme;
- (NSColor *)backgroundColor;
- (NSColor *)textColor;
- (NSColor *)accentColor;

@end

NS_ASSUME_NONNULL_END
