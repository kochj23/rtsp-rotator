//
//  RTSPMultiViewGrid.m
//  RTSP Rotator
//

#import "RTSPMultiViewGrid.h"

@implementation RTSPCameraCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor blackColor] CGColor];

        // Setup player layer
        _playerLayer = [AVPlayerLayer layer];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:_playerLayer];

        // Status indicator (top-left corner)
        _statusIndicator = [[NSView alloc] initWithFrame:NSMakeRect(8, frameRect.size.height - 20, 12, 12)];
        _statusIndicator.wantsLayer = YES;
        _statusIndicator.layer.cornerRadius = 6;
        _statusIndicator.layer.backgroundColor = [[NSColor grayColor] CGColor];
        [self addSubview:_statusIndicator];

        // Label (bottom-left)
        _labelField = [[NSTextField alloc] initWithFrame:NSMakeRect(8, 8, frameRect.size.width - 16, 20)];
        _labelField.bezeled = NO;
        _labelField.drawsBackground = YES;
        _labelField.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.7] colorWithAlphaComponent:0.7];
        _labelField.textColor = [NSColor whiteColor];
        _labelField.font = [NSFont systemFontOfSize:12];
        _labelField.editable = NO;
        _labelField.selectable = NO;
        [self addSubview:_labelField];

        // Timestamp (bottom-right)
        _timestampField = [[NSTextField alloc] initWithFrame:NSMakeRect(frameRect.size.width - 150, 8, 142, 20)];
        _timestampField.bezeled = NO;
        _timestampField.drawsBackground = YES;
        _timestampField.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.7] colorWithAlphaComponent:0.7];
        _timestampField.textColor = [NSColor whiteColor];
        _timestampField.font = [NSFont systemFontOfSize:11];
        _timestampField.alignment = NSTextAlignmentRight;
        _timestampField.editable = NO;
        _timestampField.selectable = NO;
        [self addSubview:_timestampField];

        // Diagnostics label (top-right)
        _diagnosticsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(frameRect.size.width - 100, frameRect.size.height - 20, 92, 16)];
        _diagnosticsLabel.bezeled = NO;
        _diagnosticsLabel.drawsBackground = YES;
        _diagnosticsLabel.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.7] colorWithAlphaComponent:0.7];
        _diagnosticsLabel.textColor = [NSColor whiteColor];
        _diagnosticsLabel.font = [NSFont systemFontOfSize:9];
        _diagnosticsLabel.alignment = NSTextAlignmentRight;
        _diagnosticsLabel.editable = NO;
        _diagnosticsLabel.selectable = NO;
        _diagnosticsLabel.hidden = YES;
        [self addSubview:_diagnosticsLabel];

        // Start timestamp updates
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimestamp) userInfo:nil repeats:YES];

        _showLabel = YES;
        _showTimestamp = YES;
        _showDiagnostics = NO;
        _isPlaying = NO;
    }
    return self;
}

- (void)layout {
    [super layout];

    // Update layer frames
    self.playerLayer.frame = self.bounds;
    self.statusIndicator.frame = NSMakeRect(8, self.bounds.size.height - 20, 12, 12);
    self.labelField.frame = NSMakeRect(8, 8, self.bounds.size.width - 16, 20);
    self.timestampField.frame = NSMakeRect(self.bounds.size.width - 150, 8, 142, 20);
    self.diagnosticsLabel.frame = NSMakeRect(self.bounds.size.width - 100, self.bounds.size.height - 20, 92, 16);
}

- (void)loadFeed {
    if (!self.cameraConfig || !self.cameraConfig.feedURL) {
        NSLog(@"[CameraCell] Cannot load feed: no configuration");
        [self updateStatusWithState:@"error"];
        return;
    }

    [self updateStatusWithState:@"loading"];

    // Create player
    self.player = [[AVPlayer alloc] init];
    self.player.muted = self.cameraConfig.isMuted;
    self.playerLayer.player = self.player;

    // Create player item
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.cameraConfig.feedURL];

    // Observe player item status
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self.player play];

    self.isPlaying = YES;
    self.labelField.stringValue = self.cameraConfig.name ?: @"Camera";
    self.labelField.hidden = !self.showLabel;
    self.timestampField.hidden = !self.showTimestamp;

    NSLog(@"[CameraCell] Loading feed: %@", self.cameraConfig.name);
}

- (void)stopPlayback {
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.isPlaying = NO;
    [self updateStatusWithState:@"stopped"];

    NSLog(@"[CameraCell] Stopped playback: %@", self.cameraConfig.name);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (item.status == AVPlayerItemStatusReadyToPlay) {
                [self updateStatusWithState:@"playing"];
                NSLog(@"[CameraCell] Feed ready: %@", self.cameraConfig.name);
            } else if (item.status == AVPlayerItemStatusFailed) {
                [self updateStatusWithState:@"error"];
                NSLog(@"[CameraCell] Feed failed: %@ - %@", self.cameraConfig.name, item.error);
            }
        });
    }
}

