# UniFi Protect Integration

RTSP Rotator now includes comprehensive integration with the UniFi Protect ecosystem, making it easy to automatically discover and import all your UniFi cameras.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Camera Import](#camera-import)
- [Health Monitoring](#health-monitoring)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)
- [FAQ](#faq)

## Overview

The UniFi Protect integration allows you to:

- **Automatically discover** all cameras on your UniFi Protect controller
- **Bulk import** cameras with a single click
- **Health monitoring** with real-time connection status indicators
- **Seamless RTSP streaming** with optimized URL generation
- **Configuration sync** across all your devices

All UniFi cameras are discovered via the UniFi Protect controller API and automatically configured with the correct RTSP URLs, authentication, and settings.

## Features

### 🔍 Automatic Camera Discovery

Connect to your UniFi Protect controller and RTSP Rotator will automatically discover all cameras on your network. No need to manually enter RTSP URLs or IP addresses.

### 📋 Bulk Import

Import all discovered cameras at once, or select specific cameras to add to your rotation. Cameras are automatically added to your feed list with proper naming and configuration.

### 🚦 Health Monitoring

Each camera shows its online/offline status in real-time. Test camera connections before importing to ensure they're accessible.

### 🔐 Secure Authentication

Supports both HTTPS and HTTP connections to your UniFi Protect controller. Self-signed certificates are supported (SSL verification can be disabled).

### 🎥 Stream Quality Selection

UniFi cameras support multiple stream qualities:
- **High quality** (main stream) - Full resolution
- **Low quality** (sub stream) - Reduced resolution for lower bandwidth

### 📊 Camera Information

View detailed information about each camera:
- Camera name and model
- IP address
- Connection status (online/offline)
- Firmware version
- MAC address

## Requirements

### UniFi Protect Controller

- UniFi Protect application (console, Dream Machine, Cloud Key, or UnVR)
- UniFi Protect version 1.20.0 or later
- Controller must be accessible from your Mac

### Network

- Network connectivity between your Mac and UniFi Protect controller
- Network connectivity between your Mac and UniFi cameras
- Port 443 (HTTPS) or 80 (HTTP) open on controller
- Port 7447 (RTSP) open on cameras

### Credentials

- UniFi Protect username and password
- User must have camera viewing permissions

## Quick Start

### 1. Open UniFi Protect Configuration

Access the UniFi Protect configuration window from:

- **Status Menu** → "UniFi Protect..."
- **Main Menu** → "Window" → "UniFi Protect"

### 2. Enter Controller Settings

Fill in your UniFi Protect controller information:

```
Host:        protect.local  (or IP address like 192.168.1.1)
Port:        443           (default for HTTPS)
Username:    your-username
Password:    your-password
Use HTTPS:   ☑ Checked    (recommended)
Verify SSL:  ☐ Unchecked  (for self-signed certificates)
```

### 3. Connect and Discover

Click **"Connect & Discover Cameras"**

RTSP Rotator will:
1. Authenticate with your UniFi Protect controller
2. Discover all cameras
3. Generate RTSP URLs for each camera
4. Display camera list with status

### 4. Import Cameras

Choose your import method:

- **Import Selected** - Import only selected cameras
- **Import All** - Import all discovered cameras

Imported cameras are added to your manual feeds list and ready to use immediately.

## Configuration

### Controller Settings

#### Host
The hostname or IP address of your UniFi Protect controller.

**Examples:**
- `protect.local` - Local mDNS hostname
- `192.168.1.1` - Direct IP address
- `unifi.example.com` - Remote DNS hostname

#### Port
The port number for your UniFi Protect controller.

**Default values:**
- `443` - HTTPS (recommended)
- `80` - HTTP (not recommended)

#### Username & Password
Your UniFi Protect user credentials.

**Notes:**
- User must have camera viewing permissions
- Local user accounts are recommended
- SSO accounts are not currently supported

#### Use HTTPS
Enable HTTPS for secure communication with the controller.

**Recommended:** Always enabled

**When to disable:**
- Controller only supports HTTP
- Testing/debugging connection issues

#### Verify SSL Certificate
Enable SSL certificate verification for HTTPS connections.

**Recommended:** Disabled for self-signed certificates

**When to enable:**
- Controller has valid SSL certificate from trusted CA
- Enhanced security required

### Connection Settings

Settings are automatically saved when you connect. They persist across application restarts and are stored in NSUserDefaults.

**Security Note:** Passwords are currently stored in NSUserDefaults. For production use, consider migrating to macOS Keychain.

## Camera Import

### Import Process

When you import cameras, RTSP Rotator:

1. **Generates RTSP URLs** - Creates properly formatted RTSP URLs with authentication
2. **Adds to feed list** - Adds cameras to your manual feeds configuration
3. **Names cameras** - Uses UniFi camera names (e.g., "Front Door (UVC-G4-PRO)")
4. **Sets category** - Tags cameras as "UniFi Protect" for organization
5. **Enables feeds** - Only online cameras are enabled by default

### RTSP URL Format

UniFi Protect cameras use this RTSP URL format:

```
rtsp://username:password@camera-ip:7447/channel
```

**Channel numbers:**
- `0` - High quality (main stream)
- `1` - Medium quality
- `2` - Low quality (sub stream)

**Example:**
```
rtsp://user:pass@192.168.1.100:7447/0
```

### Duplicate Detection

RTSP Rotator automatically detects if a camera has already been imported:

- Checks existing feeds for matching RTSP URLs
- Skips cameras that are already in your feed list
- Reports number of newly imported cameras

### Manual Configuration

After import, cameras appear in your manual feeds list where you can:

- Reorder cameras
- Enable/disable individual cameras
- Edit camera names
- Remove cameras
- Test connections

## Health Monitoring

### Connection Status

Each camera displays its current status:

🟢 **Online** - Camera is connected to UniFi Protect and accessible

🔴 **Offline** - Camera is disconnected or not accessible

### Testing Connections

Use the **"Test Selected"** button to verify camera connectivity:

1. Select cameras to test
2. Click "Test Selected"
3. RTSP Rotator tests TCP connection to RTSP port (7447)
4. Results show number of reachable cameras

**What's tested:**
- Network connectivity to camera IP
- RTSP port (7447) is accessible
- Connection latency

**What's NOT tested:**
- RTSP stream quality
- Authentication validity
- Actual video playback

### Status Indicators

The preferences window shows:

- **Connection status** - Connected/Disconnected from controller
- **Discovery status** - Number of cameras found
- **Import status** - Number of cameras imported
- **Test results** - Number of cameras reachable

### Health Colors

Following the app's color scheme:

- 🟢 **Green** - Healthy, connected, online
- 🟡 **Yellow** - Warning, partial connectivity
- 🔴 **Red** - Error, offline, failed
- ⚪ **Gray** - Unknown, not tested

## Troubleshooting

### Connection Issues

#### "Connection failed: Invalid URL"
**Problem:** Controller host or port is incorrect

**Solutions:**
- Verify host can be reached with `ping protect.local`
- Try IP address instead of hostname
- Verify port (443 for HTTPS, 80 for HTTP)
- Check HTTPS/HTTP setting matches controller

#### "Connection failed: HTTP 401"
**Problem:** Authentication failed

**Solutions:**
- Verify username and password are correct
- Ensure user has camera viewing permissions
- Try local user account instead of SSO
- Check if account is locked or disabled

#### "Connection failed: HTTP 403"
**Problem:** User doesn't have sufficient permissions

**Solutions:**
- Grant camera viewing permissions to user
- Use administrator account
- Check UniFi Protect user roles and permissions

#### "Connection failed: Connection timeout"
**Problem:** Cannot reach controller

**Solutions:**
- Verify network connectivity
- Check firewall rules
- Ensure controller is powered on
- Try disabling VPN if active
- Check if port forwarding is required

### Discovery Issues

#### "Discovered 0 cameras"
**Problem:** No cameras found

**Solutions:**
- Verify cameras are adopted in UniFi Protect
- Check cameras show in UniFi Protect app
- Ensure cameras are on same network
- Try refreshing camera list
- Check UniFi Protect version compatibility

#### "Discovery failed: HTTP 404"
**Problem:** Camera API endpoint not found

**Solutions:**
- Update UniFi Protect to latest version
- Verify controller supports API access
- Check if using correct API endpoint

### Import Issues

#### "No new cameras to import"
**Problem:** All cameras already imported

**Solution:** This is normal - cameras are only imported once

#### "Import failed: Camera has no RTSP URL"
**Problem:** Camera doesn't have IP address or RTSP disabled

**Solutions:**
- Check camera has valid IP address in UniFi Protect
- Verify RTSP is enabled on camera
- Try power cycling camera
- Check camera firmware is up to date

### Streaming Issues

#### Camera appears in list but won't play
**Problem:** RTSP stream not accessible

**Solutions:**
- Test camera connection in UniFi Protect preferences
- Verify port 7447 is accessible from your Mac
- Check camera is actually online (not just showing as online)
- Try lower quality stream (channel 2 instead of 0)
- Verify username/password haven't changed
- Check if camera requires different credentials than controller

#### Stream is choppy or buffering
**Problem:** Network bandwidth or performance issue

**Solutions:**
- Use low quality stream (channel 2)
- Reduce rotation interval
- Check network bandwidth
- Verify Wi-Fi signal strength to cameras
- Consider wired connection for cameras

### SSL Certificate Issues

#### "Connection failed: SSL error"
**Problem:** SSL certificate verification failed

**Solutions:**
- Disable "Verify SSL Certificate" option
- Install UniFi certificate as trusted on Mac
- Use HTTP instead of HTTPS (not recommended)

## Technical Details

### Architecture

The UniFi Protect integration consists of:

**RTSPUniFiProtectAdapter** - Core adapter class
- Handles authentication with UniFi Protect API
- Discovers cameras via REST API
- Generates RTSP URLs
- Manages camera state

**RTSPUniFiCamera** - Camera model class
- Represents individual UniFi camera
- Stores camera metadata (name, model, IP, etc.)
- Supports NSCoding for persistence

**RTSPUniFiProtectPreferences** - UI controller
- Provides graphical interface for configuration
- Displays camera list and status
- Handles import workflow

### API Endpoints

The adapter uses these UniFi Protect API endpoints:

**Authentication:**
```
POST /api/auth/login
{
  "username": "...",
  "password": "...",
  "rememberMe": true
}
```

**Camera Discovery:**
```
GET /proxy/protect/api/cameras
```

**Camera Details:**
```
GET /proxy/protect/api/cameras/{id}
```

**Logout:**
```
POST /api/auth/logout
```

### Authentication

**Method:** Cookie-based session authentication

**Flow:**
1. POST credentials to `/api/auth/login`
2. Server returns `Set-Cookie` header
3. Include cookie in subsequent requests
4. Session persists until logout or timeout

**Security:**
- Credentials not stored in requests after login
- Session cookie used for authentication
- HTTPS recommended for encrypted transport

### RTSP URL Generation

**Format:**
```
rtsp://username:password@camera-ip:port/channel
```

**Components:**
- `username` - UniFi Protect username (usually same as controller login)
- `password` - UniFi Protect password
- `camera-ip` - Camera's IP address from UniFi Protect
- `port` - Always 7447 for UniFi cameras
- `channel` - 0 (high), 1 (medium), or 2 (low)

**Example URLs:**
```
rtsp://admin:password@192.168.1.100:7447/0  (high quality)
rtsp://admin:password@192.168.1.100:7447/2  (low quality)
```

### Data Model

**RTSPUniFiCamera properties:**
```objc
@property NSString *cameraId;           // Unique ID from UniFi
@property NSString *name;               // Display name
@property NSString *model;              // Camera model (e.g., UVC-G4-PRO)
@property NSString *macAddress;         // MAC address
@property NSString *ipAddress;          // IP address
@property NSString *firmwareVersion;    // Firmware version
@property BOOL isOnline;                // Connection status
@property BOOL supportsRTSP;            // RTSP support (always YES)
@property NSInteger rtspPort;           // RTSP port (always 7447)
@property NSInteger rtspChannel;        // Stream channel (0-2)
@property NSString *rtspURL;            // Generated RTSP URL
@property NSString *cameraType;         // Camera type
@property NSDate *lastSeen;             // Last update time
@property NSDictionary *rawData;        // Raw JSON from API
```

### Configuration Storage

**Location:** NSUserDefaults

**Keys:**
- `UniFi_ControllerHost` - Controller hostname/IP
- `UniFi_ControllerPort` - Controller port
- `UniFi_Username` - UniFi username
- `UniFi_Password` - UniFi password (⚠️ consider Keychain)
- `UniFi_UseHTTPS` - HTTPS enabled flag
- `UniFi_VerifySSL` - SSL verification flag

### Network Requirements

**Outbound connections required:**
- Controller: Port 443/80 (HTTPS/HTTP)
- Cameras: Port 7447 (RTSP)

**Protocols used:**
- HTTPS/HTTP - Controller API communication
- RTSP - Video streaming from cameras

**Firewall considerations:**
- Allow outbound TCP to controller port
- Allow outbound TCP to port 7447 on camera IPs
- Ensure no network ACLs block camera subnet

## FAQ

### General Questions

**Q: Do I need UniFi Protect to use RTSP Rotator?**
A: No, but the UniFi integration makes it much easier if you have UniFi cameras. You can still use RTSP Rotator with any RTSP camera by manually entering URLs.

**Q: Can I use this with UniFi Video (legacy)?**
A: No, this integration is specifically for UniFi Protect. UniFi Video uses different APIs and RTSP URL formats.

**Q: Does this work with non-UniFi cameras?**
A: Yes! The UniFi integration is optional. You can still add any RTSP camera manually using the regular preferences.

**Q: Can I mix UniFi and non-UniFi cameras?**
A: Absolutely! Import UniFi cameras automatically, then add any other RTSP cameras manually.

### Setup Questions

**Q: What UniFi Protect versions are supported?**
A: UniFi Protect 1.20.0 and later. Tested with versions 1.20.x through 3.x.

**Q: Do I need to enable RTSP on my cameras?**
A: No, UniFi cameras have RTSP enabled by default on port 7447.

**Q: Can I use a read-only user account?**
A: Yes, as long as the user has camera viewing permissions. Full administrator access is not required.

**Q: Does this work with UniFi Protect running on a UDM-Pro/Cloud Key/Console?**
A: Yes, it works with all UniFi Protect hosting options: Dream Machines, Cloud Keys, Consoles, and UNVR devices.

### Security Questions

**Q: Is my password stored securely?**
A: Currently passwords are stored in NSUserDefaults. We recommend only using this on secure, single-user Macs. Future versions may use macOS Keychain.

**Q: Should I use HTTPS or HTTP?**
A: Always use HTTPS unless your controller doesn't support it. HTTPS encrypts your credentials during authentication.

**Q: Should I verify SSL certificates?**
A: Only if your controller has a valid certificate from a trusted CA. Most self-hosted controllers use self-signed certificates and require verification disabled.

**Q: Are my cameras exposed to the internet?**
A: No, RTSP Rotator only accesses cameras on your local network. No external connections are made.

### Technical Questions

**Q: Can I see the RTSP URLs that were generated?**
A: Yes, imported cameras appear in your manual feeds list with their full RTSP URLs.

**Q: Can I edit the RTSP URL after import?**
A: Yes, you can edit any feed URL in the main preferences, including those imported from UniFi Protect.

**Q: Why is the status showing "Online" but the camera won't play?**
A: The online status comes from UniFi Protect's controller. The camera may be connected to the controller but not accessible from your Mac due to network issues.

**Q: Can I import the same camera multiple times with different quality settings?**
A: Yes! Import once, then duplicate the feed in preferences and manually change the channel number (0 to 2) in the RTSP URL.

**Q: Does this require port forwarding?**
A: No, as long as your Mac and UniFi Protect controller are on the same network (or connected via VPN).

**Q: Can I use this remotely over VPN?**
A: Yes, if your VPN provides access to your UniFi network and controller.

**Q: What data does this send to Anthropic/external servers?**
A: None. All communication is between your Mac and your local UniFi Protect controller. RTSP Rotator does not send any data to external servers.

### Troubleshooting Questions

**Q: Why don't I see any cameras after connecting?**
A: Ensure your cameras are adopted and showing in the UniFi Protect app. Unadopted cameras won't appear in the API.

**Q: The connection test passes but streams won't play, why?**
A: The connection test only checks if the RTSP port is reachable. Stream playback can fail due to authentication, codec issues, or bandwidth problems.

**Q: Can I test without importing cameras?**
A: Yes, use the "Test Selected" button before importing to verify cameras are reachable.

**Q: How do I remove imported cameras?**
A: Go to the main Preferences window, select the camera feeds, and remove them like any other manual feed.

**Q: Does refreshing import cameras again?**
A: No, refreshing only updates the discovered camera list. You must explicitly import cameras using the import buttons.

### Feature Questions

**Q: Can this automatically update if I add new cameras to UniFi Protect?**
A: Not automatically, but you can click "Refresh" in the UniFi Protect preferences to discover newly added cameras, then import them.

**Q: Can I automate the import process?**
A: Not currently. Import must be done manually through the UI. Future versions may support scripting or command-line import.

**Q: Does this work with the iOS/tvOS versions of RTSP Rotator?**
A: The UniFi Protect import feature is currently macOS-only. However, you can export your configuration (including imported cameras) and use it on other platforms.

## Support

For issues, questions, or feature requests related to UniFi Protect integration:

1. Check this documentation and FAQ
2. Review the [Troubleshooting](#troubleshooting) section
3. Check the main [README](../README.md) for general RTSP Rotator help
4. Verify you meet all [Requirements](#requirements)

### Reporting Issues

When reporting issues, please include:

- UniFi Protect version
- Controller hardware (UDM, Cloud Key, Console, etc.)
- Number of cameras
- Camera models
- Connection settings used (host, port, HTTPS/HTTP)
- Any error messages displayed
- Console output (if available)

### Logs

Relevant log messages are prefixed with `[UniFi]` in the Console app.

To view logs:
1. Open **Console.app**
2. Select your Mac in the sidebar
3. Search for "UniFi" or "RTSP Rotator"
4. Filter by process: "RTSP Rotator"

## Version History

### Version 2.2.0 (Current)
- ✅ Initial UniFi Protect integration
- ✅ Automatic camera discovery
- ✅ Bulk import functionality
- ✅ Connection testing
- ✅ Health monitoring integration
- ✅ Configuration persistence
- ✅ Self-signed certificate support

### Planned Features

- 🔮 Automatic periodic camera sync
- 🔮 Per-camera stream quality selection
- 🔮 UniFi Protect event integration
- 🔮 Snapshot capture via UniFi API
- 🔮 PTZ control for supported cameras
- 🔮 Recording playback from UniFi Protect
- 🔮 Smart detection integration
- 🔮 Keychain password storage
- 🔮 Command-line import tool
- 🔮 Configuration import from UniFi Protect

---

**Note:** UniFi, UniFi Protect, and related product names are trademarks of Ubiquiti Inc. This integration is not affiliated with, endorsed by, or supported by Ubiquiti Inc.
