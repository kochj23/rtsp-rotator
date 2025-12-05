# Configuration Export/Import System

## Overview

The Configuration Export/Import system allows you to export all RTSP Rotator settings to a JSON file that can be:
- Stored on a remote URL for centralized configuration management
- Shared across multiple instances (macOS, iOS, tvOS, screensaver)
- Backed up for disaster recovery
- Synchronized automatically between devices

**Version:** 2.1.1
**Added:** October 29, 2025

---

## Features

### ✅ Complete Configuration Export
Exports **all** application settings to a single JSON file:
- Camera feeds with metadata (name, URL, enabled state, category)
- Bookmarks with hotkeys
- API server settings
- Failover configuration
- Monitoring features (audio, motion, smart alerts)
- Transitions and UI preferences
- Cloud storage settings
- Event logging configuration
- Display and OSD settings
- Recording preferences

### ✅ Cross-Platform JSON Format
The JSON format is designed to be compatible with:
- **macOS application** (current)
- **iOS app** (future)
- **tvOS app** (future)
- **macOS screensaver** (future)

### ✅ Multiple Import/Export Methods
- **Local file** - Save/load JSON from local filesystem
- **Remote URL** - Fetch configuration from HTTP(S) URL
- **Upload to URL** - POST/PUT configuration to remote server
- **Auto-sync** - Automatic bidirectional sync with configurable interval

### ✅ Merge or Replace
- **Replace mode** - Complete replacement of existing configuration
- **Merge mode** - Merge new settings with existing (preserves local changes)

---

## Usage

### Programmatic Access

```objc
#import "RTSPConfigurationExporter.h"

// Get shared instance
RTSPConfigurationExporter *exporter = [RTSPConfigurationExporter sharedExporter];
```

### Export to File

```objc
// Export to default location
[exporter exportConfigurationToFile:nil completion:^(BOOL success, NSString *filePath, NSError *error) {
    if (success) {
        NSLog(@"Exported to: %@", filePath);
        // Default: ~/Library/Application Support/RTSP Rotator/config.json
    } else {
        NSLog(@"Export failed: %@", error);
    }
}];

// Export to custom location
NSString *customPath = @"/Users/you/Desktop/my-config.json";
[exporter exportConfigurationToFile:customPath completion:^(BOOL success, NSString *filePath, NSError *error) {
    NSLog(@"Export %@", success ? @"succeeded" : @"failed");
}];
```

### Import from File

```objc
// Import and replace all settings
[exporter importConfigurationFromFile:@"/path/to/config.json"
                                merge:NO
                           completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"Configuration imported successfully");
    }
}];

// Import and merge with existing settings
[exporter importConfigurationFromFile:@"/path/to/config.json"
                                merge:YES
                           completion:^(BOOL success, NSError *error) {
    NSLog(@"Merge %@", success ? @"succeeded" : @"failed");
}];
```

### Import from URL

```objc
NSString *configURL = @"https://example.com/rtsp-config.json";
[exporter importConfigurationFromURL:configURL
                               merge:NO
                          completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"Downloaded and applied configuration from URL");
    } else {
        NSLog(@"Failed to fetch configuration: %@", error);
    }
}];
```

### Upload to URL

```objc
NSString *uploadURL = @"https://example.com/api/config";

// POST method
[exporter uploadConfigurationToURL:uploadURL
                            method:@"POST"
                        completion:^(BOOL success, NSString *url, NSError *error) {
    if (success) {
        NSLog(@"Uploaded configuration to: %@", url);
    }
}];

// PUT method (for RESTful APIs)
[exporter uploadConfigurationToURL:uploadURL
                            method:@"PUT"
                        completion:^(BOOL success, NSString *url, NSError *error) {
    NSLog(@"Upload %@", success ? @"succeeded" : @"failed");
}];
```

### Auto-Sync