- (void)updateStatusWithHealthStatus:(RTSPCameraHealthStatus)status {
    RTSPCameraDiagnostics *diagnostics = [RTSPCameraDiagnostics sharedDiagnostics];
    RTSPCameraDiagnosticReport *report = [diagnostics reportForCamera:self.cameraConfig];

    NSColor *color = report ? [report statusColor] : [NSColor grayColor];
    self.statusIndicator.layer.backgroundColor = [color CGColor];

    [self updateDiagnosticsDisplay];
}

- (void)updateStatusWithState:(NSString *)state {
    NSColor *color = [NSColor grayColor];

    if ([state isEqualToString:@"playing"]) {
        color = [NSColor greenColor];
    } else if ([state isEqualToString:@"loading"]) {
        color = [NSColor yellowColor];
    } else if ([state isEqualToString:@"error"]) {
        color = [NSColor redColor];
    } else if ([state isEqualToString:@"stopped"]) {
        color = [NSColor grayColor];
    }

    self.statusIndicator.layer.backgroundColor = [color CGColor];
}

- (void)updateDiagnosticsDisplay {
    if (!self.showDiagnostics) {
        self.diagnosticsLabel.hidden = YES;
        return;
    }

    RTSPCameraDiagnostics *diagnostics = [RTSPCameraDiagnostics sharedDiagnostics];
    RTSPCameraDiagnosticReport *report = [diagnostics reportForCamera:self.cameraConfig];

    if (report) {
        NSString *diagText = @"";

        if (report.hasVideo) {
            diagText = [NSString stringWithFormat:@"%@ %ldfps", report.resolution ?: @"", (long)report.framerate];
        }

        if (report.latency > 0) {
            diagText = [diagText stringByAppendingFormat:@" %.0fms", report.latency];
        }

        self.diagnosticsLabel.stringValue = diagText;
        self.diagnosticsLabel.hidden = NO;
    } else {
        self.diagnosticsLabel.hidden = YES;
    }
}

- (void)updateTimestamp {
    if (!self.showTimestamp) {
        self.timestampField.hidden = YES;
        return;
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss";
    self.timestampField.stringValue = [formatter stringFromDate:[NSDate date]];
    self.timestampField.hidden = NO;
}

- (void)dealloc {
    [self stopPlayback];
}

@end

@interface RTSPMultiViewGrid ()
@property (nonatomic, strong) NSMutableArray<RTSPCameraCell *> *allCameraCells;
@end

@implementation RTSPMultiViewGrid

- (instancetype)initWithDashboard:(RTSPDashboard *)dashboard {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _dashboard = dashboard;
        _allCameraCells = [NSMutableArray array];
        _gridSpacing = 2.0;
        _showDiagnostics = NO;
        _autoHealthMonitoring = NO;

        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor blackColor] CGColor];

        [self loadDashboard:dashboard];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    return [self initWithDashboard:nil];
}

- (NSArray<RTSPCameraCell *> *)cameraCells {
    return [self.allCameraCells copy];
}

- (void)loadDashboard:(RTSPDashboard *)dashboard {
    // Stop and remove existing cells
    [self stopAllFeeds];
    for (RTSPCameraCell *cell in self.allCameraCells) {
        [cell removeFromSuperview];
    }
    [self.allCameraCells removeAllObjects];

    self.dashboard = dashboard;

    if (!dashboard) {
        NSLog(@"[MultiViewGrid] No dashboard provided");
        return;
    }

    // Create cells for each camera
    for (RTSPCameraConfig *cameraConfig in dashboard.cameras) {
        RTSPCameraCell *cell = [[RTSPCameraCell alloc] initWithFrame:NSZeroRect];
        cell.cameraConfig = cameraConfig;
        cell.showLabel = dashboard.showLabels;
        cell.showTimestamp = dashboard.showTimestamp;
        cell.showDiagnostics = self.showDiagnostics;
        [self.allCameraCells addObject:cell];
        [self addSubview:cell];
    }

    [self layoutCameraGrid];

    NSLog(@"[MultiViewGrid] Loaded dashboard '%@' with %lu cameras", dashboard.name, (unsigned long)dashboard.cameras.count);
}

- (void)layoutCameraGrid {
    if (!self.dashboard || self.allCameraCells.count == 0) {
        return;
    }

    // Calculate grid dimensions based on layout
    NSInteger rows, columns;

    switch (self.dashboard.layout) {
        case RTSPDashboardLayout1x1:
            rows = 1; columns = 1;
            break;
        case RTSPDashboardLayout2x2:
            rows = 2; columns = 2;
            break;
        case RTSPDashboardLayout3x2:
            rows = 2; columns = 3;
            break;
        case RTSPDashboardLayout3x3:
            rows = 3; columns = 3;
            break;
        case RTSPDashboardLayout4x3:
            rows = 3; columns = 4;
            break;
        default:
            rows = 3; columns = 3;
            break;
    }

    CGFloat totalWidth = self.bounds.size.width;
    CGFloat totalHeight = self.bounds.size.height;

    CGFloat cellWidth = (totalWidth - (self.gridSpacing * (columns + 1))) / columns;
    CGFloat cellHeight = (totalHeight - (self.gridSpacing * (rows + 1))) / rows;

    // Layout cells in grid
    for (NSInteger i = 0; i < self.allCameraCells.count; i++) {
        RTSPCameraCell *cell = self.allCameraCells[i];

        NSInteger row = i / columns;
        NSInteger col = i % columns;

        CGFloat x = self.gridSpacing + col * (cellWidth + self.gridSpacing);
        CGFloat y = totalHeight - (self.gridSpacing + (row + 1) * (cellHeight + self.gridSpacing));

        cell.frame = NSMakeRect(x, y, cellWidth, cellHeight);
    }

    NSLog(@"[MultiViewGrid] Laid out %ldx%ld grid", (long)rows, (long)columns);
}

