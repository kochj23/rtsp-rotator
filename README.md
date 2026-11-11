# RTSP Rotator

**macOS RTSP camera feed viewer with on-device object detection and AI camera health summaries**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform](https://img.shields.io/badge/platform-macOS%2012.0%2B-blue)
![Language](https://img.shields.io/badge/language-Objective--C%20%2B%20Swift-orange)
![Tests](https://img.shields.io/badge/tests-270-brightgreen)
![Version](https://img.shields.io/badge/version-2.6.0-blue)

A native macOS application for viewing, rotating and monitoring RTSP camera feeds: multi-view grids,
picture-in-picture, PTZ, motion and object detection (Vision + MLX), UniFi Protect, recording, smart alerts,
dashboards, a REST API and a WidgetKit widget. Camera Diagnostics includes an **AI health summary** from
[NovaAIKit](https://github.com/kochj23/NovaAIKit) — local Ollama/MLX/… or a keyed cloud backend, with a built-in
summary when AI is off or unreachable.

- **Version:** 2.6.0 (build 260)
- **Requires:** macOS 12.0+ (raised from 11.0 for NovaAIKit / Xcode 27)
- **Dependencies:** NovaAIKit 1.0.0 (Swift Package, fetched automatically). Everything else is Apple frameworks.

---

## Architecture

```mermaid
graph TD
    subgraph Application
        AD[AppDelegate] --> WC[RTSPWallpaperController]
        AD --> MBC[RTSPMenuBarController<br/>incl. AI Settings… ⌥⌘,]
        AD --> SMC[RTSPStatusMenuController]
        AD --> PC[RTSPPreferencesController]
    end

    subgraph Display
        WC -->|AVPlayer| STREAM[RTSP Stream]
        WC --> TC[RTSPTransitionController]
        WC --> FSC[RTSPFullScreenController]
        WC --> MVG[RTSPMultiViewGrid]
        WC --> PIP[RTSPPiPController]
        WC --> OSD[RTSPOSDView]
        WC --> TG[RTSPThumbnailGrid]
    end

    subgraph Camera["Camera Management"]
        CM[RTSPCameraTypeManager] --> UFP[RTSPUniFiProtectAdapter]
        CM --> BM[RTSPBookmarkManager]
        CM --> FM[RTSPFeedMetadata]
        CM --> FGM[RTSPFeedGroupManager]
        DM[RTSPDashboardManager] --> CAM[Dashboard Configs]
        DIAG[RTSPCameraDiagnostics]
    end

    subgraph Detection["On-device detection"]
        OD[RTSPObjectDetector - Vision] --> MLX[RTSPMLXProcessor]
        OD --> SA[RTSPSmartAlerts]
        OD --> DOV[RTSPDetectionOverlayView]
        MD[RTSPMotionDetector] --> SA
    end

    subgraph AI["AI (Swift, NovaAIKit)"]
        BR[RTSPAIBridge<br/>@objc entry points] --> CHB[CameraHealthBriefing<br/>facts · validator · built-in fallback]
        CHB --> APP[AppAI.shared · NovaAI]
        BR --> NSV[NovaAISettingsView window]
        APP --> KC[(Keychain<br/>com.jkoch.rtsprotator.*)]
        APP --> BE[Ollama · MLX · TinyChat · TinyLLM · OpenWebUI · Nova Gateway · OpenRouter · OpenAI]
    end

    AD -->|Camera Diagnostics…| DIAG
    AD -->|accessory view| BR

    subgraph Infrastructure
        API[RTSPAPIServer - HTTP REST]
        REC[RTSPRecorder]
        EL[RTSPEventLogger]
        CS[RTSPCloudStorage]
        FOM[RTSPFailoverManager]
        BW[RTSPBandwidthManager]
        NM[RTSPNetworkMonitor]
        KM[RTSPKeychainManager]
        SCH[RTSPScheduleManager]
    end
```

### Camera Diagnostics → AI summary

```mermaid
sequenceDiagram
    participant U as User
    participant AD as AppDelegate
    participant D as RTSPCameraDiagnostics
    participant B as RTSPAIBridge / CameraHealthBriefing
    participant K as NovaAI
    U->>AD: RTSP Cameras ▸ Camera Diagnostics…
    AD->>D: allReports
    AD->>B: report dictionaries (no camera IDs / URLs; credentials redacted)
    B->>K: text(request, validate, fallback)
    alt AI off · all backends down · reply rejected twice
        K-->>B: built-in summary ("2 of 5 camera(s) healthy, 1 failed … Check first: Driveway")
    else AI answered and passed validation
        K-->>B: AI summary · "AI · Ollama (model)"
    end
    B-->>U: alert shows per-camera list + summary + source + status dot
```

---

## Features

| Category | Details |
|----------|---------|
| **Feed Rotation** | Automatic cycling through RTSP/HTTP camera feeds with configurable interval |
| **Multi-View Grid** | 2x2, 3x3, or custom grid layouts showing multiple cameras simultaneously |
| **Picture-in-Picture** | Floating PiP window for any camera feed |
| **Full Screen** | Dedicated full-screen mode with OSD overlay |
| **PTZ Control** | Pan, tilt, zoom control for supported cameras |
| **Transitions** | Animated transitions between feed switches |
| **AI Object Detection** | Vision framework (VNDetectHumanBodyPose, VNClassifyImage) for real-time detection |
| **MLX Processing** | Apple Silicon ML inference via Python bridge for advanced detection |
| **Motion Detection** | Frame-difference motion detection with configurable sensitivity |
| **Smart Alerts** | Notification system triggered by object detection and motion events |
| **Detection Overlay** | Bounding box and annotation overlay on live feeds |
| **UniFi Protect** | Native integration with Ubiquiti UniFi Protect controllers |
| **Camera Types** | Auto-detection and configuration for different camera manufacturers |
| **Bookmarks** | Save and organize favorite camera feeds |
| **Feed Groups** | Group cameras by location or purpose |
| **Dashboards** | Multiple saved dashboard configurations with different camera layouts |
| **Recording** | Record RTSP streams to local files |
| **Audio Monitor** | Monitor audio levels from camera feeds |
| **Snapshots** | Capture still frames from live feeds |
| **Event Logging** | Persistent log of detection events, alerts, and camera status changes |
| **Cloud Storage** | Export recordings and snapshots to cloud storage |
| **Configuration Export** | Import/export camera configurations as files |
| **CSV Import** | Bulk import camera feeds from CSV files |
| **REST API** | HTTP API server for remote control (feed switching, recording, snapshots) |
| **Failover** | Automatic reconnection and failover for dropped streams |
| **Bandwidth Manager** | Monitor and limit network bandwidth per stream |
| **Network Monitor** | Track connection status and latency |
| **Schedule Manager** | Time-based recording and alert schedules |
| **Keychain Storage** | macOS Keychain for all camera credentials and AI keys |
| **AI Camera Health Summary** | NovaAIKit: Camera Diagnostics gets a short AI summary of which cameras need attention, with a built-in fallback |
| **Global Shortcuts** | System-wide keyboard shortcuts for common actions |
| **Themes** | Glassmorphic UI with dark mode support |

---

## AI

| | |
|---|---|
| **Where** | *RTSP Cameras ▸ Camera Diagnostics…*: the alert lists every camera and adds a **Summary** — which cameras need attention and what to check first. Object/motion detection stays on-device (Vision, MLX) and never uses an AI backend. |
| **Settings** | *RTSP Rotator ▸ AI Settings…* (⌥⌘,) or the *AI Settings…* button in the diagnostics alert: NovaAISettingsView with *Use AI*, backend and timeout pickers, URL and model per backend, model list, key entry, *Test connection*. |
| **Off / fallback** | *Use AI* off → nothing is sent; the summary is built in: counts of healthy/warning/failed cameras and the cameras to check first with their first issue. The same text is used when every backend is down or a reply is rejected twice. |
| **Backends** | Auto (failover Ollama → MLX → TinyChat → TinyLLM → OpenWebUI → Nova Gateway → OpenRouter → OpenAI), or one of them. Timeouts, bounded retries (408/429/5xx), 60 s skip for a server that just failed. |
| **Validation** | Plain text, 12–600 characters, every number must appear in the report (no invented camera counts, latencies or loss figures); one retry with the reason, then the built-in summary. |
| **Privacy** | Only camera names, health, latency/loss/dropped-frame numbers and issue texts are sent — never camera IDs or stream URLs, and any `scheme://user:pass@` in an issue text is redacted first. |
| **Keys** | Keychain only: `com.jkoch.rtsprotator.<backend>` / `apiKey`; sent over https only; shown as "stored", never as text. |
| **Status** | NovaAIStatusIndicator next to the summary (backend, model, latency; orange when unreachable). |
| **Migration** | First launch imports any settings of the old built-in `AIBackendManager`, moves a plaintext OpenAI key from UserDefaults (`AIBackend_OpenAI_Key`) and the old Keychain item (`com.jordankoch.RTSPRotator`) into `com.jkoch.rtsprotator.openai`, and deletes leftover Google/Azure/AWS/IBM secrets. |

The old `AIBackendManager` (compiled into the app but never called) and its Google Cloud, Azure, AWS and IBM Watson
stubs were removed in 2.6.0.

---

## REST API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/feeds` | GET | List all configured camera feeds |
| `/api/feeds/current` | GET | Current feed index |
| `/api/feeds/next` | POST | Switch to next feed |
| `/api/feeds/previous` | POST | Switch to previous feed |
| `/api/feeds/{index}` | POST | Switch to specific feed |
| `/api/snapshot` | POST | Capture snapshot |
| `/api/recording/start` | POST | Start recording |
| `/api/recording/stop` | POST | Stop recording |
| `/api/recording/status` | GET | Recording state |
| `/api/rotation/interval` | POST | Set rotation interval |

Optional API key authentication. Configurable port (default 8080).

---

## Requirements

- macOS 12.0 or later
- Xcode 26+ to build (NovaAIKit resolves via Swift Package Manager)
- RTSP-capable cameras on the local network
- Optional for AI summaries: a local LLM server (Ollama `http://localhost:11434` by default) or an OpenRouter/OpenAI key

---

## Install

Open `RTSPRotator-v2.6.0-build260.dmg` and drag **RTSP Rotator** onto **Applications**. Release builds are kept in
`/Volumes/Data/xcode/binaries/<date>-RTSPRotator-v<version>/` and on the NAS under `/Volumes/NAS/binaries/`.

---

## Build

```bash
git clone git@github.com:kochj23/rtsp-rotator.git
cd rtsp-rotator
xcodebuild -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" -configuration Release build
```

The Release build has zero compiler warnings. Sources live in file-system-synchronised folders: anything added under
`RTSP Rotator/` (including `RTSP Rotator/AI/*.swift`) is compiled into the app.

---

## Test Suite

270 XCTest cases, all passing:

```bash
xcodebuild test -project "RTSP Rotator.xcodeproj" -scheme "RTSP Rotator" -destination "platform=macOS"
```

| Suite | Tests | Description |
|-------|------:|-------------|
| Core | 20 | Controller init, feed rotation, URL validation, mute, performance |
| CSV Import | 24 | CSV parsing, quoted fields, comments, URL formats, bulk import |
| Comprehensive | 90 | Full feature coverage across all managers |
| Configuration | 31 | Export/import, dashboard configs, preferences |
| Integration | 12 | Feed loading, rotation, UniFi credential workflow |
| URL Security | 18 | RTSP URL validation, credential stripping, injection prevention |
| Keychain | 32 | Credential storage, retrieval, deletion, edge cases |
| Memory Management | 15 | Retain cycles, leak detection, deallocation |
| **AI (AIKitAdoptionTests.swift)** | **28** | security (Keychain names, credential redaction, legacy key migration, no key over http, no old AI code), performance, retry, unit, integration (Ollama round trip, ObjC bridge), functional (AI off / offline), frame (status, summary view model, settings view) |

When the app hosts the tests it skips its normal startup and never shows modal alerts, so the suite can't hang on a
camera that isn't reachable.

---

## Security

- Camera credentials in the macOS Keychain via RTSPKeychainManager; AI keys in the Keychain via NovaAIKit.
- AI requests never carry camera IDs or stream URLs; credentials in issue texts are redacted.
- URL security validation prevents credential exposure in logs; no hardcoded passwords or API keys.
- UniFi Protect certificates pinned on first use (SHA-256 fingerprint in the Keychain).
- Local API server supports optional API key authentication; ATS exceptions scoped to local addresses.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Latest: **2.6.0** — AI migrated to NovaAIKit 1.0.0 (camera health summary,
AI settings window, status indicator, Keychain-only keys), macOS 12.0 minimum, zero-warning build, test suite fixed
to run unattended.

---

## License

MIT License. See [LICENSE](LICENSE).

Copyright (c) 2025 Jordan Koch.

---

Written by **Jordan Koch** ([@kochj23](https://github.com/kochj23))
