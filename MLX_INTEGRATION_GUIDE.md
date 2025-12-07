# MLX Integration Guide - RTSP Rotator

## Quick Start Integration

This guide shows how to integrate MLX object detection into your existing RTSP camera views.

## Step 1: Import Headers

Add to your view controller or manager:

```objc
#import "RTSPMLXProcessor.h"
#import "RTSPObjectDetector.h"
#import "RTSPSmartAlerts.h"
#import "RTSPDetectionOverlayView.h"
```

## Step 2: Initialize on App Launch

In your `AppDelegate` or main controller:

```objc
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Initialize MLX processor
    RTSPMLXProcessor *processor = [RTSPMLXProcessor sharedProcessor];

    // Load model (if available)
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"yolov8n"
                                                          ofType:@"mlpackage"];
    if (modelPath) {
        NSError *error = nil;
        BOOL success = [processor loadModel:modelPath error:&error];

        if (success) {
            NSLog(@"✓ MLX Model loaded successfully");
        } else {
            NSLog(@"✗ Failed to load model: %@", error);
        }
    } else {
        NSLog(@"ℹ️  No ML model found - detection features disabled");
        NSLog(@"   Run ./download_models.sh to download models");
    }
}
```

## Step 3: Add Detection to Camera View

### For Video Player Views

```objc
@interface RTSPCameraViewController : NSViewController

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) RTSPDetectionOverlayView *detectionOverlay;
@property (nonatomic, strong) RTSPSmartAlerts *smartAlerts;
@property (nonatomic, strong) NSString *cameraID;
@property (nonatomic, strong) NSString *cameraName;

@end

@implementation RTSPCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setup video player
    self.player = [AVPlayer playerWithURL:rtspURL];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.view.layer addSublayer:self.playerLayer];

    // Add detection overlay
    self.detectionOverlay = [[RTSPDetectionOverlayView alloc] initWithFrame:self.view.bounds];
    self.detectionOverlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.detectionOverlay.showLabels = YES;
    self.detectionOverlay.showConfidence = YES;
    [self.view addSubview:self.detectionOverlay];

    // Setup smart alerts
    self.smartAlerts = [[RTSPSmartAlerts alloc] initWithCameraID:self.cameraID
                                                      cameraName:self.cameraName];
    self.smartAlerts.delegate = self;
    self.smartAlerts.enabled = YES;
    self.smartAlerts.useMLX = YES;
    self.smartAlerts.alertClasses = @[@"person", @"car", @"package"];
    self.smartAlerts.cooldownPeriod = 30.0;

    // Start monitoring
    [self.smartAlerts startMonitoring];

    // Enable detection for this camera
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];
    detector.delegate = self;
    [detector enableDetectionForCamera:self.cameraID zones:nil];

    // Start extracting and processing frames
    [self startFrameExtraction];
}

- (void)startFrameExtraction {
    // Extract frames from video player at intervals
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (self.player) {
            // Get current frame
            CMTime currentTime = self.player.currentTime;
            AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.player.currentItem.asset];

            NSError *error = nil;
            CGImageRef image = [generator copyCGImageAtTime:currentTime actualTime:NULL error:&error];

            if (image) {
                // Process with MLX
                [[RTSPObjectDetector sharedDetector].mlxProcessor processImage:image
                    completion:^(NSArray<RTSPDetection *> *detections, NSError *error) {
                        if (detections && detections.count > 0) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.detectionOverlay updateDetections:detections];
                            });
                        }
                }];

                CGImageRelease(image);
            }

            // Wait before next frame
            [NSThread sleepForTimeInterval:0.1]; // 10 FPS extraction
        }
    });
}

#pragma mark - RTSPObjectDetectorDelegate

- (void)objectDetector:(RTSPObjectDetector *)detector
        didDetectEvent:(RTSPDetectionEvent *)event {
    NSLog(@"Detection: %@ (%.0f%%) on %@",
          event.detection.label,
          event.detection.confidence * 100,
          event.cameraName);
}

#pragma mark - RTSPSmartAlertsDelegate

- (void)smartAlerts:(RTSPSmartAlerts *)alerts
  didTriggerAlert:(NSString *)message
          forEvent:(RTSPDetectionEvent *)event {
    // Show alert to user
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Object Detected";
    alert.informativeText = message;
    [alert runModal];
}

@end
```

