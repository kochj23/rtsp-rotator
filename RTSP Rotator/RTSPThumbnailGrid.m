//
//  RTSPThumbnailGrid.m
//  RTSP Rotator
//

#import "RTSPThumbnailGrid.h"
#import <AVFoundation/AVFoundation.h>

@implementation RTSPThumbnailCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor darkGrayColor] CGColor];
        self.layer.cornerRadius = 4.0;
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = [[NSColor clearColor] CGColor];

        // Image view
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 20, frameRect.size.width, frameRect.size.height - 20)];
        _imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        [self addSubview:_imageView];

        // Label
        _labelField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, 20)];
        _labelField.stringValue = @"Feed";
        _labelField.alignment = NSTextAlignmentCenter;
        _labelField.textColor = [NSColor whiteColor];
        _labelField.backgroundColor = [NSColor clearColor];
        _labelField.bordered = NO;
        _labelField.editable = NO;
        _labelField.font = [NSFont systemFontOfSize:10];
        [self addSubview:_labelField];

        // Status indicator
        _statusIndicator = [[NSView alloc] initWithFrame:NSMakeRect(frameRect.size.width - 15, frameRect.size.height - 15, 10, 10)];
        _statusIndicator.wantsLayer = YES;
        _statusIndicator.layer.cornerRadius = 5.0;
        _statusIndicator.layer.backgroundColor = [[NSColor grayColor] CGColor];
        [self addSubview:_statusIndicator];

        _isHealthy = YES;
        _isSelected = NO;
    }
    return self;
}

- (void)setIsHealthy:(BOOL)isHealthy {
    _isHealthy = isHealthy;
    self.statusIndicator.layer.backgroundColor = isHealthy ? [[NSColor greenColor] CGColor] : [[NSColor redColor] CGColor];
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    self.layer.borderColor = isSelected ? [[NSColor systemBlueColor] CGColor] : [[NSColor clearColor] CGColor];
}

@end

@interface RTSPThumbnailGrid ()
@property (nonatomic, strong) NSMutableArray<RTSPThumbnailCell *> *cells;
@property (nonatomic, strong) NSTimer *refreshTimer;
@end

@implementation RTSPThumbnailGrid

- (instancetype)initWithFeedURLs:(NSArray<NSURL *> *)feedURLs {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _feedURLs = feedURLs;
        _cells = [NSMutableArray array];
        _refreshInterval = 5.0;
        _thumbnailSize = CGSizeMake(160, 120);
        _columns = 4;
        _allowsReordering = YES;
        _selectedIndex = -1;

        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor blackColor] CGColor];

        [self setupCells];
    }
    return self;
}

- (void)setupCells {
    // Remove old cells
    for (RTSPThumbnailCell *cell in self.cells) {
        [cell removeFromSuperview];
    }
    [self.cells removeAllObjects];

    // Create cells
    for (NSUInteger i = 0; i < self.feedURLs.count; i++) {
        NSURL *feedURL = self.feedURLs[i];

        RTSPThumbnailCell *cell = [[RTSPThumbnailCell alloc] initWithFrame:NSMakeRect(0, 0, self.thumbnailSize.width, self.thumbnailSize.height)];
        cell.feedURL = feedURL;
        cell.labelField.stringValue = [NSString stringWithFormat:@"Feed %lu", (unsigned long)(i + 1)];

        // Add click gesture
        NSClickGestureRecognizer *clickGesture = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(cellClicked:)];
        [cell addGestureRecognizer:clickGesture];

        [self addSubview:cell];
        [self.cells addObject:cell];
    }

    [self layoutCells];
    [self reloadThumbnails];
}

- (void)layoutCells {
    CGFloat margin = 10;
    CGFloat cellWidth = self.thumbnailSize.width;
    CGFloat cellHeight = self.thumbnailSize.height;

    NSInteger cols = self.columns;
    NSInteger rows = (NSInteger)ceil((CGFloat)self.cells.count / cols);

    for (NSUInteger i = 0; i < self.cells.count; i++) {
        NSInteger row = i / cols;
        NSInteger col = i % cols;

        CGFloat x = margin + col * (cellWidth + margin);
        CGFloat y = margin + row * (cellHeight + margin);

        RTSPThumbnailCell *cell = self.cells[i];
        cell.frame = NSMakeRect(x, y, cellWidth, cellHeight);
    }

    // Update view size
    CGFloat totalWidth = margin + cols * (cellWidth + margin);
    CGFloat totalHeight = margin + rows * (cellHeight + margin);
    self.frame = NSMakeRect(self.frame.origin.x, self.frame.origin.y, totalWidth, totalHeight);
}