- (void)layout {
    [super layout];
    [self layoutCameraGrid];
}

- (void)startAllFeeds {
    if (self.dashboard.syncPlayback) {
        // Start all feeds simultaneously
        for (RTSPCameraCell *cell in self.allCameraCells) {
            if (cell.cameraConfig.enabled) {
                [cell loadFeed];
            }
        }
    } else {
        // Start feeds sequentially with slight delay
        for (NSInteger i = 0; i < self.allCameraCells.count; i++) {
            RTSPCameraCell *cell = self.allCameraCells[i];
            if (cell.cameraConfig.enabled) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [cell loadFeed];
                });
            }
        }
    }

    NSLog(@"[MultiViewGrid] Started %lu camera feeds", (unsigned long)self.allCameraCells.count);
}

- (void)stopAllFeeds {
    for (RTSPCameraCell *cell in self.allCameraCells) {
        [cell stopPlayback];
    }

    NSLog(@"[MultiViewGrid] Stopped all camera feeds");
}

- (void)refreshCameraAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.allCameraCells.count) {
        return;
    }

    RTSPCameraCell *cell = self.allCameraCells[index];
    [cell stopPlayback];
    [cell loadFeed];

    NSLog(@"[MultiViewGrid] Refreshed camera at index %ld", (long)index);
}

- (void)refreshAllCameras {
    [self stopAllFeeds];
    [self startAllFeeds];

    NSLog(@"[MultiViewGrid] Refreshed all cameras");
}

- (RTSPCameraCell *)cellAtRow:(NSInteger)row column:(NSInteger)column {
    NSInteger columns;

    switch (self.dashboard.layout) {
        case RTSPDashboardLayout1x1: columns = 1; break;
        case RTSPDashboardLayout2x2: columns = 2; break;
        case RTSPDashboardLayout3x2: columns = 3; break;
        case RTSPDashboardLayout3x3: columns = 3; break;
        case RTSPDashboardLayout4x3: columns = 4; break;
        default: columns = 3; break;
    }

    NSInteger index = row * columns + column;

    if (index >= 0 && index < self.allCameraCells.count) {
        return self.allCameraCells[index];
    }

    return nil;
}

- (void)runDiagnostics {
    RTSPCameraDiagnostics *diagnostics = [RTSPCameraDiagnostics sharedDiagnostics];

    NSLog(@"[MultiViewGrid] Running diagnostics on %lu cameras...", (unsigned long)self.allCameraCells.count);

    for (RTSPCameraCell *cell in self.allCameraCells) {
        if (cell.cameraConfig) {
            [diagnostics testCamera:cell.cameraConfig completion:^(RTSPCameraDiagnosticReport *report) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell updateStatusWithHealthStatus:report.healthStatus];
                });
            }];
        }
    }
}

- (void)updateAllStatusIndicators {
    RTSPCameraDiagnostics *diagnostics = [RTSPCameraDiagnostics sharedDiagnostics];

    for (RTSPCameraCell *cell in self.allCameraCells) {
        if (cell.cameraConfig) {
            RTSPCameraHealthStatus status = [diagnostics healthStatusForCamera:cell.cameraConfig];
            [cell updateStatusWithHealthStatus:status];
        }
    }
}

- (void)setShowDiagnostics:(BOOL)showDiagnostics {
    _showDiagnostics = showDiagnostics;

    // Update all cells
    for (RTSPCameraCell *cell in self.allCameraCells) {
        cell.showDiagnostics = showDiagnostics;
        [cell updateDiagnosticsDisplay];
    }
}

- (void)setAutoHealthMonitoring:(BOOL)autoHealthMonitoring {
    _autoHealthMonitoring = autoHealthMonitoring;

    RTSPCameraDiagnostics *diagnostics = [RTSPCameraDiagnostics sharedDiagnostics];

    if (autoHealthMonitoring) {
        [diagnostics startHealthMonitoring];
        NSLog(@"[MultiViewGrid] Enabled automatic health monitoring");
    } else {
        [diagnostics stopHealthMonitoring];
        NSLog(@"[MultiViewGrid] Disabled automatic health monitoring");
    }
}

- (void)dealloc {
    [self stopAllFeeds];
}

@end
