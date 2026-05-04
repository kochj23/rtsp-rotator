//
//  WidgetData.swift
//  RTSP Rotator Widget
//
//  Data models for widget data sharing
//  Created by Jordan Koch
//

import Foundation
import WidgetKit

// MARK: - Camera Health Status

/// Camera health status matching RTSPFeedHealthStatus
public enum CameraHealthStatus: Int, Codable, CaseIterable {
    case unknown = 0
    case healthy = 1
    case degraded = 2
    case unhealthy = 3

    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .healthy: return "Healthy"
        case .degraded: return "Degraded"
        case .unhealthy: return "Offline"
        }
    }

    public var symbolName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .healthy: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.circle.fill"
        }
    }

    public var colorName: String {
        switch self {
        case .unknown: return "gray"
        case .healthy: return "green"
        case .degraded: return "yellow"
        case .unhealthy: return "red"
        }
    }
}

// MARK: - Camera Data

/// Represents camera data for the widget
public struct WidgetCameraData: Codable, Identifiable {
    public var id: String
    public var name: String
    public var displayName: String
    public var healthStatus: CameraHealthStatus
    public var detectionCount: Int
    public var lastDetectionTime: Date?
    public var lastDetectionType: String?
    public var isEnabled: Bool
    public var uptimePercentage: Double
    public var consecutiveFailures: Int
    public var lastSuccessfulConnection: Date?

    public init(
        id: String,
        name: String,
        displayName: String = "",
        healthStatus: CameraHealthStatus = .unknown,
        detectionCount: Int = 0,
        lastDetectionTime: Date? = nil,
        lastDetectionType: String? = nil,
        isEnabled: Bool = true,
        uptimePercentage: Double = 0.0,
        consecutiveFailures: Int = 0,
        lastSuccessfulConnection: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName.isEmpty ? name : displayName
        self.healthStatus = healthStatus
        self.detectionCount = detectionCount
        self.lastDetectionTime = lastDetectionTime
        self.lastDetectionType = lastDetectionType
        self.isEnabled = isEnabled
        self.uptimePercentage = uptimePercentage
        self.consecutiveFailures = consecutiveFailures
        self.lastSuccessfulConnection = lastSuccessfulConnection
    }
}

// MARK: - Widget Entry

/// Timeline entry for the widget
public struct RTSPRotatorEntry: TimelineEntry {
    public let date: Date
    public let cameras: [WidgetCameraData]
    public let currentCameraIndex: Int
    public let totalDetections: Int
    public let healthyCameraCount: Int
    public let totalCameraCount: Int
    public let lastUpdateTime: Date
    public let isAppRunning: Bool

    public init(
        date: Date = Date(),
        cameras: [WidgetCameraData] = [],
        currentCameraIndex: Int = 0,
        totalDetections: Int = 0,
        healthyCameraCount: Int = 0,
        totalCameraCount: Int = 0,
        lastUpdateTime: Date = Date(),
        isAppRunning: Bool = false
    ) {
        self.date = date
        self.cameras = cameras
        self.currentCameraIndex = currentCameraIndex
        self.totalDetections = totalDetections
        self.healthyCameraCount = healthyCameraCount
        self.totalCameraCount = totalCameraCount
        self.lastUpdateTime = lastUpdateTime
        self.isAppRunning = isAppRunning
    }

    /// Current camera or nil if none
    public var currentCamera: WidgetCameraData? {
        guard currentCameraIndex >= 0 && currentCameraIndex < cameras.count else {
            return nil
        }
        return cameras[currentCameraIndex]
    }

    /// Sample entry for previews
    public static var sample: RTSPRotatorEntry {
        let sampleCameras = [
            WidgetCameraData(
                id: "cam1",
                name: "Front Door",
                displayName: "Front Door",
                healthStatus: .healthy,
                detectionCount: 12,
                lastDetectionTime: Date().addingTimeInterval(-300),
                lastDetectionType: "Person",
                isEnabled: true,
                uptimePercentage: 99.5,
                consecutiveFailures: 0,
                lastSuccessfulConnection: Date()
            ),
            WidgetCameraData(
                id: "cam2",
                name: "Backyard",
                displayName: "Backyard",
                healthStatus: .healthy,
                detectionCount: 5,
                lastDetectionTime: Date().addingTimeInterval(-1800),
                lastDetectionType: "Dog",
                isEnabled: true,
                uptimePercentage: 98.2,
                consecutiveFailures: 0,
                lastSuccessfulConnection: Date()
            ),
            WidgetCameraData(
                id: "cam3",
                name: "Garage",
                displayName: "Garage",
                healthStatus: .degraded,
                detectionCount: 3,
                lastDetectionTime: Date().addingTimeInterval(-3600),
                lastDetectionType: "Car",
                isEnabled: true,
                uptimePercentage: 85.0,
                consecutiveFailures: 2,
                lastSuccessfulConnection: Date().addingTimeInterval(-60)
            ),
            WidgetCameraData(
                id: "cam4",
                name: "Driveway",
                displayName: "Driveway",
                healthStatus: .unhealthy,
                detectionCount: 0,
                lastDetectionTime: nil,
                lastDetectionType: nil,
                isEnabled: true,
                uptimePercentage: 0.0,
                consecutiveFailures: 10,
                lastSuccessfulConnection: Date().addingTimeInterval(-7200)
            )
        ]

        return RTSPRotatorEntry(
            date: Date(),
            cameras: sampleCameras,
            currentCameraIndex: 0,
            totalDetections: 20,
            healthyCameraCount: 2,
            totalCameraCount: 4,
            lastUpdateTime: Date(),
            isAppRunning: true
        )
    }

    /// Placeholder entry for loading state
    public static var placeholder: RTSPRotatorEntry {
        RTSPRotatorEntry(
            date: Date(),
            cameras: [],
            currentCameraIndex: 0,
            totalDetections: 0,
            healthyCameraCount: 0,
            totalCameraCount: 0,
            lastUpdateTime: Date(),
            isAppRunning: false
        )
    }
}

// MARK: - Widget Configuration Intent

/// Intent for camera selection
public struct CameraSelectionIntent: Codable {
    public var selectedCameraID: String?

    public init(selectedCameraID: String? = nil) {
        self.selectedCameraID = selectedCameraID
    }
}

// MARK: - Widget Deep Links

/// Deep link actions for the widget
public enum WidgetDeepLink: String {
    case openApp = "rtsprotator://open"
    case switchCamera = "rtsprotator://switch"
    case viewDetections = "rtsprotator://detections"
    case viewDiagnostics = "rtsprotator://diagnostics"

    public func url(cameraID: String? = nil) -> URL {
        if let cameraID = cameraID {
            return URL(string: "\(rawValue)/\(cameraID)")!
        }
        return URL(string: rawValue)!
    }
}
