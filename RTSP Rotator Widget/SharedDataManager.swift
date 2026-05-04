//
//  SharedDataManager.swift
//  RTSP Rotator Widget
//
//  Manages data sharing between main app and widget via App Group
//  Created by Jordan Koch
//

import Foundation
import WidgetKit

// MARK: - App Group Constants

public struct AppGroupConstants {
    public static let groupIdentifier = "group.com.jkoch.rtsprotator"
    public static let cameraDataKey = "widget_camera_data"
    public static let currentCameraIndexKey = "widget_current_camera_index"
    public static let totalDetectionsKey = "widget_total_detections"
    public static let lastUpdateTimeKey = "widget_last_update_time"
    public static let isAppRunningKey = "widget_is_app_running"
}

// MARK: - Shared Data Manager

/// Manages shared data between the main app and widget extension
public class SharedDataManager {

    // MARK: - Singleton

    public static let shared = SharedDataManager()

    // MARK: - Properties

    private let userDefaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    private init() {
        userDefaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)

        if userDefaults == nil {
            print("[SharedDataManager] Warning: Could not initialize UserDefaults with App Group: \(AppGroupConstants.groupIdentifier)")
        }
    }

    // MARK: - Camera Data

    /// Save camera data to shared storage
    public func saveCameraData(_ cameras: [WidgetCameraData]) {
        guard let userDefaults = userDefaults else {
            print("[SharedDataManager] UserDefaults not available")
            return
        }

        do {
            let data = try encoder.encode(cameras)
            userDefaults.set(data, forKey: AppGroupConstants.cameraDataKey)
            userDefaults.set(Date(), forKey: AppGroupConstants.lastUpdateTimeKey)
            userDefaults.synchronize()

            // Trigger widget refresh
            WidgetCenter.shared.reloadTimelines(ofKind: "RTSPRotatorWidget")

            print("[SharedDataManager] Saved \(cameras.count) cameras to widget data")
        } catch {
            print("[SharedDataManager] Error encoding camera data: \(error)")
        }
    }

    /// Load camera data from shared storage
    public func loadCameraData() -> [WidgetCameraData] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: AppGroupConstants.cameraDataKey) else {
            return []
        }

        do {
            let cameras = try decoder.decode([WidgetCameraData].self, from: data)
            return cameras
        } catch {
            print("[SharedDataManager] Error decoding camera data: \(error)")
            return []
        }
    }

    // MARK: - Current Camera Index

    /// Save current camera index
    public func saveCurrentCameraIndex(_ index: Int) {
        userDefaults?.set(index, forKey: AppGroupConstants.currentCameraIndexKey)
        userDefaults?.synchronize()

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "RTSPRotatorWidget")
    }

    /// Load current camera index
    public func loadCurrentCameraIndex() -> Int {
        return userDefaults?.integer(forKey: AppGroupConstants.currentCameraIndexKey) ?? 0
    }

    // MARK: - Detection Count

    /// Save total detection count
    public func saveTotalDetections(_ count: Int) {
        userDefaults?.set(count, forKey: AppGroupConstants.totalDetectionsKey)
        userDefaults?.synchronize()
    }

    /// Load total detection count
    public func loadTotalDetections() -> Int {
        return userDefaults?.integer(forKey: AppGroupConstants.totalDetectionsKey) ?? 0
    }

    // MARK: - App Running State

    /// Save app running state
    public func saveAppRunningState(_ isRunning: Bool) {
        userDefaults?.set(isRunning, forKey: AppGroupConstants.isAppRunningKey)
        userDefaults?.synchronize()

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "RTSPRotatorWidget")
    }

    /// Load app running state
    public func loadAppRunningState() -> Bool {
        return userDefaults?.bool(forKey: AppGroupConstants.isAppRunningKey) ?? false
    }

    // MARK: - Last Update Time

    /// Load last update time
    public func loadLastUpdateTime() -> Date {
        return userDefaults?.object(forKey: AppGroupConstants.lastUpdateTimeKey) as? Date ?? Date.distantPast
    }

    // MARK: - Widget Entry

    /// Create a widget entry from stored data
    public func createWidgetEntry() -> RTSPRotatorEntry {
        let cameras = loadCameraData()
        let currentIndex = loadCurrentCameraIndex()
        let totalDetections = loadTotalDetections()
        let lastUpdateTime = loadLastUpdateTime()
        let isAppRunning = loadAppRunningState()

        let healthyCameras = cameras.filter { $0.healthStatus == .healthy }.count

        return RTSPRotatorEntry(
            date: Date(),
            cameras: cameras,
            currentCameraIndex: currentIndex,
            totalDetections: totalDetections,
            healthyCameraCount: healthyCameras,
            totalCameraCount: cameras.count,
            lastUpdateTime: lastUpdateTime,
            isAppRunning: isAppRunning
        )
    }

    // MARK: - Full Update

    /// Perform a full update of all widget data
    public func updateWidgetData(
        cameras: [WidgetCameraData],
        currentCameraIndex: Int,
        totalDetections: Int,
        isAppRunning: Bool
    ) {
        guard let userDefaults = userDefaults else {
            print("[SharedDataManager] UserDefaults not available")
            return
        }

        do {
            let data = try encoder.encode(cameras)
            userDefaults.set(data, forKey: AppGroupConstants.cameraDataKey)
        } catch {
            print("[SharedDataManager] Error encoding camera data: \(error)")
        }

        userDefaults.set(currentCameraIndex, forKey: AppGroupConstants.currentCameraIndexKey)
        userDefaults.set(totalDetections, forKey: AppGroupConstants.totalDetectionsKey)
        userDefaults.set(isAppRunning, forKey: AppGroupConstants.isAppRunningKey)
        userDefaults.set(Date(), forKey: AppGroupConstants.lastUpdateTimeKey)
        userDefaults.synchronize()

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "RTSPRotatorWidget")

        print("[SharedDataManager] Full widget data update completed")
    }

    // MARK: - Clear Data

    /// Clear all widget data
    public func clearWidgetData() {
        userDefaults?.removeObject(forKey: AppGroupConstants.cameraDataKey)
        userDefaults?.removeObject(forKey: AppGroupConstants.currentCameraIndexKey)
        userDefaults?.removeObject(forKey: AppGroupConstants.totalDetectionsKey)
        userDefaults?.removeObject(forKey: AppGroupConstants.lastUpdateTimeKey)
        userDefaults?.removeObject(forKey: AppGroupConstants.isAppRunningKey)
        userDefaults?.synchronize()

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "RTSPRotatorWidget")

        print("[SharedDataManager] Widget data cleared")
    }
}

// MARK: - Detection Update Helper

extension SharedDataManager {

    /// Update detection count for a specific camera
    public func updateCameraDetection(cameraID: String, detectionType: String) {
        var cameras = loadCameraData()

        if let index = cameras.firstIndex(where: { $0.id == cameraID }) {
            cameras[index].detectionCount += 1
            cameras[index].lastDetectionTime = Date()
            cameras[index].lastDetectionType = detectionType

            saveCameraData(cameras)

            // Update total detections
            let totalDetections = loadTotalDetections() + 1
            saveTotalDetections(totalDetections)
        }
    }

    /// Update camera health status
    public func updateCameraHealth(cameraID: String, status: CameraHealthStatus) {
        var cameras = loadCameraData()

        if let index = cameras.firstIndex(where: { $0.id == cameraID }) {
            cameras[index].healthStatus = status

            if status == .healthy {
                cameras[index].lastSuccessfulConnection = Date()
                cameras[index].consecutiveFailures = 0
            } else if status == .unhealthy {
                cameras[index].consecutiveFailures += 1
            }

            saveCameraData(cameras)
        }
    }
}
