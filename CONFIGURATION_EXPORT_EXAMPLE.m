//
//  Configuration Export/Import Example
//  RTSP Rotator v2.1.1
//
//  Examples demonstrating configuration export, import, upload, and auto-sync features
//

#import "RTSPConfigurationExporter.h"

#pragma mark - Example 1: Export Configuration to File

void example1_exportToFile() {
    NSLog(@"=== Example 1: Export Configuration ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Export to default location
    [exporter exportConfigurationToFile:nil
                             completion:^(BOOL success, NSString *filePath, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration exported successfully");
            NSLog(@"  Location: %@", filePath);
            // Default: ~/Library/Application Support/RTSP Rotator/config.json
        } else {
            NSLog(@"✗ Export failed: %@", error.localizedDescription);
        }
    }];

    // Export to custom location
    NSString *customPath = @"/Users/you/Desktop/my-rtsp-config.json";
    [exporter exportConfigurationToFile:customPath
                             completion:^(BOOL success, NSString *filePath, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration exported to: %@", filePath);
        }
    }];
}

#pragma mark - Example 2: Import Configuration from File

void example2_importFromFile() {
    NSLog(@"=== Example 2: Import Configuration from File ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Import and REPLACE all settings
    NSString *configPath = @"/path/to/config.json";
    [exporter importConfigurationFromFile:configPath
                                    merge:NO  // Replace mode
                               completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration imported and applied (replace mode)");
            NSLog(@"  All existing settings have been replaced");
        } else {
            NSLog(@"✗ Import failed: %@", error.localizedDescription);
        }
    }];

    // Import and MERGE with existing settings
    [exporter importConfigurationFromFile:configPath
                                    merge:YES  // Merge mode
                               completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration imported and merged");
            NSLog(@"  Existing settings preserved where not overridden");
        } else {
            NSLog(@"✗ Import failed: %@", error.localizedDescription);
        }
    }];
}

#pragma mark - Example 3: Import from Remote URL

void example3_importFromURL() {
    NSLog(@"=== Example 3: Import Configuration from URL ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Download and apply configuration from remote server
    NSString *configURL = @"https://config-server.company.com/rtsp-config.json";

    [exporter importConfigurationFromURL:configURL
                                   merge:NO  // Replace all settings
                              completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration downloaded and applied from URL");
            NSLog(@"  URL: %@", configURL);
        } else {
            NSLog(@"✗ Failed to fetch configuration: %@", error.localizedDescription);
            NSLog(@"  Check network connectivity and URL accessibility");
        }
    }];
}

#pragma mark - Example 4: Upload Configuration to Server

void example4_uploadToServer() {
    NSLog(@"=== Example 4: Upload Configuration to Server ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    NSString *uploadURL = @"https://api.company.com/rtsp-config";

    // Upload using POST method
    [exporter uploadConfigurationToURL:uploadURL
                                method:@"POST"
                            completion:^(BOOL success, NSString *url, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration uploaded successfully");
            NSLog(@"  Method: POST");
            NSLog(@"  URL: %@", url);
        } else {
            NSLog(@"✗ Upload failed: %@", error.localizedDescription);
        }
    }];

    // Upload using PUT method (for RESTful APIs)
    NSString *putURL = @"https://api.company.com/rtsp-config/device-123";
    [exporter uploadConfigurationToURL:putURL
                                method:@"PUT"
                            completion:^(BOOL success, NSString *url, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration updated on server");
            NSLog(@"  Method: PUT");
            NSLog(@"  URL: %@", url);
        }
    }];
}

#pragma mark - Example 5: Auto-Sync Configuration

void example5_autoSync() {
    NSLog(@"=== Example 5: Auto-Sync Configuration ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Configure auto-sync
    exporter.autoSyncURL = @"https://config-server.company.com/api/rtsp-config";
    exporter.autoSyncInterval = 300.0;  // 5 minutes
    exporter.autoSyncUploadMethod = @"POST";
    exporter.autoSyncEnabled = YES;

    // Start auto-sync
    [exporter startAutoSync];
    NSLog(@"✓ Auto-sync started");
    NSLog(@"  URL: %@", exporter.autoSyncURL);
    NSLog(@"  Interval: %.0f seconds", exporter.autoSyncInterval);
    NSLog(@"  Method: %@", exporter.autoSyncUploadMethod);
    NSLog(@"  Auto-sync will:");
    NSLog(@"    1. Download latest configuration from URL");
    NSLog(@"    2. Merge with local configuration");
    NSLog(@"    3. Upload current configuration to URL");
    NSLog(@"    4. Repeat every %.0f seconds", exporter.autoSyncInterval);

    // Manual sync trigger (force sync now)
    [exporter syncNow:^(BOOL downloadSuccess, BOOL uploadSuccess) {
        NSLog(@"Manual sync completed:");
        NSLog(@"  Download: %@", downloadSuccess ? @"✓" : @"✗");
        NSLog(@"  Upload: %@", uploadSuccess ? @"✓" : @"✗");
    }];

    // Stop auto-sync when needed
    // [exporter stopAutoSync];
}

#pragma mark - Example 6: Centralized Fleet Management

void example6_fleetManagement() {
    NSLog(@"=== Example 6: Centralized Fleet Management ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Configure all machines in the fleet to sync from central server
    exporter.autoSyncURL = @"https://fleet-manager.company.com/rtsp-config";
    exporter.autoSyncInterval = 600.0;  // Check every 10 minutes
    exporter.autoSyncUploadMethod = @"POST";
    exporter.autoSyncEnabled = YES;
    [exporter startAutoSync];

    NSLog(@"✓ Fleet management configured");
    NSLog(@"  All machines will sync from: %@", exporter.autoSyncURL);
    NSLog(@"  Configuration updates propagate automatically");
    NSLog(@"  Sync interval: %.0f seconds (10 minutes)", exporter.autoSyncInterval);
}

#pragma mark - Example 7: Disaster Recovery

void example7_disasterRecovery() {
    NSLog(@"=== Example 7: Disaster Recovery ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Step 1: Backup configuration before making changes
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *backupPath = [NSString stringWithFormat:@"/Backups/rtsp-config-%@.json", timestamp];

    [exporter exportConfigurationToFile:backupPath
                             completion:^(BOOL success, NSString *filePath, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration backed up to: %@", filePath);
            NSLog(@"  Safe to proceed with changes");
        } else {
            NSLog(@"✗ Backup failed - DO NOT PROCEED with changes");
        }
    }];

    // Step 2: Make changes...
    // (User makes configuration changes)

    // Step 3: If something goes wrong, restore from backup
    [exporter importConfigurationFromFile:backupPath
                                    merge:NO  // Complete restore
                               completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✓ Configuration restored from backup");
        }
    }];
}