```objc
// Configure auto-sync
exporter.autoSyncURL = @"https://example.com/api/rtsp-config";
exporter.autoSyncInterval = 300.0; // 5 minutes
exporter.autoSyncUploadMethod = @"PUT";
exporter.autoSyncEnabled = YES;

// Start auto-sync
[exporter startAutoSync];

// Manual sync trigger
[exporter syncNow:^(BOOL downloadSuccess, BOOL uploadSuccess) {
    NSLog(@"Download: %@, Upload: %@",
          downloadSuccess ? @"✓" : @"✗",
          uploadSuccess ? @"✓" : @"✗");
}];

// Stop auto-sync
[exporter stopAutoSync];
```

---

## JSON Format

### Example Configuration

```json
{
  "version": "2.1",
  "exportDate": "2025-10-29T12:00:00Z",
  "platform": "macOS",
  "basic": {
    "rotationInterval": 60,
    "startMuted": true,
    "autoSkipFailedFeeds": true,
    "retryAttempts": 3
  },
  "display": {
    "displayIndex": 0,
    "gridLayoutEnabled": false,
    "gridRows": 2,
    "gridColumns": 2
  },
  "osd": {
    "enabled": true,
    "duration": 3.0,
    "position": 1
  },
  "recording": {
    "autoSnapshotsEnabled": false,
    "snapshotInterval": 300,
    "snapshotDirectory": "/Users/you/Snapshots"
  },
  "feeds": [
    {
      "url": "rtsp://camera1.local/stream",
      "name": "Front Door",
      "enabled": true,
      "category": "Exterior"
    },
    {
      "url": "rtsp://camera2.local/stream",
      "name": "Backyard",
      "enabled": true,
      "category": "Exterior"
    }
  ],
  "bookmarks": [
    {
      "name": "Main Entrance",
      "feedURL": "rtsp://camera1.local/stream",
      "hotkey": 1,
      "feedIndex": 0
    }
  ],
  "bookmarksEnabled": true,
  "transitions": {
    "type": 1,
    "duration": 0.5
  },
  "api": {
    "enabled": true,
    "port": 8080,
    "requireAPIKey": false
  },
  "failover": {
    "enabled": true,
    "healthCheckInterval": 30,
    "connectionTimeout": 10,
    "maxRetryAttempts": 3
  },
  "monitoring": {
    "audioMonitorEnabled": false,
    "audioMonitorThreshold": 0.8,
    "motionDetectionEnabled": false,
    "motionSensitivity": 0.5,
    "smartAlertsEnabled": false,
    "smartAlertsThreshold": 0.7
  },
  "cloud": {
    "enabled": false,
    "provider": 0,
    "retentionDays": 30
  },
  "eventLogging": {
    "enabled": true,
    "maxEvents": 1000
  },
  "fullScreen": {
    "showControlsOnHover": true,
    "controlsFadeDelay": 3.0
  }
}
```

### Field Reference

#### Metadata
- **version** (string) - Configuration format version
- **exportDate** (string) - ISO8601 timestamp
- **platform** (string) - Source platform (macOS, iOS, tvOS)

#### Basic Settings
- **rotationInterval** (number) - Seconds between feed switches
- **startMuted** (boolean) - Start with audio muted
- **autoSkipFailedFeeds** (boolean) - Skip feeds that fail to connect
- **retryAttempts** (number) - Connection retry count (1-10)

#### Display Settings
- **displayIndex** (number) - Monitor index (0 = main)
- **gridLayoutEnabled** (boolean) - Enable multi-camera grid
- **gridRows** (number) - Grid rows
- **gridColumns** (number) - Grid columns

#### Feeds
Array of feed objects:
- **url** (string) - RTSP URL
- **name** (string) - Display name
- **enabled** (boolean) - Is feed active
- **category** (string, optional) - Category/group name

#### Bookmarks
Array of bookmark objects:
- **name** (string) - Bookmark name
- **feedURL** (string) - Feed URL
- **hotkey** (number) - Keyboard shortcut (1-9, 0=none)
- **feedIndex** (number) - Index in feed list

#### API Settings
- **enabled** (boolean) - API server enabled
- **port** (number) - HTTP port (1024-65535)
- **requireAPIKey** (boolean) - Require authentication
- **apiKey** (string, optional) - API key for authentication

