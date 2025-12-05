//
//  RTSPPreferencesController+Extended.m
//  RTSP Rotator - Extended functionality for Configuration Manager
//
//  Created by Jordan Koch on 10/29/25.
//

#import "RTSPPreferencesController.h"
#import "RTSPFeedMetadata.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@implementation RTSPConfigurationManager (Extended)

#pragma mark - Feed Metadata Management

- (NSArray<RTSPFeedMetadata *> *)manualFeedMetadata {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"RTSPManualFeedMetadata"];
    if (!data) {
        // Migrate from old feeds array
        return [self migrateManualFeedsToMetadata];
    }

    NSError *error = nil;
    NSSet *classes = [NSSet setWithArray:@[[NSArray class], [RTSPFeedMetadata class]]];
    NSArray *metadata = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];

    if (error) {
        NSLog(@"[ERROR] Failed to unarchive feed metadata: %@", error.localizedDescription);
        return @[];
    }

    return metadata ?: @[];
}

- (void)setManualFeedMetadata:(NSArray<RTSPFeedMetadata *> *)manualFeedMetadata {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:manualFeedMetadata
                                         requiringSecureCoding:YES
                                                         error:&error];

    if (error) {
        NSLog(@"[ERROR] Failed to archive feed metadata: %@", error.localizedDescription);
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"RTSPManualFeedMetadata"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<RTSPFeedMetadata *> *)migrateManualFeedsToMetadata {
    NSArray<NSString *> *feeds = self.manualFeeds;
    NSMutableArray<RTSPFeedMetadata *> *metadata = [NSMutableArray array];

    for (NSString *url in feeds) {
        RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:url];
        [metadata addObject:feed];
    }

    if (metadata.count > 0) {
        self.manualFeedMetadata = metadata;
        NSLog(@"[INFO] Migrated %lu feeds to metadata format", (unsigned long)metadata.count);
    }

    return metadata;
}

- (void)addManualFeedWithMetadata:(RTSPFeedMetadata *)metadata {
    if (!metadata) {
        NSLog(@"[WARNING] Attempted to add nil metadata");
        return;
    }

    NSMutableArray *feeds = [self.manualFeedMetadata mutableCopy];
    [feeds addObject:metadata];
    self.manualFeedMetadata = feeds;
    [self save];

    NSLog(@"[INFO] Added feed with metadata: %@", metadata.effectiveDisplayName);
}

- (void)updateManualFeedMetadataAtIndex:(NSUInteger)index with:(RTSPFeedMetadata *)metadata {
    if (index >= self.manualFeedMetadata.count) {
        NSLog(@"[ERROR] Invalid index for updateManualFeedMetadataAtIndex");
        return;
    }

    NSMutableArray *feeds = [self.manualFeedMetadata mutableCopy];
    feeds[index] = metadata;
    self.manualFeedMetadata = feeds;
    [self save];

    NSLog(@"[INFO] Updated feed metadata at index %lu", (unsigned long)index);
}

#pragma mark - Import/Export

- (BOOL)exportFeedsToFile:(NSString *)filePath error:(NSError **)error {
    NSMutableString *content = [NSMutableString string];
    [content appendString:@"# RTSP Rotator Feed List\n"];
    [content appendFormat:@"# Exported: %@\n", [NSDate date]];
    [content appendString:@"# Format: URL,Display Name,Category,Enabled\n\n"];

    for (RTSPFeedMetadata *feed in self.manualFeedMetadata) {
        NSString *displayName = feed.displayName ?: @"";
        NSString *category = feed.category ?: @"";
        NSString *enabled = feed.enabled ? @"YES" : @"NO";

        // Escape commas and quotes in fields
        displayName = [self escapeCSVField:displayName];
        category = [self escapeCSVField:category];

        [content appendFormat:@"\"%@\",\"%@\",\"%@\",%@\n",
         feed.url, displayName, category, enabled];
    }

    BOOL success = [content writeToFile:filePath
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:error];

    if (success) {
        NSLog(@"[INFO] Exported %lu feeds to: %@", (unsigned long)self.manualFeedMetadata.count, filePath);
    } else {
        NSLog(@"[ERROR] Failed to export feeds: %@", error ? (*error).localizedDescription : @"Unknown error");
    }

    return success;
}

