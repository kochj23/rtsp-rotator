//
//  RTSPEventLogger.m
//  RTSP Rotator
//

#import "RTSPEventLogger.h"

@implementation RTSPEvent

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _eventID = [[NSUUID UUID] UUIDString];
        _timestamp = [NSDate date];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.eventID forKey:@"eventID"];
    [coder encodeInteger:self.type forKey:@"type"];
    [coder encodeObject:self.timestamp forKey:@"timestamp"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.details forKey:@"details"];
    [coder encodeObject:self.feedURL forKey:@"feedURL"];
    // Note: NSImage can be encoded but we'll skip for simplicity
    [coder encodeObject:self.metadata forKey:@"metadata"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _eventID = [coder decodeObjectOfClass:[NSString class] forKey:@"eventID"];
        _type = [coder decodeIntegerForKey:@"type"];
        _timestamp = [coder decodeObjectOfClass:[NSDate class] forKey:@"timestamp"];
        _title = [coder decodeObjectOfClass:[NSString class] forKey:@"title"];
        _details = [coder decodeObjectOfClass:[NSString class] forKey:@"details"];
        _feedURL = [coder decodeObjectOfClass:[NSURL class] forKey:@"feedURL"];
        _metadata = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"metadata"];
    }
    return self;
}

@end

@interface RTSPEventLogger ()
@property (nonatomic, strong) NSMutableArray<RTSPEvent *> *allEvents;
@end

@implementation RTSPEventLogger

+ (instancetype)sharedLogger {
    static RTSPEventLogger *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RTSPEventLogger alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allEvents = [NSMutableArray array];
        _loggingEnabled = YES;
        _maxEventsInMemory = 1000;

        [self loadEvents];
    }
    return self;
}

- (NSArray<RTSPEvent *> *)events {
    return [self.allEvents copy];
}

- (void)logEvent:(RTSPEvent *)event {
    if (!self.loggingEnabled) {
        return;
    }

    [self.allEvents addObject:event];

    // Trim if exceeds maximum
    if (self.allEvents.count > self.maxEventsInMemory) {
        [self.allEvents removeObjectAtIndex:0];
    }

    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(eventLogger:didLogEvent:)]) {
        [self.delegate eventLogger:self didLogEvent:event];
    }

    // Auto-save periodically
    if (self.allEvents.count % 10 == 0) {
        [self saveEvents];
    }

    NSLog(@"[Events] %@: %@", [RTSPEventLogger nameForEventType:event.type], event.title);
}

- (void)logEventType:(RTSPEventType)type title:(NSString *)title details:(NSString *)details feedURL:(NSURL *)feedURL {
    RTSPEvent *event = [[RTSPEvent alloc] init];
    event.type = type;
    event.title = title;
    event.details = details;
    event.feedURL = feedURL;

    [self logEvent:event];
}

- (NSArray<RTSPEvent *> *)eventsWithType:(RTSPEventType)type {
    return [self.allEvents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RTSPEvent *event, NSDictionary *bindings) {
        return event.type == type;
    }]];
}

- (NSArray<RTSPEvent *> *)eventsFromDate:(NSDate *)startDate toDate:(NSDate *)endDate {
    return [self.allEvents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RTSPEvent *event, NSDictionary *bindings) {
        return [event.timestamp compare:startDate] != NSOrderedAscending && [event.timestamp compare:endDate] != NSOrderedDescending;
    }]];
}

- (NSArray<RTSPEvent *> *)eventsForFeedURL:(NSURL *)feedURL {
    return [self.allEvents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RTSPEvent *event, NSDictionary *bindings) {
        return event.feedURL && [event.feedURL.absoluteString isEqualToString:feedURL.absoluteString];
    }]];
}

- (NSArray<RTSPEvent *> *)searchEventsWithQuery:(NSString *)query {
    NSString *lowerQuery = [query lowercaseString];

    return [self.allEvents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RTSPEvent *event, NSDictionary *bindings) {
        NSString *title = [event.title lowercaseString];
        NSString *details = [event.details lowercaseString];

        return [title containsString:lowerQuery] || [details containsString:lowerQuery];
    }]];
}

- (void)clearAllEvents {
    [self.allEvents removeAllObjects];
    [self saveEvents];

    NSLog(@"[Events] Cleared all events");
}

- (void)clearEventsBeforeDate:(NSDate *)date {
    NSArray *eventsToKeep = [self.allEvents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RTSPEvent *event, NSDictionary *bindings) {
        return [event.timestamp compare:date] != NSOrderedAscending;
    }]];

    self.allEvents = [NSMutableArray arrayWithArray:eventsToKeep];
    [self saveEvents];

    NSLog(@"[Events] Cleared events before %@", date);
}