- (void)reloadThumbnails {
    for (NSUInteger i = 0; i < self.cells.count; i++) {
        [self updateThumbnailAtIndex:i];
    }
}

- (void)updateThumbnailAtIndex:(NSUInteger)index {
    if (index >= self.cells.count) {
        return;
    }

    RTSPThumbnailCell *cell = self.cells[index];
    NSURL *feedURL = cell.feedURL;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSImage *thumbnail = [self captureThumbnailForURL:feedURL];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (thumbnail) {
                cell.imageView.image = thumbnail;
                cell.isHealthy = YES;
            } else {
                cell.imageView.image = nil;
                cell.isHealthy = NO;
            }
        });
    });
}

- (NSImage *)captureThumbnailForURL:(NSURL *)feedURL {
    // Create temporary player to capture frame
    AVPlayer *player = [[AVPlayer alloc] init];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:feedURL];
    [player replaceCurrentItemWithPlayerItem:playerItem];

    // Wait for player to be ready
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while ([[NSDate date] compare:timeoutDate] == NSOrderedAscending) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            break;
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            return nil;
        }

        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    if (playerItem.status != AVPlayerItemStatusReadyToPlay) {
        return nil;
    }

    // Generate thumbnail
    AVAsset *asset = playerItem.asset;
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(self.thumbnailSize.width * 2, self.thumbnailSize.height * 2);

    __block NSImage *thumbnail = nil;
    __block BOOL completed = NO;

    if (@available(macOS 13.0, *)) {
        [generator generateCGImageAsynchronouslyForTime:kCMTimeZero completionHandler:^(CGImageRef imageRef, CMTime actualTime, NSError *error) {
            if (imageRef) {
                thumbnail = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
            }
            completed = YES;
        }];

        // Wait for completion
        while (!completed && [[NSDate date] compare:timeoutDate] == NSOrderedAscending) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    } else {
        // Fallback for macOS 11.0-12.x: use synchronous API
        NSError *error = nil;
        CGImageRef imageRef = [generator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:&error];
        if (imageRef) {
            thumbnail = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
            CGImageRelease(imageRef);
        }
    }

    return thumbnail;
}

- (void)updateHealthStatus:(BOOL)healthy atIndex:(NSUInteger)index {
    if (index >= self.cells.count) {
        return;
    }

    RTSPThumbnailCell *cell = self.cells[index];
    cell.isHealthy = healthy;
}

- (void)cellClicked:(NSClickGestureRecognizer *)gesture {
    if (gesture.state != NSGestureRecognizerStateEnded) {
        return;
    }

    RTSPThumbnailCell *clickedCell = (RTSPThumbnailCell *)gesture.view;
    NSUInteger index = [self.cells indexOfObject:clickedCell];

    if (index != NSNotFound) {
        self.selectedIndex = index;

        // Update selection state
        for (NSUInteger i = 0; i < self.cells.count; i++) {
            self.cells[i].isSelected = (i == index);
        }

        if ([self.delegate respondsToSelector:@selector(thumbnailGrid:didSelectFeedAtIndex:)]) {
            [self.delegate thumbnailGrid:self didSelectFeedAtIndex:index];
        }
    }
}

- (void)startAutoRefresh {
    if (self.refreshTimer) {
        return;
    }

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                         target:self
                                                       selector:@selector(reloadThumbnails)
                                                       userInfo:nil
                                                        repeats:YES];

    NSLog(@"[Thumbnails] Started auto-refresh (interval: %.1fs)", self.refreshInterval);
}

- (void)stopAutoRefresh {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;

    NSLog(@"[Thumbnails] Stopped auto-refresh");
}

- (void)setFeedURLs:(NSArray<NSURL *> *)feedURLs {
    _feedURLs = feedURLs;
    [self setupCells];
}

- (void)dealloc {
    [self stopAutoRefresh];
}

@end