## Step 4: Configure Detection Zones (Optional)

```objc
// Create zones for specific areas
- (void)setupDetectionZones {
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

    // Front porch zone
    RTSPDetectionZone *porch = [[RTSPDetectionZone alloc] initWithName:@"Front Porch"
                                                                   rect:CGRectMake(0.2, 0.6, 0.6, 0.3)];
    porch.enabledClasses = @[@"person", @"package"];

    // Driveway zone
    RTSPDetectionZone *driveway = [[RTSPDetectionZone alloc] initWithName:@"Driveway"
                                                                      rect:CGRectMake(0.0, 0.4, 0.4, 0.6)];
    driveway.enabledClasses = @[@"car", @"truck", @"motorcycle"];

    // Apply zones to camera
    [detector setZones:@[porch, driveway] forCamera:self.cameraID];

    // Show zones on overlay
    self.detectionOverlay.zones = @[porch, driveway];
    self.detectionOverlay.showZones = YES;
}
```

## Step 5: Export Detection Data

```objc
- (void)exportDetectionHistory {
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

    NSString *desktop = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,
                                                            NSUserDomainMask,
                                                            YES).firstObject;
    NSString *csvPath = [desktop stringByAppendingPathComponent:@"detections.csv"];

    NSError *error = nil;
    BOOL success = [detector exportEventsToCSV:csvPath error:&error];

    if (success) {
        NSLog(@"✓ Exported detections to: %@", csvPath);
    } else {
        NSLog(@"✗ Export failed: %@", error);
    }
}
```

## Integration with Existing Features

### 1. Dashboard Manager Integration

```objc
// In RTSPDashboardManager.m

- (void)setupDetectionForAllCameras {
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

    for (RTSPCameraConfig *camera in self.cameras) {
        // Enable detection
        [detector enableDetectionForCamera:camera.cameraID zones:nil];

        // Setup alerts
        RTSPSmartAlerts *alerts = [[RTSPSmartAlerts alloc] initWithCameraID:camera.cameraID
                                                                  cameraName:camera.name];
        alerts.enabled = YES;
        alerts.alertClasses = @[@"person"]; // Alert only on people
        alerts.delegate = self;
        [alerts startMonitoring];

        // Store alerts instance
        self.alertsMap[camera.cameraID] = alerts;
    }
}
```

### 2. UniFi Protect Integration

```objc
// In RTSPUniFiProtectAdapter.m

- (void)enableMLXForUniFiCamera:(RTSPCameraConfig *)camera {
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

    // Create zone for camera's monitored area
    RTSPDetectionZone *zone = [[RTSPDetectionZone alloc] initWithName:camera.location
                                                                  rect:CGRectMake(0, 0, 1, 1)];

    [detector enableDetectionForCamera:camera.cameraID zones:@[zone]];

    NSLog(@"[UniFi] Enabled MLX detection for: %@", camera.name);
}
```

### 3. Recording Integration

```objc
// In RTSPRecorder.m

- (void)recordWithDetectionMetadata {
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

    // Get recent detections
    NSArray<RTSPDetectionEvent *> *events = [detector recentEvents:100];

    // Add to recording metadata
    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    metadata[@"detectionCount"] = @(events.count);
    metadata[@"recordingDate"] = [NSDate date];

    NSMutableArray *detectionData = [NSMutableArray array];
    for (RTSPDetectionEvent *event in events) {
        [detectionData addObject:@{
            @"object": event.detection.label,
            @"confidence": @(event.detection.confidence),
            @"timestamp": event.timestamp
        }];
    }
    metadata[@"detections"] = detectionData;

    // Save metadata with recording
    [self saveMetadata:metadata forRecording:self.currentRecordingPath];
}
```

## Configuration Examples

### Conservative (Low False Positives)

