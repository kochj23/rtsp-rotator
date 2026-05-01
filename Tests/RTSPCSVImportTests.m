//
//  RTSPCSVImportTests.m
//  RTSP Rotator Tests
//
//  Functional tests for CSV camera import and URL validation
//  Written by Jordan Koch
//

#import <XCTest/XCTest.h>

@interface RTSPCSVImportTests : XCTestCase
@end

@implementation RTSPCSVImportTests

#pragma mark - CSV Line Parsing

/// Helper: Parse a CSV line handling quoted fields (mirrors AppDelegate's parseCSVLine:)
- (NSArray<NSString *> *)parseCSVLine:(NSString *)line {
    NSMutableArray *fields = [NSMutableArray array];
    NSMutableString *currentField = [NSMutableString string];
    BOOL insideQuotes = NO;

    for (NSInteger i = 0; i < line.length; i++) {
        unichar c = [line characterAtIndex:i];

        if (c == '"') {
            insideQuotes = !insideQuotes;
        } else if (c == ',' && !insideQuotes) {
            [fields addObject:[currentField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            [currentField setString:@""];
        } else {
            [currentField appendFormat:@"%C", c];
        }
    }

    // Add last field
    [fields addObject:[currentField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];

    return [fields copy];
}

#pragma mark - Basic CSV Parsing Tests

- (void)testParseSimpleCSVLine {
    NSArray *fields = [self parseCSVLine:@"Front Door,rtsp://192.168.1.100:554/stream,rtsp"];
    XCTAssertEqual(fields.count, 3);
    XCTAssertEqualObjects(fields[0], @"Front Door");
    XCTAssertEqualObjects(fields[1], @"rtsp://192.168.1.100:554/stream");
    XCTAssertEqualObjects(fields[2], @"rtsp");
}

- (void)testParseCSVLineWithQuotedFields {
    NSArray *fields = [self parseCSVLine:@"\"Garage (Main)\",rtsp://192.168.1.101:554/stream,rtsp"];
    XCTAssertEqual(fields.count, 3);
    XCTAssertEqualObjects(fields[0], @"Garage (Main)");
}

- (void)testParseCSVLineWithCommaInQuotedField {
    NSArray *fields = [self parseCSVLine:@"\"Camera, Front\",rtsp://camera.example.com/stream,rtsp"];
    XCTAssertEqual(fields.count, 3);
    XCTAssertEqualObjects(fields[0], @"Camera, Front");
}

- (void)testParseCSVLineWithTwoFields {
    // Some CSV files might only have name,url without type
    NSArray *fields = [self parseCSVLine:@"Backyard,rtsp://192.168.1.102:554/stream"];
    XCTAssertEqual(fields.count, 2);
    XCTAssertEqualObjects(fields[0], @"Backyard");
    XCTAssertEqualObjects(fields[1], @"rtsp://192.168.1.102:554/stream");
}

- (void)testParseCSVLineWithWhitespace {
    NSArray *fields = [self parseCSVLine:@"  Living Room  , rtsp://camera.example.com/stream , rtsp "];
    XCTAssertEqual(fields.count, 3);
    XCTAssertEqualObjects(fields[0], @"Living Room");
    XCTAssertEqualObjects(fields[1], @"rtsp://camera.example.com/stream");
    XCTAssertEqualObjects(fields[2], @"rtsp");
}

- (void)testParseEmptyCSVLine {
    NSArray *fields = [self parseCSVLine:@""];
    XCTAssertEqual(fields.count, 1);
    XCTAssertEqualObjects(fields[0], @"");
}

- (void)testParseSingleFieldCSVLine {
    NSArray *fields = [self parseCSVLine:@"OnlyOneName"];
    XCTAssertEqual(fields.count, 1);
    XCTAssertEqualObjects(fields[0], @"OnlyOneName");
}

#pragma mark - Full CSV Content Parsing

/// Helper: Parse full CSV content into an array of camera entries
- (NSArray<NSDictionary *> *)parseCamerasFromCSV:(NSString *)csvContent {
    NSArray *lines = [csvContent componentsSeparatedByString:@"\n"];
    NSMutableArray *cameras = [NSMutableArray array];
    NSInteger lineNumber = 0;

    for (NSString *line in lines) {
        lineNumber++;
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // Skip empty lines and comments
        if (trimmedLine.length == 0 || [trimmedLine hasPrefix:@"#"]) {
            continue;
        }

        // Skip header line
        if (lineNumber == 1 && ([trimmedLine.lowercaseString containsString:@"name"] ||
                                [trimmedLine.lowercaseString containsString:@"url"])) {
            continue;
        }

        NSArray *fields = [self parseCSVLine:trimmedLine];
        if (fields.count < 2) {
            continue;
        }

        NSString *name = fields[0];
        NSString *url = fields[1];

        // Validate URL
        if (![url hasPrefix:@"rtsp://"] && ![url hasPrefix:@"rtsps://"] &&
            ![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
            continue;
        }

        NSMutableDictionary *camera = [NSMutableDictionary dictionary];
        camera[@"name"] = name;
        camera[@"url"] = url;
        camera[@"line"] = @(lineNumber);
        if (fields.count >= 3) {
            camera[@"type"] = fields[2];
        }
        [cameras addObject:camera];
    }

    return [cameras copy];
}

- (void)testParseStandardCSVContent {
    NSString *csv = @"name,url,type\n"
                    @"Front Door,rtsp://192.168.1.100:554/stream,rtsp\n"
                    @"Backyard,rtsp://192.168.1.101:554/stream,rtsp\n"
                    @"Garage,rtsp://192.168.1.102:554/stream,rtsp\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 3);
    XCTAssertEqualObjects(cameras[0][@"name"], @"Front Door");
    XCTAssertEqualObjects(cameras[1][@"name"], @"Backyard");
    XCTAssertEqualObjects(cameras[2][@"name"], @"Garage");
}

- (void)testParseCSVWithComments {
    NSString *csv = @"# My cameras\n"
                    @"name,url,type\n"
                    @"# Outdoor cameras\n"
                    @"Front Door,rtsp://192.168.1.100:554/stream,rtsp\n"
                    @"# Indoor cameras\n"
                    @"Living Room,rtsp://192.168.1.200:554/stream,rtsp\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 2);
}

- (void)testParseCSVWithEmptyLines {
    NSString *csv = @"name,url,type\n"
                    @"\n"
                    @"Camera 1,rtsp://192.168.1.100:554/stream,rtsp\n"
                    @"\n"
                    @"\n"
                    @"Camera 2,rtsp://192.168.1.101:554/stream,rtsp\n"
                    @"\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 2);
}

- (void)testParseCSVWithInvalidURLs {
    NSString *csv = @"name,url,type\n"
                    @"Valid Camera,rtsp://192.168.1.100:554/stream,rtsp\n"
                    @"Invalid Camera,not-a-url,rtsp\n"
                    @"Also Invalid,ftp://wrong.protocol.com,rtsp\n"
                    @"Another Valid,rtsps://secure.example.com:7441/stream,rtsp\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 2, @"Should only import cameras with valid RTSP/HTTP URLs");
    XCTAssertEqualObjects(cameras[0][@"name"], @"Valid Camera");
    XCTAssertEqualObjects(cameras[1][@"name"], @"Another Valid");
}

- (void)testParseCSVWithoutHeader {
    NSString *csv = @"Front Door,rtsp://192.168.1.100:554/stream,rtsp\n"
                    @"Backyard,rtsp://192.168.1.101:554/stream,rtsp\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 2, @"Should work without header row");
}

- (void)testParseCSVWithQuotedNames {
    NSString *csv = @"name,url,type\n"
                    @"\"Front Door (Main)\",rtsp://192.168.1.100:554/stream,rtsp\n"
                    @"\"Back, Yard\",rtsp://192.168.1.101:554/stream,rtsp\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 2);
    XCTAssertEqualObjects(cameras[0][@"name"], @"Front Door (Main)");
    XCTAssertEqualObjects(cameras[1][@"name"], @"Back, Yard");
}

- (void)testParseCSVWithHTTPURLs {
    // Some cameras use HTTP streams
    NSString *csv = @"name,url,type\n"
                    @"HTTP Camera,http://192.168.1.100/stream,http\n"
                    @"HTTPS Camera,https://192.168.1.101/stream,https\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 2);
}

- (void)testParseCSVWithCredentialsInURL {
    NSString *csv = @"name,url,type\n"
                    @"Auth Camera,rtsp://admin:password@192.168.1.100:554/stream,rtsp\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 1);

    // URL should preserve credentials for connection purposes
    NSString *url = cameras[0][@"url"];
    NSURL *parsedURL = [NSURL URLWithString:url];
    XCTAssertNotNil(parsedURL);
    XCTAssertEqualObjects(parsedURL.user, @"admin");
}

- (void)testParseEmptyCSV {
    NSArray *cameras = [self parseCamerasFromCSV:@""];
    XCTAssertEqual(cameras.count, 0);
}

- (void)testParseCSVWithOnlyCommentsAndHeader {
    NSString *csv = @"# My cameras\n"
                    @"name,url,type\n"
                    @"# No cameras configured yet\n";

    NSArray *cameras = [self parseCamerasFromCSV:csv];
    XCTAssertEqual(cameras.count, 0);
}

#pragma mark - Stream URL Validation Tests

- (void)testValidStreamURLFormats {
    NSArray *validURLs = @[
        @"rtsp://192.168.1.100:554/stream",
        @"rtsp://camera.local/live",
        @"rtsp://admin:pass@192.168.1.100:554/Streaming/Channels/101",
        @"rtsps://10.0.0.1:7441/stream?enableSrtp",
        @"rtsp://192.168.1.100:554/cam/realmonitor?channel=1&subtype=0",
        @"rtsp://192.168.1.100:554/h264Preview_01_main",
        @"http://192.168.1.100/snapshot.cgi",
        @"https://camera.example.com/hls/stream.m3u8",
    ];

    for (NSString *urlString in validURLs) {
        NSURL *url = [NSURL URLWithString:urlString];
        XCTAssertNotNil(url, @"Should parse valid stream URL: %@", urlString);
        XCTAssertNotNil(url.host, @"Should have a host: %@", urlString);
    }
}

- (void)testStreamURLPathComponents {
    // Hikvision format
    NSURL *hikvision = [NSURL URLWithString:@"rtsp://admin:pass@192.168.1.100:554/Streaming/Channels/101"];
    XCTAssertEqualObjects(hikvision.path, @"/Streaming/Channels/101");

    // Dahua/Amcrest format
    NSURL *dahua = [NSURL URLWithString:@"rtsp://admin:pass@192.168.1.100:554/cam/realmonitor?channel=1&subtype=0"];
    XCTAssertEqualObjects(dahua.path, @"/cam/realmonitor");

    // Reolink format
    NSURL *reolink = [NSURL URLWithString:@"rtsp://admin:pass@192.168.1.100:554/h264Preview_01_main"];
    XCTAssertEqualObjects(reolink.path, @"/h264Preview_01_main");
}

#pragma mark - Stream Cycling Logic Tests

- (void)testFeedCyclingWrapsAround {
    NSArray *feeds = @[@"rtsp://cam1.example.com", @"rtsp://cam2.example.com", @"rtsp://cam3.example.com"];
    NSUInteger currentIndex = 0;

    // Cycle through all feeds
    for (NSUInteger i = 0; i < feeds.count * 2; i++) {
        currentIndex = (currentIndex + 1) % feeds.count;
    }

    // After 6 rotations with 3 feeds, should be back to 0
    XCTAssertEqual(currentIndex, 0, @"Should wrap around to start");
}

- (void)testFeedCyclingWithSingleFeed {
    NSArray *feeds = @[@"rtsp://cam1.example.com"];
    NSUInteger currentIndex = 0;

    currentIndex = (currentIndex + 1) % feeds.count;
    XCTAssertEqual(currentIndex, 0, @"Single feed should always stay at index 0");
}

- (void)testPreviousFeedWrapsAround {
    NSArray *feeds = @[@"rtsp://cam1.example.com", @"rtsp://cam2.example.com", @"rtsp://cam3.example.com"];
    NSUInteger currentIndex = 0;

    // Go to previous from first should wrap to last
    NSUInteger count = feeds.count;
    currentIndex = (currentIndex - 1 + count) % count;
    XCTAssertEqual(currentIndex, 2, @"Previous from 0 should wrap to last feed");
}

#pragma mark - Performance Tests

- (void)testCSVParsingPerformanceWith100Cameras {
    NSMutableString *csv = [NSMutableString stringWithString:@"name,url,type\n"];
    for (int i = 0; i < 100; i++) {
        [csv appendFormat:@"Camera %d,rtsp://192.168.1.%d:554/stream,rtsp\n", i, i % 256];
    }

    [self measureBlock:^{
        NSArray *cameras = [self parseCamerasFromCSV:csv];
        XCTAssertEqual(cameras.count, 100);
    }];
}

- (void)testCSVParsingPerformanceWithQuotedFields {
    NSMutableString *csv = [NSMutableString stringWithString:@"name,url,type\n"];
    for (int i = 0; i < 50; i++) {
        [csv appendFormat:@"\"Camera %d, Location %d\",rtsp://192.168.1.%d:554/stream,rtsp\n", i, i, i % 256];
    }

    [self measureBlock:^{
        NSArray *cameras = [self parseCamerasFromCSV:csv];
        XCTAssertEqual(cameras.count, 50);
    }];
}

@end