#pragma mark - Example 8: Configuration Templates

void example8_configurationTemplates() {
    NSLog(@"=== Example 8: Configuration Templates ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Company-wide standard configuration
    NSString *companyTemplate = @"https://company.com/templates/rtsp-standard.json";

    [exporter importConfigurationFromURL:companyTemplate
                                   merge:NO
                              completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✓ Company standard configuration applied");
            NSLog(@"  All machines now use consistent settings");
        }
    }];

    // Department-specific configuration
    NSString *deptTemplate = @"https://company.com/templates/rtsp-security-dept.json";

    [exporter importConfigurationFromURL:deptTemplate
                                   merge:YES  // Merge with company standard
                              completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✓ Department-specific settings applied");
            NSLog(@"  Company standard + department customizations");
        }
    }];
}

#pragma mark - Example 9: Cross-Platform Sync

void example9_crossPlatformSync() {
    NSLog(@"=== Example 9: Cross-Platform Sync ===");

    // Configuration for macOS app
    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];
    exporter.autoSyncURL = @"https://myserver.com/api/config/user123";
    exporter.autoSyncInterval = 300.0;
    exporter.autoSyncEnabled = YES;
    [exporter startAutoSync];

    NSLog(@"✓ macOS app configured for cross-platform sync");
    NSLog(@"  Sync URL: %@", exporter.autoSyncURL);
    NSLog(@"  This URL should be used by:");
    NSLog(@"    - macOS application");
    NSLog(@"    - iOS app (future)");
    NSLog(@"    - tvOS app (future)");
    NSLog(@"    - macOS screensaver (future)");
    NSLog(@"  All platforms will stay synchronized automatically");
}

#pragma mark - Example 10: JSON Generation

void example10_jsonGeneration() {
    NSLog(@"=== Example 10: Direct JSON Generation ===");

    RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];

    // Generate configuration dictionary
    NSDictionary *config = [exporter generateConfigurationDictionary];
    NSLog(@"✓ Configuration dictionary generated");
    NSLog(@"  Top-level keys: %@", [config allKeys]);
    NSLog(@"  Version: %@", config[@"version"]);
    NSLog(@"  Platform: %@", config[@"platform"]);
    NSLog(@"  Export date: %@", config[@"exportDate"]);

    // Generate JSON data
    NSError *error = nil;
    NSData *jsonData = [exporter generateConfigurationJSON:&error];
    if (jsonData) {
        NSLog(@"✓ JSON data generated");
        NSLog(@"  Size: %lu bytes", (unsigned long)jsonData.length);

        // Write to custom location
        NSString *customPath = @"/tmp/my-config.json";
        [jsonData writeToFile:customPath atomically:YES];
        NSLog(@"  Written to: %@", customPath);
    } else {
        NSLog(@"✗ JSON generation failed: %@", error.localizedDescription);
    }

    // Parse and apply dictionary
    [exporter applyConfigurationFromDictionary:config
                                        merge:YES
                                        error:&error];
    if (!error) {
        NSLog(@"✓ Configuration applied from dictionary");
    }
}

#pragma mark - Main Example Runner

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"\n");
        NSLog(@"==============================================");
        NSLog(@"  RTSP Rotator Configuration Export Examples");
        NSLog(@"  Version 2.1.1");
        NSLog(@"==============================================\n");

        // Run examples
        example1_exportToFile();
        NSLog(@"\n");

        example2_importFromFile();
        NSLog(@"\n");

        example3_importFromURL();
        NSLog(@"\n");

        example4_uploadToServer();
        NSLog(@"\n");

        example5_autoSync();
        NSLog(@"\n");

        example6_fleetManagement();
        NSLog(@"\n");

        example7_disasterRecovery();
        NSLog(@"\n");

        example8_configurationTemplates();
        NSLog(@"\n");

        example9_crossPlatformSync();
        NSLog(@"\n");

        example10_jsonGeneration();
        NSLog(@"\n");

        NSLog(@"==============================================");
        NSLog(@"  All Examples Completed");
        NSLog(@"==============================================\n");
    }
    return 0;
}