```objc
RTSPMLXConfiguration *config = [RTSPMLXConfiguration defaultConfiguration];
config.confidenceThreshold = 0.7;      // High confidence only
config.inferenceInterval = 5;           // Every 5th frame
config.enabledClasses = @[@"person"];   // Only people

alerts.cooldownPeriod = 120.0;          // 2 minutes between alerts
alerts.alertMode = RTSPAlertModeZone;   // Only in zones
```

### Aggressive (Catch Everything)

```objc
RTSPMLXConfiguration *config = [RTSPMLXConfiguration defaultConfiguration];
config.confidenceThreshold = 0.3;       // Lower threshold
config.inferenceInterval = 2;            // Every 2nd frame
config.enabledClasses = nil;             // All classes

alerts.cooldownPeriod = 10.0;            // 10 seconds
alerts.alertMode = RTSPAlertModeAny;     // All detections
```

### Balanced (Recommended)

```objc
RTSPMLXConfiguration *config = [RTSPMLXConfiguration recommendedConfiguration];
// Uses system defaults based on hardware

alerts.alertClasses = @[@"person", @"car", @"package"];
alerts.cooldownPeriod = 30.0;
alerts.alertMode = RTSPAlertModeSpecific;
```

## Performance Monitoring

```objc
// Get statistics
RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];
NSDictionary *stats = [detector statistics];

NSLog(@"Total events: %@", stats[@"totalEvents"]);
NSLog(@"Active cameras: %@", stats[@"enabledCameras"]);
NSLog(@"Detections by class: %@", stats[@"detectionsByClass"]);

// MLX performance
NSDictionary *mlxStats = stats[@"mlxPerformance"];
NSLog(@"Average inference time: %@ ms", mlxStats[@"averageInferenceTime"]);
NSLog(@"FPS: %@", mlxStats[@"framesPerSecond"]);
```

## Memory Management Notes

### Retain Cycle Prevention

All delegates use `weak` references:
```objc
@property (nonatomic, weak) id<RTSPObjectDetectorDelegate> delegate;
```

Timer invalidation in dealloc:
```objc
- (void)dealloc {
    [self stopMonitoring]; // Invalidates timers
}
```

### Memory Optimization

```objc
// Limit history size
detector.maxHistorySize = 500; // Keep only 500 events

// Clear old events periodically
[detector clearHistory];

// Stop detection when not needed
[detector disableDetectionForCamera:cameraID];
```

## Testing Checklist

- [ ] Model loads without errors
- [ ] Detections appear on overlay
- [ ] Alerts trigger correctly
- [ ] Zone filtering works
- [ ] Performance is acceptable (check FPS)
- [ ] Memory usage is reasonable
- [ ] Notifications work
- [ ] CSV export succeeds
- [ ] Statistics are accurate
- [ ] App doesn't crash on model errors

## Common Patterns

### Pattern 1: Single Camera with Alerts

```objc
// Simple setup for one camera
RTSPSmartAlerts *alerts = [[RTSPSmartAlerts alloc] initWithCameraID:@"front-door"
                                                          cameraName:@"Front Door"];
alerts.enabled = YES;
alerts.alertClasses = @[@"person"];
[alerts startMonitoring];
```

### Pattern 2: Multiple Cameras with Zones

```objc
// Setup for multi-camera with different zones per camera
RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

for (RTSPCameraConfig *camera in cameras) {
    // Create zone based on camera location
    RTSPDetectionZone *zone = [self zoneForCamera:camera];
    [detector enableDetectionForCamera:camera.cameraID zones:@[zone]];
}
```

### Pattern 3: Real-Time Frame Processing

```objc
// Process frames from AVCaptureSession
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {

    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];
    [detector processFrame:pixelBuffer
                fromCamera:self.cameraID
                      name:self.cameraName];
}
```

### Pattern 4: Custom Alert Logic

```objc
- (void)objectDetector:(RTSPObjectDetector *)detector
        didDetectEvent:(RTSPDetectionEvent *)event {

    // Custom logic
    if ([event.detection.label isEqualToString:@"person"] &&
        event.detection.confidence > 0.8 &&
        [self isNightTime]) {

        // High-confidence person at night
        [self sendUrgentAlert:@"Person detected at night!" event:event];
        [self startRecording:event.cameraID];
    }
}
```