- (BOOL)exportToCSV:(NSString *)filePath {
    NSMutableString *csv = [NSMutableString string];

    // Header
    [csv appendString:@"Timestamp,Type,Title,Details,Feed URL\n"];

    // Data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";

    for (RTSPEvent *event in self.allEvents) {
        NSString *timestamp = [formatter stringFromDate:event.timestamp];
        NSString *type = [RTSPEventLogger nameForEventType:event.type];
        NSString *title = [event.title stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
        NSString *details = event.details ? [event.details stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @"";
        NSString *feedURL = event.feedURL ? event.feedURL.absoluteString : @"";

        [csv appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\"\n", timestamp, type, title, details, feedURL];
    }

    NSError *error = nil;
    BOOL success = [csv writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

    if (success) {
        NSLog(@"[Events] Exported events to CSV: %@", filePath);
    } else {
        NSLog(@"[Events] Failed to export CSV: %@", error);
    }

    return success;
}

- (BOOL)exportToPDF:(NSString *)filePath {
    // Simplified PDF export (production would use PDFKit or NSPrintOperation)
    NSMutableString *text = [NSMutableString string];

    [text appendString:@"RTSP Rotator Event Timeline\n"];
    [text appendFormat:@"Generated: %@\n\n", [NSDate date]];
    [text appendFormat:@"Total Events: %lu\n\n", (unsigned long)self.allEvents.count];
    [text appendString:@"================================================================================\n\n"];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";

    for (RTSPEvent *event in self.allEvents) {
        [text appendFormat:@"[%@] %@\n", [formatter stringFromDate:event.timestamp], [RTSPEventLogger nameForEventType:event.type]];
        [text appendFormat:@"Title: %@\n", event.title];

        if (event.details) {
            [text appendFormat:@"Details: %@\n", event.details];
        }

        if (event.feedURL) {
            [text appendFormat:@"Feed: %@\n", event.feedURL.absoluteString];
        }

        [text appendString:@"\n"];
    }

    NSError *error = nil;
    BOOL success = [text writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

    if (success) {
        NSLog(@"[Events] Exported events to PDF: %@", filePath);
    } else {
        NSLog(@"[Events] Failed to export PDF: %@", error);
    }

    return success;
}

- (BOOL)saveEvents {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *appFolder = [appSupport stringByAppendingPathComponent:@"RTSP Rotator"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appFolder]) {
        [fm createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *eventsPath = [appFolder stringByAppendingPathComponent:@"events.dat"];

    NSError *error = nil;
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:self.allEvents requiringSecureCoding:YES error:&error];

    if (error) {
        NSLog(@"[Events] Failed to archive events: %@", error);
        return NO;
    }

    BOOL success = [archiveData writeToFile:eventsPath atomically:YES];

    if (!success) {
        NSLog(@"[Events] Failed to save events to disk");
    }

    return success;
}

- (BOOL)loadEvents {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *eventsPath = [[appSupport stringByAppendingPathComponent:@"RTSP Rotator"] stringByAppendingPathComponent:@"events.dat"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:eventsPath]) {
        NSLog(@"[Events] No saved events found");
        return NO;
    }

    NSError *error = nil;
    NSData *archiveData = [NSData dataWithContentsOfFile:eventsPath];

    NSSet *classes = [NSSet setWithArray:@[[NSArray class], [RTSPEvent class], [NSString class], [NSDate class], [NSURL class], [NSDictionary class]]];
    NSArray *loadedEvents = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:archiveData error:&error];

    if (error) {
        NSLog(@"[Events] Failed to unarchive events: %@", error);
        return NO;
    }

    self.allEvents = [NSMutableArray arrayWithArray:loadedEvents];

    NSLog(@"[Events] Loaded %lu events from disk", (unsigned long)self.allEvents.count);
    return YES;
}

+ (NSString *)nameForEventType:(RTSPEventType)type {
    switch (type) {
        case RTSPEventTypeFeedSwitch: return @"Feed Switch";
        case RTSPEventTypeSnapshot: return @"Snapshot";
        case RTSPEventTypeRecordingStarted: return @"Recording Started";
        case RTSPEventTypeRecordingStopped: return @"Recording Stopped";
        case RTSPEventTypeMotionDetected: return @"Motion Detected";
        case RTSPEventTypeAudioAlert: return @"Audio Alert";
        case RTSPEventTypeConnectionFailed: return @"Connection Failed";
        case RTSPEventTypeFailover: return @"Failover";
        case RTSPEventTypeBookmarkActivated: return @"Bookmark Activated";
        case RTSPEventTypeScheduleActivated: return @"Schedule Activated";
        case RTSPEventTypeError: return @"Error";
        case RTSPEventTypeWarning: return @"Warning";
        case RTSPEventTypeInfo: return @"Info";
    }
}

+ (NSImage *)iconForEventType:(RTSPEventType)type {
    NSString *iconName;

    switch (type) {
        case RTSPEventTypeFeedSwitch: iconName = NSImageNameCaution; break;
        case RTSPEventTypeSnapshot: iconName = NSImageNameActionTemplate; break;
        case RTSPEventTypeRecordingStarted: iconName = NSImageNameStatusAvailable; break;
        case RTSPEventTypeRecordingStopped: iconName = NSImageNameStatusUnavailable; break;
        case RTSPEventTypeMotionDetected: iconName = NSImageNameCaution; break;
        case RTSPEventTypeAudioAlert: iconName = NSImageNameCaution; break;
        case RTSPEventTypeConnectionFailed: iconName = NSImageNameStatusUnavailable; break;
        case RTSPEventTypeFailover: iconName = NSImageNameRefreshTemplate; break;
        case RTSPEventTypeBookmarkActivated: iconName = NSImageNameBookmarksTemplate; break;
        case RTSPEventTypeScheduleActivated: iconName = NSImageNameActionTemplate; break;
        case RTSPEventTypeError: iconName = NSImageNameStatusUnavailable; break;
        case RTSPEventTypeWarning: iconName = NSImageNameCaution; break;
        case RTSPEventTypeInfo: iconName = NSImageNameInfo; break;
        default: iconName = NSImageNameInfo; break;
    }

    return [NSImage imageNamed:iconName];
}

@end
