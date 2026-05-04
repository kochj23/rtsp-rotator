//
//  RTSPWidgetRefreshHelper.swift
//  RTSP Rotator
//
//  Swift helper to refresh widget timelines from Objective-C code
//  This is needed because WidgetCenter is a Swift-only API
//  Created by Jordan Koch
//

import Foundation
import WidgetKit

/// Helper class to bridge Objective-C to Swift WidgetKit APIs
@objc public class RTSPWidgetRefreshHelper: NSObject {

    // MARK: - Singleton

    @objc public static let shared = RTSPWidgetRefreshHelper()

    // MARK: - Properties

    private let widgetRefreshNotification = NSNotification.Name("com.jkoch.rtsprotator.refreshWidget")

    // MARK: - Initialization

    private override init() {
        super.init()
        setupNotificationObserver()
    }

    // MARK: - Setup

    private func setupNotificationObserver() {
        // Listen for refresh notifications from Objective-C
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWidgetRefreshNotification),
            name: widgetRefreshNotification,
            object: nil
        )

        // Also listen on distributed notification center
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleWidgetRefreshNotification),
            name: widgetRefreshNotification,
            object: nil
        )

        NSLog("[RTSPWidgetRefreshHelper] Notification observers registered")
    }

    // MARK: - Notification Handler

    @objc private func handleWidgetRefreshNotification() {
        refreshAllWidgets()
    }

    // MARK: - Public Methods

    /// Refresh all RTSP Rotator widgets
    @objc public func refreshAllWidgets() {
        if #available(macOS 11.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "RTSPRotatorWidget")
            NSLog("[RTSPWidgetRefreshHelper] Widget timelines reloaded")
        }
    }

    /// Refresh all widgets with specific kind
    @objc public func refreshWidgets(ofKind kind: String) {
        if #available(macOS 11.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
            NSLog("[RTSPWidgetRefreshHelper] Widget timelines reloaded for kind: \(kind)")
        }
    }

    /// Reload all widgets
    @objc public func reloadAllTimelines() {
        if #available(macOS 11.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            NSLog("[RTSPWidgetRefreshHelper] All widget timelines reloaded")
        }
    }

    /// Get current widget configurations (for debugging)
    @objc public func logCurrentWidgetConfigurations() {
        if #available(macOS 11.0, *) {
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let widgets):
                    NSLog("[RTSPWidgetRefreshHelper] Current widgets: \(widgets.count)")
                    for widget in widgets {
                        NSLog("  - Kind: \(widget.kind), Family: \(widget.family)")
                    }
                case .failure(let error):
                    NSLog("[RTSPWidgetRefreshHelper] Error getting widget configurations: \(error)")
                }
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
}

// MARK: - Objective-C Convenience Methods

extension RTSPWidgetRefreshHelper {
    /// Static function callable from Objective-C to refresh widgets
    @objc public static func refreshTimelines() {
        shared.refreshAllWidgets()
    }

    /// Static function callable from Objective-C to reload all widget timelines
    @objc public static func reloadTimelines() {
        shared.reloadAllTimelines()
    }
}
