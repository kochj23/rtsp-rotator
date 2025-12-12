# MLX Object Detection - RTSP Rotator

## Overview

RTSP Rotator now includes **powerful on-device machine learning** powered by Apple's CoreML and optimized for Apple Silicon with MLX-style architecture. This enables real-time object detection on camera feeds with zero cloud dependencies.

## Features

### ✅ Real-Time Object Detection
- Detect people, vehicles, animals, packages, and more
- Process multiple camera streams simultaneously
- Optimized for Apple Silicon (M1/M2/M3+)
- Runs entirely on-device (no internet required)

### ✅ Smart Alerts
- Configurable alert rules per object type
- Zone-based detection (alert only in specific areas)
- Cooldown periods to prevent alert spam
- System notifications and sound alerts
- Alert history and statistics

### ✅ Visual Overlays
- Real-time bounding boxes on video
- Confidence scores and labels
- Animated detection highlights
- Custom colors per object class
- Zone visualization

### ✅ Performance
- 30-60 FPS on Apple Silicon
- 15-30 FPS on Intel Macs
- Minimal CPU/GPU impact
- Configurable processing intervals
- Automatic hardware optimization

## Architecture

### Core Components

```
RTSPMLXProcessor
├── Model loading and management
├── Frame-by-frame inference
├── GPU acceleration
└── Performance monitoring

RTSPObjectDetector
├── Multi-camera management
├── Detection zones
├── Event logging
└── CSV export

RTSPSmartAlerts
├── Alert rules and filtering
├── Cooldown management
├── Notifications
└── Sound alerts

RTSPDetectionOverlayView
├── Visual rendering
├── Bounding boxes
├── Labels and confidence
└── Zone visualization
```

## Setup Instructions

### 1. Download a CoreML Model

You need a CoreML object detection model. Recommended options:

#### Option A: YOLOv8 (Recommended)
```bash
# Download YOLOv8-nano (fast, ~6MB)
curl -L "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.mlmodel" -o ~/Desktop/yolov8n.mlmodel

# Or YOLOv8-small (balanced, ~22MB)
curl -L "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s.mlmodel" -o ~/Desktop/yolov8s.mlmodel
```

#### Option B: Use Apple's Built-in Models
The code includes fallback to Apple's Vision framework for animal detection.

#### Option C: Train Your Own
Use CreateML or convert PyTorch/TensorFlow models to CoreML.

### 2. Add Model to Project

1. Drag the `.mlmodel` file into Xcode
2. Check "Copy items if needed"
3. Add to target: "RTSP Rotator"

### 3. Initialize Object Detection

```objc
#import "RTSPMLXProcessor.h"
#import "RTSPObjectDetector.h"

// Initialize the MLX processor
RTSPMLXProcessor *processor = [RTSPMLXProcessor sharedProcessor];

// Load your model
NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"yolov8n" ofType:@"mlmodel"];
NSError *error = nil;
BOOL success = [processor loadModel:modelPath error:&error];

if (success) {
    NSLog(@"Model loaded successfully!");
} else {
    NSLog(@"Error loading model: %@", error);
}
```

### 4. Enable Detection for Camera

```objc
RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];

// Enable detection for a camera
[detector enableDetectionForCamera:@"camera-1" zones:nil];

// Process frames
CVPixelBufferRef pixelBuffer = // ... get from video stream
[detector processFrame:pixelBuffer
            fromCamera:@"camera-1"
                  name:@"Front Door"];
```

### 5. Set Up Smart Alerts

```objc
#import "RTSPSmartAlerts.h"

RTSPSmartAlerts *alerts = [[RTSPSmartAlerts alloc] initWithCameraID:@"camera-1"
                                                          cameraName:@"Front Door"];
alerts.enabled = YES;
alerts.useMLX = YES;
alerts.alertMode = RTSPAlertModeSpecific;
alerts.alertClasses = @[@"person", @"car", @"package"];
alerts.cooldownPeriod = 30.0; // 30 seconds between alerts

[alerts startMonitoring];
```

### 6. Add Visual Overlay

```objc
#import "RTSPDetectionOverlayView.h"

// Create overlay view
RTSPDetectionOverlayView *overlayView = [[RTSPDetectionOverlayView alloc] initWithFrame:videoView.bounds];
overlayView.showLabels = YES;
overlayView.showConfidence = YES;
[videoView addSubview:overlayView];

// Update with detections
[overlayView updateDetections:detectionsArray];
```

## Configuration

### MLX Processor Configuration

