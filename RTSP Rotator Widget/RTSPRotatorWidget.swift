//
//  RTSPRotatorWidget.swift
//  RTSP Rotator Widget
//
//  WidgetKit widget for RTSP Rotator - displays camera status, detections, and health
//  Supports Small, Medium, and Large widget sizes
//  Created by Jordan Koch
//

import WidgetKit
import SwiftUI

// MARK: - Widget Provider

struct RTSPRotatorProvider: TimelineProvider {

    func placeholder(in context: Context) -> RTSPRotatorEntry {
        return RTSPRotatorEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (RTSPRotatorEntry) -> Void) {
        if context.isPreview {
            completion(RTSPRotatorEntry.sample)
        } else {
            let entry = SharedDataManager.shared.createWidgetEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RTSPRotatorEntry>) -> Void) {
        let entry = SharedDataManager.shared.createWidgetEntry()

        // Refresh every 5 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

        completion(timeline)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: RTSPRotatorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.blue)
                Text("RTSP Rotator")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            if let camera = entry.currentCamera {
                // Camera name
                Text(camera.displayName)
                    .font(.headline)
                    .lineLimit(1)

                // Health status
                HStack(spacing: 4) {
                    Image(systemName: camera.healthStatus.symbolName)
                        .foregroundColor(healthColor(camera.healthStatus))
                    Text(camera.healthStatus.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Detection count
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.orange)
                    Text("\(camera.detectionCount) alerts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // No cameras configured
                VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No cameras")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .widgetURL(WidgetDeepLink.openApp.url())
    }

    private func healthColor(_ status: CameraHealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .unhealthy: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: RTSPRotatorEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Current camera info
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(.blue)
                    Text("RTSP Rotator")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }

                Spacer()

                if let camera = entry.currentCamera {
                    // Camera name
                    Text(camera.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    // Health status
                    HStack(spacing: 4) {
                        Image(systemName: camera.healthStatus.symbolName)
                            .foregroundColor(healthColor(camera.healthStatus))
                        Text(camera.healthStatus.displayName)
                            .font(.caption)
                    }

                    // Last detection
                    if let lastDetection = camera.lastDetectionTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text(timeAgo(lastDetection))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No cameras")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side - Stats
            VStack(alignment: .trailing, spacing: 8) {
                // Total cameras
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.healthyCameraCount)/\(entry.totalCameraCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Healthy")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Total detections
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.totalDetections)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Detections")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80)
        }
        .padding()
        .widgetURL(WidgetDeepLink.openApp.url())
    }

    private func healthColor(_ status: CameraHealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .unhealthy: return .red
        case .unknown: return .gray
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: RTSPRotatorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("RTSP Rotator")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Status indicator
                Circle()
                    .fill(entry.isAppRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(entry.isAppRunning ? "Running" : "Stopped")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Stats row
            HStack(spacing: 24) {
                StatView(
                    value: "\(entry.totalCameraCount)",
                    label: "Cameras",
                    icon: "video",
                    color: .blue
                )

                StatView(
                    value: "\(entry.healthyCameraCount)",
                    label: "Healthy",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatView(
                    value: "\(entry.totalDetections)",
                    label: "Detections",
                    icon: "eye.fill",
                    color: .orange
                )
            }

            Divider()

            // Camera list
            Text("Cameras")
                .font(.subheadline)
                .fontWeight(.semibold)

            if entry.cameras.isEmpty {
                VStack {
                    Spacer()
                    Text("No cameras configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ForEach(entry.cameras.prefix(4)) { camera in
                    CameraRowView(camera: camera, isCurrentCamera: camera.id == entry.currentCamera?.id)
                }
            }

            Spacer()

            // Last update
            HStack {
                Text("Updated \(timeAgo(entry.lastUpdateTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .widgetURL(WidgetDeepLink.openApp.url())
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

struct StatView: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct CameraRowView: View {
    let camera: WidgetCameraData
    let isCurrentCamera: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Health indicator
            Circle()
                .fill(healthColor(camera.healthStatus))
                .frame(width: 8, height: 8)

            // Camera name
            Text(camera.displayName)
                .font(.caption)
                .lineLimit(1)
                .font(.caption.weight(isCurrentCamera ? .semibold : .regular))

            Spacer()

            // Detection count
            if camera.detectionCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(camera.detectionCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Current camera indicator
            if isCurrentCamera {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 2)
    }

    private func healthColor(_ status: CameraHealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .unhealthy: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Widget Entry View

struct RTSPRotatorWidgetEntryView: View {
    var entry: RTSPRotatorEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

@main
struct RTSPRotatorWidget: Widget {
    let kind: String = "RTSPRotatorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RTSPRotatorProvider()) { entry in
            if #available(macOS 14.0, *) {
                RTSPRotatorWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                RTSPRotatorWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("RTSP Rotator")
        .description("Monitor your security cameras with AI detection alerts and health status.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Previews

@available(macOS 14.0, *)
struct RTSPRotatorWidget_Previews: PreviewProvider {
    static var previews: some View {
        Text("Widget Preview requires macOS 14+")
    }
}