- (NSInteger)importFeedsFromFile:(NSString *)filePath replace:(BOOL)replace error:(NSError **)error {
    NSString *content = [NSString stringWithContentsOfFile:filePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:error];

    if (!content) {
        NSLog(@"[ERROR] Failed to read import file: %@", error ? (*error).localizedDescription : @"Unknown error");
        return 0;
    }

    NSMutableArray<RTSPFeedMetadata *> *importedFeeds = [NSMutableArray array];
    NSArray<NSString *> *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // Skip empty lines and comments
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) {
            continue;
        }

        // Parse CSV line
        NSArray<NSString *> *fields = [self parseCSVLine:trimmed];

        if (fields.count >= 1) {
            NSString *url = fields[0];
            NSString *displayName = fields.count > 1 ? fields[1] : nil;
            NSString *category = fields.count > 2 ? fields[2] : nil;
            BOOL enabled = fields.count > 3 ? [fields[3] isEqualToString:@"YES"] : YES;

            RTSPFeedMetadata *feed = [[RTSPFeedMetadata alloc] initWithURL:url displayName:displayName];
            feed.category = category;
            feed.enabled = enabled;

            [importedFeeds addObject:feed];
        }
    }

    if (importedFeeds.count == 0) {
        NSLog(@"[WARNING] No feeds found in import file");
        return 0;
    }

    // Update configuration
    if (replace) {
        self.manualFeedMetadata = importedFeeds;
    } else {
        NSMutableArray *combined = [self.manualFeedMetadata mutableCopy];
        [combined addObjectsFromArray:importedFeeds];
        self.manualFeedMetadata = combined;
    }

    [self save];
    NSLog(@"[INFO] Imported %lu feeds from: %@", (unsigned long)importedFeeds.count, filePath);

    return importedFeeds.count;
}

- (NSString *)escapeCSVField:(NSString *)field {
    if ([field containsString:@"\""] || [field containsString:@","] || [field containsString:@"\n"]) {
        // Escape quotes by doubling them
        field = [field stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
        return field;
    }
    return field;
}

- (NSArray<NSString *> *)parseCSVLine:(NSString *)line {
    NSMutableArray *fields = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:line];
    scanner.charactersToBeSkipped = nil;

    while (!scanner.isAtEnd) {
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];

        if ([scanner scanString:@"\"" intoString:nil]) {
            // Quoted field
            NSMutableString *field = [NSMutableString string];
            while (!scanner.isAtEnd) {
                NSString *chunk;
                if ([scanner scanUpToString:@"\"" intoString:&chunk]) {
                    [field appendString:chunk];
                }
                if ([scanner scanString:@"\"" intoString:nil]) {
                    if ([scanner scanString:@"\"" intoString:nil]) {
                        // Escaped quote
                        [field appendString:@"\""];
                    } else {
                        // End of field
                        break;
                    }
                }
            }
            [fields addObject:field];
        } else {
            // Unquoted field
            NSString *field;
            [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",\n"]
                                    intoString:&field];
            if (field) {
                [fields addObject:[field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            }
        }

        [scanner scanString:@"," intoString:nil];
    }

    return fields;
}

#pragma mark - Feed Testing

- (void)testFeedConnectivity:(NSString *)feedURL
                  completion:(void (^)(BOOL, NSTimeInterval, NSError * _Nullable))completion {

    if (!feedURL || feedURL.length == 0) {
        NSError *error = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                             code:2001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid feed URL"}];
        if (completion) completion(NO, 0, error);
        return;
    }

    NSLog(@"[INFO] Testing feed connectivity: %@", feedURL);

    NSDate *startTime = [NSDate date];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
        AVPlayer *testPlayer = [[AVPlayer alloc] init];
        NSURL *url = [NSURL URLWithString:feedURL];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];

        if (!playerItem) {
            NSError *error = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                                 code:2002
                                             userInfo:@{NSLocalizedDescriptionKey: @"Failed to create player item"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, 0, error);
            });
            return;
        }

        // Wait for state change with timeout
        __block BOOL completed = NO;
        __block BOOL testSuccess = NO;

        // Add completion handler for status changes
        dispatch_async(dispatch_get_main_queue(), ^{
            [testPlayer replaceCurrentItemWithPlayerItem:playerItem];
            [testPlayer play];
        });

        // Wait with timeout (5 seconds) and check status periodically
        NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
        while (!completed && [[NSDate date] compare:timeoutDate] == NSOrderedAscending) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

            // Check status directly
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                testSuccess = YES;
                completed = YES;
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                testSuccess = NO;
                completed = YES;
            }
        }

        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:startTime];

        [testPlayer pause];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completed && testSuccess) {
                NSLog(@"[INFO] Feed test successful (%.2fs): %@", latency, feedURL);
                if (completion) completion(YES, latency, nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"RTSPConfigurationManager"
                                                     code:2003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Connection timeout or failed"}];
                NSLog(@"[ERROR] Feed test failed (%.2fs): %@", latency, feedURL);
                if (completion) completion(NO, latency, error);
            }
        });
    });
}

@end