```objc
RTSPMLXConfiguration *config = [RTSPMLXConfiguration defaultConfiguration];
config.useGPU = YES;                      // Enable GPU acceleration
config.maxConcurrentStreams = 4;          // Max simultaneous streams
config.confidenceThreshold = 0.5;        // Minimum detection confidence
config.iouThreshold = 0.45;               // Non-max suppression
config.inferenceInterval = 3;             // Process every 3rd frame
config.enabledClasses = @[@"person", @"car"]; // Filter classes (nil = all)

processor.configuration = config;
```

### Detection Zones

```objc
// Create a zone for driveway
RTSPDetectionZone *driveway = [[RTSPDetectionZone alloc] initWithName:@"Driveway"
                                                                 rect:CGRectMake(0.2, 0.5, 0.6, 0.4)];
driveway.enabledClasses = @[@"person", @"car"];

// Apply to camera
[detector setZones:@[driveway] forCamera:@"camera-1"];
```

### Alert Configuration

```objc
// Configure alerts
alerts.alertMode = RTSPAlertModeSpecific;
alerts.alertClasses = @[@"person"];        // Only alert on people
alerts.confidenceThreshold = 0.6;          // 60% confidence minimum
alerts.cooldownPeriod = 60.0;              // 1 minute cooldown
alerts.sendSystemNotifications = YES;
alerts.playAlertSound = YES;
alerts.alertSoundName = @"Ping";
```

## Usage Examples

### Example 1: Front Door Person Detection

```objc
// Setup detector
RTSPObjectDetector *detector = [RTSPObjectDetector sharedDetector];
[detector enableDetectionForCamera:@"front-door" zones:nil];

// Setup alerts
RTSPSmartAlerts *alerts = [[RTSPSmartAlerts alloc] initWithCameraID:@"front-door"
                                                          cameraName:@"Front Door"];
alerts.enabled = YES;
alerts.alertClasses = @[@"person"];
alerts.cooldownPeriod = 30.0;
[alerts startMonitoring];

// Process video frames
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [alerts processFrame:pixelBuffer];
}
```

### Example 2: Package Delivery Detection

```objc
// Create zone for front porch
RTSPDetectionZone *porch = [[RTSPDetectionZone alloc] initWithName:@"Porch"
                                                               rect:CGRectMake(0.3, 0.6, 0.4, 0.3)];
porch.enabledClasses = @[@"person", @"package"];

[detector setZones:@[porch] forCamera:@"front-door"];

// Alert on packages
alerts.alertClasses = @[@"package"];
alerts.cooldownPeriod = 300.0; // 5 minutes
```

### Example 3: Vehicle Detection in Driveway

```objc
// Driveway zone
RTSPDetectionZone *driveway = [[RTSPDetectionZone alloc] initWithName:@"Driveway"
                                                                  rect:CGRectMake(0.0, 0.5, 1.0, 0.5)];
driveway.enabledClasses = @[@"car", @"truck", @"motorcycle"];

[detector setZones:@[driveway] forCamera:@"driveway-cam"];

// Alert on vehicles
alerts.alertClasses = @[@"car", @"truck"];
alerts.cooldownPeriod = 60.0;
```

## API Reference

### RTSPMLXProcessor

```objc
// Load model
- (BOOL)loadModel:(NSString *)modelPath error:(NSError **)error;

// Process frame
- (void)processFrame:(CVPixelBufferRef)pixelBuffer
           forCamera:(NSString *)cameraID
          completion:(void (^)(NSArray<RTSPDetection *> *, NSError *))completion;

// Stop processing
- (void)stopProcessingForCamera:(NSString *)cameraID;
- (void)stopAllProcessing;

// Statistics
- (NSDictionary *)performanceMetrics;
- (void)resetStatistics;
```

### RTSPObjectDetector

```objc
// Enable/disable detection
- (void)enableDetectionForCamera:(NSString *)cameraID
                           zones:(NSArray<RTSPDetectionZone *> *)zones;
- (void)disableDetectionForCamera:(NSString *)cameraID;

// Process frames
- (void)processFrame:(CVPixelBufferRef)pixelBuffer
          fromCamera:(NSString *)cameraID
                name:(NSString *)cameraName;

// Zone management
- (void)setZones:(NSArray<RTSPDetectionZone *> *)zones
      forCamera:(NSString *)cameraID;

// History and statistics
- (NSArray<RTSPDetectionEvent *> *)recentEvents:(NSInteger)limit;
- (NSDictionary *)statistics;
- (BOOL)exportEventsToCSV:(NSString *)filePath error:(NSError **)error;
```

