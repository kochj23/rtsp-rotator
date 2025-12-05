//
//  RTSPBookmarkManager.m
//  RTSP Rotator
//

#import "RTSPBookmarkManager.h"

@implementation RTSPBookmark

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _bookmarkID = [[NSUUID UUID] UUIDString];
        _hotkey = 0;
        _feedIndex = -1;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.feedURL forKey:@"feedURL"];
    [coder encodeInteger:self.hotkey forKey:@"hotkey"];
    [coder encodeObject:self.bookmarkID forKey:@"bookmarkID"];
    [coder encodeInteger:self.feedIndex forKey:@"feedIndex"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _feedURL = [coder decodeObjectOfClass:[NSURL class] forKey:@"feedURL"];
        _hotkey = [coder decodeIntegerForKey:@"hotkey"];
        _bookmarkID = [coder decodeObjectOfClass:[NSString class] forKey:@"bookmarkID"];
        _feedIndex = [coder decodeIntegerForKey:@"feedIndex"];
    }
    return self;
}

@end

@interface RTSPBookmarkManager ()
@property (nonatomic, strong) NSMutableArray<RTSPBookmark *> *allBookmarks;
@end

@implementation RTSPBookmarkManager

+ (instancetype)sharedManager {
    static RTSPBookmarkManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPBookmarkManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allBookmarks = [NSMutableArray array];
        _hotkeysEnabled = YES;

        [self loadBookmarks];
    }
    return self;
}

- (NSArray<RTSPBookmark *> *)bookmarks {
    return [self.allBookmarks copy];
}

- (void)addBookmark:(RTSPBookmark *)bookmark {
    // Check if hotkey is already used
    if (bookmark.hotkey > 0) {
        RTSPBookmark *existing = [self bookmarkWithHotkey:bookmark.hotkey];
        if (existing) {
            // Clear existing hotkey
            existing.hotkey = 0;
            NSLog(@"[Bookmarks] Cleared hotkey %ld from '%@'", (long)bookmark.hotkey, existing.name);
        }
    }

    [self.allBookmarks addObject:bookmark];
    [self saveBookmarks];

    NSLog(@"[Bookmarks] Added bookmark: %@ (hotkey: %ld)", bookmark.name, (long)bookmark.hotkey);
}

- (void)removeBookmark:(RTSPBookmark *)bookmark {
    [self.allBookmarks removeObject:bookmark];
    [self saveBookmarks];

    NSLog(@"[Bookmarks] Removed bookmark: %@", bookmark.name);
}

- (void)updateBookmark:(RTSPBookmark *)bookmark {
    // Check if hotkey changed and conflicts
    if (bookmark.hotkey > 0) {
        RTSPBookmark *existing = [self bookmarkWithHotkey:bookmark.hotkey];
        if (existing && ![existing.bookmarkID isEqualToString:bookmark.bookmarkID]) {
            existing.hotkey = 0;
            NSLog(@"[Bookmarks] Cleared conflicting hotkey %ld from '%@'", (long)bookmark.hotkey, existing.name);
        }
    }

    [self saveBookmarks];
    NSLog(@"[Bookmarks] Updated bookmark: %@", bookmark.name);
}

- (RTSPBookmark *)bookmarkWithID:(NSString *)bookmarkID {
    for (RTSPBookmark *bookmark in self.allBookmarks) {
        if ([bookmark.bookmarkID isEqualToString:bookmarkID]) {
            return bookmark;
        }
    }
    return nil;
}

- (RTSPBookmark *)bookmarkWithHotkey:(NSInteger)hotkey {
    for (RTSPBookmark *bookmark in self.allBookmarks) {
        if (bookmark.hotkey == hotkey) {
            return bookmark;
        }
    }
    return nil;
}

- (RTSPBookmark *)bookmarkWithFeedURL:(NSURL *)feedURL {
    for (RTSPBookmark *bookmark in self.allBookmarks) {
        if ([bookmark.feedURL.absoluteString isEqualToString:feedURL.absoluteString]) {
            return bookmark;
        }
    }
    return nil;
}

- (void)activateBookmark:(RTSPBookmark *)bookmark {
    if ([self.delegate respondsToSelector:@selector(bookmarkManager:didActivateBookmark:)]) {
        [self.delegate bookmarkManager:self didActivateBookmark:bookmark];
    }

    NSLog(@"[Bookmarks] Activated bookmark: %@", bookmark.name);
}

- (void)handleHotkeyPress:(NSInteger)hotkey {
    if (!self.hotkeysEnabled) {
        return;
    }

    if (hotkey < 1 || hotkey > 9) {
        return;
    }

    RTSPBookmark *bookmark = [self bookmarkWithHotkey:hotkey];
    if (bookmark) {
        [self activateBookmark:bookmark];
    } else {
        NSLog(@"[Bookmarks] No bookmark assigned to hotkey %ld", (long)hotkey);
    }
}

- (BOOL)saveBookmarks {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *appFolder = [appSupport stringByAppendingPathComponent:@"RTSP Rotator"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appFolder]) {
        [fm createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *bookmarksPath = [appFolder stringByAppendingPathComponent:@"bookmarks.dat"];

    NSError *error = nil;
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:self.allBookmarks requiringSecureCoding:YES error:&error];

    if (error) {
        NSLog(@"[Bookmarks] Failed to archive bookmarks: %@", error);
        return NO;
    }

    BOOL success = [archiveData writeToFile:bookmarksPath atomically:YES];

    if (success) {
        NSLog(@"[Bookmarks] Saved bookmarks to disk");
    } else {
        NSLog(@"[Bookmarks] Failed to save bookmarks to disk");
    }

    return success;
}

- (BOOL)loadBookmarks {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *bookmarksPath = [[appSupport stringByAppendingPathComponent:@"RTSP Rotator"] stringByAppendingPathComponent:@"bookmarks.dat"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:bookmarksPath]) {
        NSLog(@"[Bookmarks] No saved bookmarks found");
        return NO;
    }

    NSError *error = nil;
    NSData *archiveData = [NSData dataWithContentsOfFile:bookmarksPath];

    NSSet *classes = [NSSet setWithArray:@[[NSArray class], [RTSPBookmark class], [NSString class], [NSURL class]]];
    NSArray *loadedBookmarks = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:archiveData error:&error];

    if (error) {
        NSLog(@"[Bookmarks] Failed to unarchive bookmarks: %@", error);
        return NO;
    }

    self.allBookmarks = [NSMutableArray arrayWithArray:loadedBookmarks];

    NSLog(@"[Bookmarks] Loaded %lu bookmarks from disk", (unsigned long)self.allBookmarks.count);
    return YES;
}

@end
