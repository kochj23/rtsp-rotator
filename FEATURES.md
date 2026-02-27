# RTSP Rotator - Features Documentation

## Version 1.2.0 Features

### Core Features

#### 1. Preferences Window ✅ IMPLEMENTED
A comprehensive preferences interface for configuring all aspects of the application.

**Access:** Menu Bar → RTSP Rotator → Preferences... (⌘,)

**Features:**
- Modern native macOS interface
- Tabbed sections for organization
- Real-time validation
- Persistent storage via NSUserDefaults

---

#### 2. Configuration Sources ✅ IMPLEMENTED

**Manual Entry:**
- Add RTSP URLs directly in the application
- Edit/remove individual feeds
- Reorder feeds in the list
- Immediate application of changes

**Remote URL:**
- Load feeds from remote HTTP/HTTPS URL
- Supports plain text (one URL per line)
- Supports CSV format with quoted strings
- Auto-refresh capability
- Retry on network failures

**Format Support:**
```
# Plain text format (line-delimited)
rtsp://camera1.example.com/stream
rtsp://camera2.example.com/stream

# CSV format (comma-separated)
"rtsp://camera1.example.com/stream","rtsp://camera2.example.com/stream"

# CSV with special characters (quoted)
"rtsp://admin:pass@camera1.example.com/stream","rtsp://user:p@ss,word@camera2.example.com/stream"
```

---

#### 3. Menu Bar Integration ✅ IMPLEMENTED

**Application Menu:**
- About RTSP Rotator
- Preferences... (⌘,)
- Quit RTSP Rotator (⌘Q)

**Controls Menu:**
- Next Feed (⌘N) - Manually advance to next feed
- Toggle Mute (⌘M) - Mute/unmute audio
- Refresh Configuration (⌘R) - Reload feeds from source

---

#### 4. Persistent Configuration ✅ IMPLEMENTED

All settings are automatically saved and restored:
- Configuration source (Manual/Remote URL)
- Remote URL (if configured)
- Manual feed list
- Rotation interval
- Mute state preference
- Auto-skip settings
- Retry attempts

**Storage:** NSUserDefaults (user preferences domain)
**Location:** `~/Library/Preferences/com.jkoch.RTSP-Rotator.plist`

---

### Configuration Options

#### Feed Management

**Manual Feeds:**
- Add new RTSP URLs via dialog
- Edit URLs inline in table
- Remove selected feeds
- Drag to reorder (planned)