## Debugging Tips

### Enable Verbose Logging

```objc
// Check if MLX is available
if ([RTSPMLXProcessor isMLXAvailable]) {
    NSLog(@"✓ MLX is available");
} else {
    NSLog(@"✗ MLX not available on this system");
}

// Monitor performance
NSTimer *statsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                       target:self
                                                     selector:@selector(logPerformance)
                                                     userInfo:nil
                                                      repeats:YES];

- (void)logPerformance {
    NSDictionary *metrics = [[RTSPMLXProcessor sharedProcessor] performanceMetrics];
    NSLog(@"MLX Performance: %@", metrics);
}
```

### Visualize Detection Zones

```objc
// Show zones in debug mode
overlayView.showZones = YES;
overlayView.style = RTSPDetectionOverlayStyleDebug;
```

### Test Detection Without Camera

```objc
// Test with static image
NSImage *testImage = [NSImage imageNamed:@"test_frame"];
CGImageRef cgImage = [testImage CGImageForProposedRect:NULL
                                               context:nil
                                                 hints:nil];

[[RTSPMLXProcessor sharedProcessor] processImage:cgImage
                                      completion:^(NSArray<RTSPDetection *> *detections, NSError *error) {
    NSLog(@"Test detections: %@", detections);
}];
```

## Error Handling

### Model Loading Errors

```objc
NSError *error = nil;
if (![processor loadModel:modelPath error:&error]) {
    if (error.code == 404) {
        // Model file not found
        [self showModelDownloadPrompt];
    } else if (error.code == 500) {
        // Model loading exception
        NSLog(@"Model incompatible: %@", error.localizedDescription);
    }
}
```

### Detection Errors

```objc
[processor processFrame:pixelBuffer
              forCamera:cameraID
             completion:^(NSArray<RTSPDetection *> *detections, NSError *error) {
    if (error) {
        if (error.code == 400) {
            // Model not loaded
            NSLog(@"Load model first");
        } else {
            NSLog(@"Detection error: %@", error);
        }
    }
}];
```

## Best Practices

### 1. Load Model Once at Startup
```objc
// ✅ Good: Load once
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self loadMLXModel];
}

// ❌ Bad: Loading multiple times
- (void)viewDidLoad {
    [self loadMLXModel]; // Don't do this in every view
}
```

### 2. Reuse Object Detector Instance
```objc
// ✅ Good: Use shared instance
RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

// ❌ Bad: Creating new instances
RTSPObjectDetector *detector = [[RTSPObjectDetector alloc] init];
```

### 3. Disable Detection When Not Visible
```objc
- (void)viewDidDisappear {
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];
    [detector disableDetectionForCamera:self.cameraID];
}

- (void)viewDidAppear {
    RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];
    [detector enableDetectionForCamera:self.cameraID zones:self.zones];
}
```

### 4. Use Zones for Better Performance
```objc
// ✅ Good: Focus on important areas
RTSPDetectionZone *entryway = [[RTSPDetectionZone alloc] initWithName:@"Entry"
                                                                  rect:CGRectMake(0.3, 0.5, 0.4, 0.4)];
[detector setZones:@[entryway] forCamera:cameraID];

// ❌ Bad: Processing entire frame when only doorway matters
[detector setZones:nil forCamera:cameraID]; // Full frame
```

## Advanced Usage

### Custom Alert Rules

```objc
- (void)setupAdvancedAlerts {
    RTSPSmartAlerts *alerts = self.smartAlerts;

    // Different rules for day vs night
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:[NSDate date]];

    if (hour >= 22 || hour <= 6) {
        // Night mode: alert on any person
        alerts.alertClasses = @[@"person"];
        alerts.confidenceThreshold = 0.6;
        alerts.cooldownPeriod = 60.0;
    } else {
        // Day mode: only packages
        alerts.alertClasses = @[@"package"];
        alerts.confidenceThreshold = 0.7;
        alerts.cooldownPeriod = 300.0;
    }
}
```

### Batch Processing