### RTSPSmartAlerts

```objc
// Start/stop monitoring
- (void)startMonitoring;
- (void)stopMonitoring;

// Process frame
- (void)processFrame:(CVPixelBufferRef)pixelBuffer;

// Statistics
- (void)resetStatistics;
- (NSArray<RTSPDetectionEvent *> *)alertHistory:(NSInteger)limit;
```

### RTSPDetectionOverlayView

```objc
// Update display
- (void)updateDetections:(NSArray<RTSPDetection *> *)detections;
- (void)clearDetections;

// Configuration
@property (nonatomic, assign) RTSPDetectionOverlayStyle style;
@property (nonatomic, assign) BOOL showConfidence;
@property (nonatomic, assign) BOOL showLabels;
@property (nonatomic, assign) BOOL showZones;
```

## Performance Tips

### 1. Optimize for Your Hardware

```objc
// Automatically detect and optimize
RTSPMLXConfiguration *config = [RTSPMLXConfiguration recommendedConfiguration];
processor.configuration = config;
```

### 2. Adjust Processing Interval

```objc
// Process fewer frames for better performance
config.inferenceInterval = 5; // Process every 5th frame
```

### 3. Limit Concurrent Streams

```objc
// Reduce concurrent cameras if performance is an issue
config.maxConcurrentStreams = 2;
```

### 4. Use Smaller Models

- YOLOv8-nano: Fast, lower accuracy (~6MB)
- YOLOv8-small: Balanced (22MB)
- YOLOv8-medium: Higher accuracy, slower (~50MB)

### 5. Enable GPU Acceleration

```objc
config.useGPU = YES; // Default, use Neural Engine + GPU
```

## Supported Object Classes

Standard COCO dataset classes (80 objects):

- **People**: person
- **Vehicles**: car, truck, bus, motorcycle, bicycle, train, airplane, boat
- **Animals**: dog, cat, bird, horse, cow, sheep, elephant, bear, zebra, giraffe
- **Items**: backpack, umbrella, handbag, suitcase, bottle, cup, fork, knife, spoon, bowl
- **Furniture**: chair, couch, bed, dining table, toilet
- **Electronics**: tv, laptop, mouse, remote, keyboard, cell phone
- **And more**: See COCO dataset for full list

## Troubleshooting

### Model Won't Load

```
Error: Model file not found
```
**Solution**: Ensure the model file is added to Xcode project and target.

### Low Performance

```
FPS dropping below 10
```
**Solutions**:
- Increase `inferenceInterval`
- Use smaller model (yolov8n instead of yolov8m)
- Reduce `maxConcurrentStreams`
- Check Activity Monitor for CPU/GPU usage

### No Detections

```
No objects detected
```
**Solutions**:
- Lower `confidenceThreshold` (try 0.3)
- Check camera feed is active
- Verify model supports expected classes
- Enable debug logging

### Memory Issues

```
App using too much memory
```
**Solutions**:
- Reduce `maxHistorySize` in RTSPObjectDetector
- Limit alert history size
- Stop detection on inactive cameras
- Clear detection history periodically

## Logging and Debugging

Enable detailed logging:

```objc
// Check if MLX is available
if ([RTSPMLXProcessor isMLXAvailable]) {
    NSLog(@"MLX is available on this system");
}

// Monitor performance
NSDictionary *metrics = [processor performanceMetrics];
NSLog(@"Performance: %@", metrics);
// Output: {
//   framesProcessed: 1000,
//   detectionsCount: 45,
//   averageInferenceTime: 25.5,  // milliseconds
//   activeCameras: 2,
//   framesPerSecond: 28.3
// }
```

## Privacy & Security

✅ **100% On-Device Processing**
- No video leaves your Mac
- No cloud dependencies
- No internet required
- GDPR compliant

✅ **Local Storage Only**
- Detection history stored locally
- Export to CSV for analysis
- No external data transmission

## License

This MLX integration is part of RTSP Rotator and follows the MIT License.

## Credits

- Jordan Koch - Author
- Built by Jordan Koch
- Powered by Apple CoreML and Vision frameworks
- Optimized for Apple Silicon

## Support

For issues or questions:
1. Check this documentation
2. Review example code
3. Enable debug logging
4. Check system requirements (macOS 11.0+)

---

**Version**: 2.3.0
**Last Updated**: December 2025
**Minimum macOS**: 11.0 (Big Sur)
**Recommended**: macOS 13.0+ with Apple Silicon