**Remote Configuration:**
- HTTP/HTTPS URL support
- CSV parsing with quote escaping
- Comment support (lines starting with #)
- Whitespace trimming
- Error handling and retries

#### Playback Settings

**Rotation Interval:**
- Configurable time between feed switches
- Range: 5-3600 seconds (5s to 1 hour)
- Default: 60 seconds

**Start Muted:**
- Begin playback with audio muted
- Prevents unexpected loud audio
- Default: Yes (muted)

**Auto-skip Failed Feeds:**
- Automatically skip feeds that fail to load
- Continues rotation on error
- Prevents application hanging
- Default: Yes (enabled)

**Retry Attempts:**
- Number of connection retries before skipping
- Range: 0-10 attempts
- Default: 3 attempts

---

### User Interface Features

#### Preferences Window

**Layout:**
```
┌─────────────────────────────────────┐
│ RTSP Rotator Preferences         [X]│
├─────────────────────────────────────┤
│ Configuration Source:               │
│   ○ Manual Entry                    │
│   ○ Remote URL                      │
│                                     │
│ Remote Configuration URL:           │
│ [https://example.com/feeds.txt    ]│
│                                     │
│ Manual Feeds:                       │
│ ┌─────────────────────────┐   [+]  │
│ │ rtsp://camera1/stream   │   [-]  │
│ │ rtsp://camera2/stream   │        │
│ │ rtsp://camera3/stream   │        │
│ └─────────────────────────┘        │
│                                     │
│ Playback Settings:                  │
│   Rotation Interval (seconds): [60]│
│   ☑ Start Muted                     │
│   ☑ Auto-skip Failed Feeds          │
│   Retry Attempts: 3 [▼▲]           │
│                                     │
│              [Cancel]    [Save]     │
└─────────────────────────────────────┘
```

**Behavior:**
- Modal window (focused during editing)
- Validates input before saving
- Cancel button discards changes
- Save button applies and persists
- Automatic reload of feeds after save

---

### Advanced Features

#### Error Handling

**Network Errors:**
- Timeout handling (30 seconds)
- HTTP error code reporting
- User-friendly error messages
- Fallback to cached configuration

**Feed Errors:**
- Invalid URL detection
- Connection failure logging
- Auto-skip if enabled
- Retry with exponential backoff

**UI Errors:**
- Empty feed list warning
- Invalid configuration alert
- Guided setup on first launch

#### Configuration Reload

**Manual Reload:**
- Menu: Controls → Refresh Configuration (⌘R)
- Forces re-fetch from remote URL
- Reloads manual configuration
- Restarts playback with new feeds

**Automatic Reload:**
- After saving preferences
- On configuration change notification
- Seamless transition between feeds

---

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘, | Open Preferences |
| ⌘Q | Quit Application |
| ⌘N | Next Feed |
| ⌘M | Toggle Mute |
| ⌘R | Refresh Configuration |
| Enter | Toggle Mute (console) |

---

### CSV Format Specification

#### Basic CSV
```csv
rtsp://camera1.example.com/stream,rtsp://camera2.example.com/stream
```

#### CSV with Quotes (for special characters)
```csv
"rtsp://admin:password@camera1.example.com/stream","rtsp://user:p@ss,word@camera2.example.com/stream"
```

#### CSV with Escaped Quotes
```csv
"rtsp://camera1.example.com/stream?name=""Office Camera""","rtsp://camera2.example.com/stream"
```

**Parsing Rules:**
1. Commas separate fields
2. Quotes enclose fields containing commas
3. Double quotes (`""`) escape quotes within quoted fields
4. Leading/trailing whitespace is trimmed
5. Empty fields are ignored
6. Lines starting with # are comments

---

### Technical Implementation

#### Architecture

```
RTSPAppDelegate
├── Menu Bar Management
├── Application Lifecycle
└── Configuration Monitoring

RTSPConfigurationManager (Singleton)
├── Configuration Source Management
├── NSUserDefaults Persistence
├── Remote URL Fetching
├── CSV/Text Parsing
└── Feed Validation

RTSPPreferencesController (Singleton)
├── Preferences Window UI
├── NSTableView for Feed List
├── Form Validation
└── User Input Handling

RTSPWallpaperController
├── VLC Player Management
├── Feed Rotation
├── Window Management
└── Error Recovery
```

#### Data Flow

```
Launch
  ↓
Load NSUserDefaults
  ↓
RTSPConfigurationManager.loadFeedsWithCompletion()
  ├─→ Manual: Return cached feeds
  └─→ Remote: Fetch from URL → Parse → Return
       ↓
RTSPWallpaperController.start()
  ↓
Begin Playback
  ↓
User Opens Preferences
  ↓
Edit Configuration
  ↓
Save → NSUserDefaults
  ↓
Post Notification
  ↓
RTSPAppDelegate receives notification
  ↓
Stop current playback
  ↓
Reload configuration
  ↓
Restart playback with new feeds
```

#### Persistence Keys

```objc
RTSPConfigurationSource        // Integer: 0=Manual, 1=Remote
RTSPRemoteConfigurationURL     // String: Remote URL
RTSPManualFeeds                // Array: Manual feed URLs
RTSPRotationInterval           // Double: Seconds
RTSPStartMuted                 // Boolean: Start muted
RTSPAutoSkipFailed             // Boolean: Auto-skip failed feeds
RTSPRetryAttempts              // Integer: Retry count
```

---

### API Reference

#### RTSPConfigurationManager

**Singleton Access:**
```objc
RTSPConfigurationManager *manager = [RTSPConfigurationManager sharedManager];
```

**Load Feeds:**
```objc
[manager loadFeedsWithCompletion:^(NSArray<NSString *> *feeds, NSError *error) {
    if (feeds) {
        // Use feeds
    } else {
        // Handle error
    }
}];
```

**Add Manual Feed:**
```objc
[manager addManualFeed:@"rtsp://camera.local/stream"];
```

**Refresh Remote:**
```objc
[manager refreshRemoteConfiguration:^(BOOL success, NSError *error) {
    // Handle result
}];
```

**Save Configuration:**
```objc
[manager save];
```

#### RTSPPreferencesController

**Show Preferences:**
```objc
[[RTSPPreferencesController sharedController] showWindow:nil];
```

**Programmatic Configuration:**
```objc
RTSPConfigurationManager *config = [RTSPConfigurationManager sharedManager];
config.configurationSource = RTSPConfigurationSourceRemoteURL;
config.remoteConfigurationURL = @"https://example.com/feeds.txt";
config.rotationInterval = 30.0;
[config save];
```

---

### Usage Examples

#### Example 1: Manual Configuration

1. Launch RTSP Rotator
2. If no feeds configured, preferences opens automatically
3. Select "Manual Entry" radio button
4. Click "+" button
5. Enter RTSP URL: `rtsp://192.168.1.100:554/stream`
6. Click "Add"
7. Repeat for additional feeds
8. Set rotation interval: 60 seconds
9. Check "Start Muted" if desired
10. Click "Save"

Result: Feeds rotate every 60 seconds

#### Example 2: Remote Configuration

1. Open Preferences (⌘,)
2. Select "Remote URL" radio button
3. Enter URL: `https://example.com/camera-feeds.txt`
4. Click "Save"

Result: Feeds loaded from remote URL and rotated

#### Example 3: CSV Remote Configuration

**Remote File** (`camera-feeds.csv`):
```csv
"rtsp://admin:password@camera1.local/stream","rtsp://admin:password@camera2.local/stream","rtsp://admin:password@camera3.local/stream"
```

**Configuration:**
1. Open Preferences
2. Select "Remote URL"
3. Enter: `https://example.com/camera-feeds.csv`
4. Save

Result: Three cameras loaded and rotated

#### Example 4: Keyboard Control

**While Running:**
- Press ⌘N to skip to next camera
- Press ⌘M to toggle audio
- Press ⌘R to reload configuration
- Press Enter (in terminal) to toggle mute

---

### Troubleshooting

#### Preferences Won't Save

**Symptom:** Changes don't persist after restart

**Solutions:**
1. Check file permissions:
   ```bash
   ls -l ~/Library/Preferences/com.jkoch.RTSP-Rotator.plist
   ```
2. Reset preferences:
   ```bash
   defaults delete com.jkoch.RTSP-Rotator
   ```
3. Check Console.app for errors

#### Remote URL Not Loading

**Symptom:** Feeds don't load from remote URL

**Solutions:**
1. Test URL in browser
2. Check network connectivity
3. Verify URL returns plain text or CSV
4. Check for HTTP errors in logs
5. Try with `http://` instead of `https://` for testing

#### Feeds Not Appearing in Preferences

**Symptom:** Manual feeds list is empty

**Solutions:**
1. Check that feeds were saved (click Save button)
2. Verify feeds in NSUserDefaults:
   ```bash
   defaults read com.jkoch.RTSP-Rotator RTSPManualFeeds
   ```
3. Reset and re-add feeds

---

### Future Enhancements

#### Planned for v1.3.0:
- [ ] Drag & drop reordering in feed list
- [ ] Feed categories/groups
- [ ] Custom names for feeds (alias)
- [ ] Test feed button (verify before saving)
- [ ] Import/Export feed lists
- [ ] Feed health indicators in UI

#### Planned for v1.4.0:
- [ ] Grid layout (multiple simultaneous feeds)
- [ ] Multi-monitor support
- [ ] Feed scheduling (time-based rotation)
- [ ] Recording and snapshots
- [ ] OSD (on-screen display) with feed info

#### Planned for v2.0.0:
- [ ] Swift rewrite
- [ ] SwiftUI preferences
- [ ] CloudKit sync
- [ ] iOS companion app
- [ ] HomeKit integration

---

### Migration Guide

#### From v1.1.0 to v1.2.0

**Breaking Changes:**
- File-based configuration (`~/rtsp_feeds.txt`) is deprecated
- Use Manual Entry in Preferences instead

**Migration Steps:**

1. **Automatic Import:**
   - First launch detects `~/rtsp_feeds.txt`
   - Automatically imports to Manual Feeds
   - File can be deleted after import

2. **Manual Import:**
   ```bash
   # View current file
   cat ~/rtsp_feeds.txt

   # Open Preferences and add each URL manually
   # Or use remote URL pointing to the file
   ```

3. **Remote URL Migration:**
   - Upload `rtsp_feeds.txt` to web server
   - Configure Remote URL in Preferences
   - Delete local file

**Backward Compatibility:**
- Old configuration file still works
- Will be used if no new configuration exists
- Recommended to migrate to new system

---

### Security Considerations

**Credentials in URLs:**
- RTSP URLs may contain passwords
- Stored in NSUserDefaults (not encrypted)
- Consider using network-level authentication instead

**Recommendations:**
- Use dedicated camera accounts with limited permissions
- Restrict RTSP access by IP address
- Use VPN for remote camera access
- Consider removing credentials from URLs
- Use RTSPS (RTSP over TLS) when available

**Remote Configuration Security:**
- Use HTTPS for remote URLs
- Verify SSL certificates
- Restrict access to configuration files
- Audit who can modify remote configuration

---

## Summary

RTSP Rotator v1.2.0 provides a complete configuration management system with:

✅ Graphical preferences interface
✅ Manual and remote configuration sources
✅ Persistent settings across launches
✅ CSV and plain text format support
✅ Menu bar integration
✅ Keyboard shortcuts
✅ Error handling and recovery
✅ Auto-reload capability

The application is now production-ready for enterprise deployments with centralized configuration management.