#### Monitoring Settings
- **audioMonitorEnabled** (boolean) - Enable audio monitoring
- **motionDetectionEnabled** (boolean) - Enable motion detection
- **smartAlertsEnabled** (boolean) - Enable AI object detection
- Threshold values (0.0-1.0) for each monitoring type

---

## Server-Side Implementation

### Simple HTTP Server (Python)

```python
from flask import Flask, request, jsonify
import json

app = Flask(__name__)
config_storage = {}

@app.route('/api/config', methods=['GET'])
def get_config():
    """Download configuration"""
    if 'rtsp' in config_storage:
        return jsonify(config_storage['rtsp'])
    return jsonify({"error": "No configuration found"}), 404

@app.route('/api/config', methods=['POST', 'PUT'])
def update_config():
    """Upload configuration"""
    config_storage['rtsp'] = request.json
    return jsonify({"success": True, "message": "Configuration saved"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

### Static File Hosting

The simplest approach is to host the JSON file on any web server:

```bash
# Upload config to web server
scp config.json user@server.com:/var/www/html/rtsp-config.json

# Access from RTSP Rotator
https://server.com/rtsp-config.json
```

### RESTful API (Node.js)

```javascript
const express = require('express');
const fs = require('fs');
const app = express();

app.use(express.json());

const CONFIG_FILE = './rtsp-config.json';

// GET configuration
app.get('/api/config', (req, res) => {
    if (fs.existsSync(CONFIG_FILE)) {
        const config = JSON.parse(fs.readFileSync(CONFIG_FILE));
        res.json(config);
    } else {
        res.status(404).json({ error: 'Configuration not found' });
    }
});

// POST/PUT configuration
app.post('/api/config', (req, res) => {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(req.body, null, 2));
    res.json({ success: true });
});

app.put('/api/config', (req, res) => {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(req.body, null, 2));
    res.json({ success: true });
});

app.listen(8080, () => console.log('Config server running on port 8080'));
```

---

## Use Cases

### 1. Centralized Configuration Management

Deploy RTSP Rotator across multiple Macs with shared configuration:

```objc
// On all machines, configure to sync from central server
exporter.autoSyncURL = @"https://config-server.company.com/rtsp.json";
exporter.autoSyncInterval = 600; // Check every 10 minutes
exporter.autoSyncEnabled = YES;
[exporter startAutoSync];
```

### 2. Disaster Recovery

Backup configuration before major changes:

```objc
// Backup current configuration
NSString *backupPath = [NSString stringWithFormat:@"/Backups/rtsp-config-%@.json",
                        [[NSDate date] description]];
[exporter exportConfigurationToFile:backupPath completion:^(BOOL success, NSString *path, NSError *error) {
    NSLog(@"Backup saved to: %@", path);
}];
```

### 3. Configuration Templates

Create and distribute configuration templates:

```objc
// Import standard company configuration
[exporter importConfigurationFromURL:@"https://company.com/rtsp-template.json"
                               merge:NO
                          completion:^(BOOL success, NSError *error) {
    NSLog(@"Template applied: %@", success ? @"YES" : @"NO");
}];
```

### 4. Cross-Platform Sync

Keep settings synchronized across macOS, iOS, and tvOS:

```objc
// All platforms use same sync URL
exporter.autoSyncURL = @"https://myserver.com/api/rtsp-config";
exporter.autoSyncEnabled = YES;
[exporter startAutoSync];

// Bidirectional sync ensures all devices stay in sync
```

---

## Security Considerations

### API Key Authentication

When uploading sensitive configurations:

```objc
// Configure server-side authentication
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
[request setValue:@"Bearer your-api-token" forHTTPHeaderField:@"Authorization"];
// Or use API key in URL: https://server.com/config?key=secret
```

### HTTPS Only

**Always use HTTPS** for remote configuration to prevent:
- Man-in-the-middle attacks
- Credential exposure
- Configuration tampering

```objc
// ✓ Good
exporter.autoSyncURL = @"https://secure-server.com/config.json";

