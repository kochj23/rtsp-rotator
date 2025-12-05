//
//  RTSPRecorder.h
//  RTSP Rotator
//
//  Created by Jordan Koch on 10/29/25.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Manages recording and snapshot functionality for RTSP streams
@interface RTSPRecorder : NSObject

/// Initialize with AVPlayer
- (instancetype)initWithPlayer:(AVPlayer *)player;

#pragma mark - Snapshots

/// Take a snapshot of the current frame
/// @param completion Completion handler with image or error
- (void)takeSnapshotWithCompletion:(void (^)(NSImage * _Nullable image, NSError * _Nullable error))completion;

/// Save snapshot to file
/// @param filePath Destination file path
/// @param completion Completion handler with success status
- (void)saveSnapshotToFile:(NSString *)filePath
                completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/// Take and save snapshot with auto-generated filename
/// @param directory Directory to save snapshot
/// @param completion Completion handler with file path or error
- (void)autoSaveSnapshotToDirectory:(NSString *)directory
                         completion:(void (^)(NSString * _Nullable filePath, NSError * _Nullable error))completion;

#pragma mark - Recording

/// Start recording current stream
/// @param filePath Output file path
/// @param completion Completion handler with success status
- (void)startRecordingToFile:(NSString *)filePath
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/// Stop current recording
- (void)stopRecording;

/// Whether currently recording
@property (nonatomic, assign, readonly) BOOL isRecording;

/// Current recording file path
@property (nonatomic, strong, readonly, nullable) NSString *recordingFilePath;

/// Recording duration
@property (nonatomic, assign, readonly) NSTimeInterval recordingDuration;

#pragma mark - Scheduled Snapshots

/// Schedule periodic snapshots
/// @param interval Time between snapshots
/// @param directory Directory to save snapshots
- (void)scheduleSnapshotsWithInterval:(NSTimeInterval)interval
                          toDirectory:(NSString *)directory;

/// Stop scheduled snapshots
- (void)stopScheduledSnapshots;

/// Whether scheduled snapshots are active
@property (nonatomic, assign, readonly) BOOL scheduledSnapshotsActive;

@end

NS_ASSUME_NONNULL_END