```objc
// Process multiple frames efficiently
- (void)processFrameBatch:(NSArray<NSValue *> *)pixelBuffers {
    RTSPMLXProcessor *processor = [RTSPMLXProcessor sharedProcessor];

    for (NSValue *bufferValue in pixelBuffers) {
        CVPixelBufferRef buffer = [bufferValue pointerValue];

        [processor processFrame:buffer
                      forCamera:self.cameraID
                     completion:^(NSArray<RTSPDetection *> *detections, NSError *error) {
            // Handle detections
        }];
    }
}
```

## UI Integration Examples

### Menu Bar Item with Detection Count

```objc
- (void)updateMenuBarIcon {
    NSDictionary *stats = [[RTSPObjectDetector sharedDetector] statistics];
    NSInteger eventCount = [stats[@"totalEvents"] integerValue];

    NSString *title = [NSString stringWithFormat:@"📹 %ld", (long)eventCount];
    self.statusItem.title = title;
}
```

### Preferences Panel

```objc
// Add detection settings to preferences
- (void)addMLXPreferences {
    NSView *mlxPanel = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];

    // Confidence slider
    NSSlider *confidenceSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 200, 360, 20)];
    confidenceSlider.minValue = 0.0;
    confidenceSlider.maxValue = 1.0;
    confidenceSlider.doubleValue = 0.5;

    // Class selection
    NSPopUpButton *classSelector = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(20, 150, 360, 30)];
    [classSelector addItemsWithTitles:@[@"All Classes", @"People Only", @"Vehicles Only", @"Custom"]];

    [mlxPanel addSubview:confidenceSlider];
    [mlxPanel addSubview:classSelector];
}
```

## Performance Profiling

```objc
// Log performance every 10 seconds
- (void)startPerformanceMonitoring {
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(logPerformanceMetrics)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)logPerformanceMetrics {
    RTSPMLXProcessor *processor = [RTSPMLXProcessor sharedProcessor];
    NSDictionary *metrics = [processor performanceMetrics];

    double avgInference = [metrics[@"averageInferenceTime"] doubleValue];
    double fps = [metrics[@"framesPerSecond"] doubleValue];
    NSInteger detections = [metrics[@"detectionsCount"] integerValue];

    NSLog(@"📊 MLX Performance:");
    NSLog(@"   Inference: %.1f ms", avgInference);
    NSLog(@"   FPS: %.1f", fps);
    NSLog(@"   Detections: %ld", (long)detections);
}
```

## Troubleshooting Guide

### Issue: No Detections

**Possible causes:**
1. Model not loaded
2. Confidence threshold too high
3. Camera feed not active
4. Wrong model type

**Solution:**
```objc
// Check if model is loaded
if (!processor.isProcessing) {
    NSLog(@"Model not loaded or no active cameras");
}

// Lower threshold temporarily
config.confidenceThreshold = 0.3;

// Verify camera is enabled
BOOL enabled = [detector.enabledCameras containsObject:cameraID];
NSLog(@"Camera enabled: %@", enabled ? @"YES" : @"NO");
```

### Issue: Poor Performance

**Solution:**
```objc
// Reduce processing load
config.inferenceInterval = 10; // Process every 10th frame
config.maxConcurrentStreams = 2; // Fewer cameras at once

// Use smaller model
// Switch from yolov8m to yolov8n
```

### Issue: Too Many False Positives

**Solution:**
```objc
// Increase confidence
config.confidenceThreshold = 0.7;

// Use zones
RTSPDetectionZone *zone = // ... create relevant zone only
[detector setZones:@[zone] forCamera:cameraID];

// Filter classes
alerts.alertClasses = @[@"person"]; // Ignore other objects
```

## Next Steps

1. **Download a model**: Run `./download_models.sh`
2. **Add to Xcode**: Drag model into project
3. **Test**: Build and run the app
4. **Configure**: Adjust thresholds and zones
5. **Deploy**: Archive and distribute

For complete API documentation, see `MLX_OBJECT_DETECTION.md`

---

**Version**: 2.3.0
**Date**: December 2025
**Author**: Jordan Koch