// ✗ Bad (credentials exposed!)
exporter.autoSyncURL = @"http://insecure-server.com/config.json";
```

### Sensitive Data

The JSON export includes:
- ⚠️ RTSP camera credentials (in URLs)
- ⚠️ API keys
- ⚠️ Cloud storage credentials

**Recommendations:**
- Use HTTPS exclusively
- Implement server-side authentication
- Consider encrypting the JSON before upload
- Use environment-specific URLs (exclude credentials from JSON)

---

## Troubleshooting

### Configuration Not Loading

**Check URL accessibility:**
```bash
curl https://your-server.com/rtsp-config.json
```

**Verify JSON format:**
```bash
cat config.json | python -m json.tool
```

### Auto-Sync Not Working

**Enable debug logging:**
```objc
// Check sync status
NSLog(@"Auto-sync enabled: %@", exporter.autoSyncEnabled ? @"YES" : @"NO");
NSLog(@"Sync URL: %@", exporter.autoSyncURL);
NSLog(@"Sync interval: %.0f seconds", exporter.autoSyncInterval);
```

**Common issues:**
- URL not accessible (firewall, DNS)
- Invalid JSON format on server
- Server returns non-200 status code
- Network connectivity issues

### Merge vs Replace

**Replace mode** (`merge:NO`):
- Completely replaces all settings
- Use for initial setup or complete reconfiguration
- **Warning:** Loses all local customizations

**Merge mode** (`merge:YES`):
- Preserves settings not in imported config
- Updates only specified fields
- Safer for partial updates
- Does not replace feeds or bookmarks (by design)

---

## API Reference

### RTSPConfigurationExporter Class

#### Singleton
```objc
+ (instancetype)sharedExporter;
```

#### Export Methods
```objc
- (void)exportConfigurationToFile:(nullable NSString *)filePath
                       completion:(RTSPConfigurationExportCompletion)completion;

- (NSString *)defaultExportPath;
```

#### Import Methods
```objc
- (void)importConfigurationFromFile:(NSString *)filePath
                              merge:(BOOL)merge
                         completion:(RTSPConfigurationImportCompletion)completion;

- (void)importConfigurationFromURL:(NSString *)urlString
                             merge:(BOOL)merge
                        completion:(RTSPConfigurationImportCompletion)completion;
```

#### Upload Methods
```objc
- (void)uploadConfigurationToURL:(NSString *)urlString
                          method:(NSString *)method
                      completion:(RTSPConfigurationUploadCompletion)completion;
```

#### Auto-Sync Properties
```objc
@property (nonatomic, assign) BOOL autoSyncEnabled;
@property (nonatomic, assign) NSTimeInterval autoSyncInterval; // seconds
@property (nonatomic, strong, nullable) NSString *autoSyncURL;
@property (nonatomic, strong) NSString *autoSyncUploadMethod; // "POST" or "PUT"
```

#### Auto-Sync Methods
```objc
- (void)startAutoSync;
- (void)stopAutoSync;
- (void)syncNow:(nullable void (^)(BOOL downloadSuccess, BOOL uploadSuccess))completion;
```

#### JSON Utilities
```objc
- (NSDictionary *)generateConfigurationDictionary;
- (nullable NSData *)generateConfigurationJSON:(NSError **)error;
- (BOOL)applyConfigurationFromDictionary:(NSDictionary *)dictionary
                                   merge:(BOOL)merge
                                   error:(NSError **)error;
```

---

## Future Enhancements

### Planned Features
- [ ] Encryption support for sensitive configurations
- [ ] Configuration versioning and rollback
- [ ] Partial configuration updates (specific sections only)
- [ ] Configuration diff/comparison tool
- [ ] UI for export/import in preferences window
- [ ] Configuration validation before import
- [ ] Multi-profile support (dev/staging/production)

---

## Version History

### 2.1.1 (October 29, 2025)
- ✅ Initial release of Configuration Export/Import system
- ✅ JSON format design
- ✅ Local file import/export
- ✅ Remote URL import
- ✅ Upload to URL (POST/PUT)
- ✅ Auto-sync with configurable interval
- ✅ Merge vs replace modes
- ✅ Complete settings coverage
- ✅ Cross-platform JSON format

---

**Copyright © 2025 Jordan Koch**
