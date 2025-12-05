//
//  RTSPEventLogger.h
//  RTSP Rotator
//
//  Event timeline and activity logging
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPEventType) {
    RTSPEventTypeFeedSwitch,
    RTSPEventTypeSnapshot,
    RTSPEventTypeRecordingStarted,
    RTSPEventTypeRecordingStopped,
    RTSPEventTypeMotionDetected,
    RTSPEventTypeAudioAlert,
    RTSPEventTypeConnectionFailed,
    RTSPEventTypeFailover,
    RTSPEventTypeBookmarkActivated,
    RTSPEventTypeScheduleActivated,
    RTSPEventTypeError,
    RTSPEventTypeWarning,
    RTSPEventTypeInfo
};

/// Event record
@interface RTSPEvent : NSObject <NSCoding, NSSecureCoding>
@property (nonatomic, strong) NSString *eventID;
@property (nonatomic, assign) RTSPEventType type;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, nullable) NSString *details;
@property (nonatomic, strong, nullable) NSURL *feedURL;
@property (nonatomic, strong, nullable) NSImage *thumbnail;
@property (nonatomic, strong, nullable) NSDictionary *metadata;
@end

@class RTSPEventLogger;

/// Event logger delegate
@protocol RTSPEventLoggerDelegate <NSObject>
@optional
- (void)eventLogger:(RTSPEventLogger *)logger didLogEvent:(RTSPEvent *)event;
@end

/// Event timeline and logging system
@interface RTSPEventLogger : NSObject

/// Shared instance
+ (instancetype)sharedLogger;

/// Delegate for event notifications
@property (nonatomic, weak) id<RTSPEventLoggerDelegate> delegate;

/// Enable logging (default: YES)
@property (nonatomic, assign) BOOL loggingEnabled;

/// Maximum events to keep in memory (default: 1000)
@property (nonatomic, assign) NSInteger maxEventsInMemory;

/// All events
- (NSArray<RTSPEvent *> *)events;

/// Log event
- (void)logEvent:(RTSPEvent *)event;

/// Log event with details
- (void)logEventType:(RTSPEventType)type title:(NSString *)title details:(nullable NSString *)details feedURL:(nullable NSURL *)feedURL;

/// Get events by type
- (NSArray<RTSPEvent *> *)eventsWithType:(RTSPEventType)type;

/// Get events in date range
- (NSArray<RTSPEvent *> *)eventsFromDate:(NSDate *)startDate toDate:(NSDate *)endDate;

/// Get events for feed
- (NSArray<RTSPEvent *> *)eventsForFeedURL:(NSURL *)feedURL;

/// Search events
- (NSArray<RTSPEvent *> *)searchEventsWithQuery:(NSString *)query;

/// Clear all events
- (void)clearAllEvents;

/// Clear events before date
- (void)clearEventsBeforeDate:(NSDate *)date;

/// Export events to CSV
- (BOOL)exportToCSV:(NSString *)filePath;

/// Export events to PDF
- (BOOL)exportToPDF:(NSString *)filePath;

/// Save events to disk
- (BOOL)saveEvents;

/// Load events from disk
- (BOOL)loadEvents;

/// Get display name for event type
+ (NSString *)nameForEventType:(RTSPEventType)type;

/// Get icon for event type
+ (NSImage *)iconForEventType:(RTSPEventType)type;

@end

NS_ASSUME_NONNULL_END
