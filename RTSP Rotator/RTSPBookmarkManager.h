//
//  RTSPBookmarkManager.h
//  RTSP Rotator
//
//  Quick access bookmarks for favorite feeds
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Feed bookmark with hotkey
@interface RTSPBookmark : NSObject <NSCoding, NSSecureCoding>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, assign) NSInteger hotkey; // 1-9, 0 for none
@property (nonatomic, strong) NSString *bookmarkID;
@property (nonatomic, assign) NSInteger feedIndex; // Index in feed list, -1 if not found
@end

@class RTSPBookmarkManager;

/// Bookmark manager delegate
@protocol RTSPBookmarkManagerDelegate <NSObject>
@optional
- (void)bookmarkManager:(RTSPBookmarkManager *)manager didActivateBookmark:(RTSPBookmark *)bookmark;
@end

/// Manages feed bookmarks and hotkeys
@interface RTSPBookmarkManager : NSObject

/// Shared instance
+ (instancetype)sharedManager;

/// Delegate for bookmark events
@property (nonatomic, weak) id<RTSPBookmarkManagerDelegate> delegate;

/// All bookmarks (read-only access)
- (NSArray<RTSPBookmark *> *)bookmarks;

/// Enable hotkeys (default: YES)
@property (nonatomic, assign) BOOL hotkeysEnabled;

/// Add bookmark
- (void)addBookmark:(RTSPBookmark *)bookmark;

/// Remove bookmark
- (void)removeBookmark:(RTSPBookmark *)bookmark;

/// Update bookmark
- (void)updateBookmark:(RTSPBookmark *)bookmark;

/// Get bookmark by ID
- (nullable RTSPBookmark *)bookmarkWithID:(NSString *)bookmarkID;

/// Get bookmark by hotkey (1-9)
- (nullable RTSPBookmark *)bookmarkWithHotkey:(NSInteger)hotkey;

/// Get bookmark by feed URL
- (nullable RTSPBookmark *)bookmarkWithFeedURL:(NSURL *)feedURL;

/// Activate bookmark (jump to feed)
- (void)activateBookmark:(RTSPBookmark *)bookmark;

/// Handle hotkey press (1-9)
- (void)handleHotkeyPress:(NSInteger)hotkey;

/// Save bookmarks to disk
- (BOOL)saveBookmarks;

/// Load bookmarks from disk
- (BOOL)loadBookmarks;

@end

NS_ASSUME_NONNULL_END
