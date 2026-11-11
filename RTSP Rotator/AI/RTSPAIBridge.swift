//
//  RTSPAIBridge.swift
//  RTSP Rotator
//
//  Objective-C entry points for the NovaAIKit features: the AI settings window and the
//  AI camera health summary shown in the Camera Diagnostics alert.
//

import AppKit
import SwiftUI
import NovaAIKit

@MainActor
@objc public final class RTSPAIBridge: NSObject {
    private static var settingsWindow: NSWindow?

    static let settingsFooter = "AI writes the camera health summary in Camera Diagnostics. When AI is off or "
        + "unreachable, the built-in summary (counts and the cameras to check first) is shown instead."

    /// Opens (or brings forward) the AI settings window: on/off, backend, URLs, models, Keychain keys, test connection.
    @objc public static func showSettingsWindow() {
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let root = NovaAISettingsView(ai: AppAI.shared, footer: settingsFooter)
            .padding()
            .frame(minWidth: 480, idealWidth: 520, minHeight: 520, idealHeight: 620)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = "\(AppAI.appName) AI Settings"
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// A view for the Camera Diagnostics alert: starts the AI (or built-in) summary of `reports`
    /// (`-[RTSPCameraDiagnosticReport toDictionary]`) and shows it with its source and the AI status dot.
    @objc public static func diagnosticsSummaryView(reports: [[String: Any]], totalCameras: Int) -> NSView {
        let model = CameraHealthSummaryModel(input: CameraHealthBriefing.Input(totalCameras: totalCameras, reports: reports))
        let host = NSHostingView(rootView: CameraHealthSummaryView(model: model, ai: AppAI.shared))
        host.frame = NSRect(x: 0, y: 0, width: 420, height: 130)
        model.start(ai: AppAI.shared)
        return host
    }
}

/// Holds one summary run for the diagnostics alert.
@MainActor
final class CameraHealthSummaryModel: ObservableObject {
    let input: CameraHealthBriefing.Input
    @Published private(set) var result: NovaAIResult<String>?
    private var task: Task<Void, Never>?

    init(input: CameraHealthBriefing.Input) { self.input = input }

    func start(ai: NovaAI) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            let r = await CameraHealthBriefing.summarize(self.input, ai: ai)
            if !Task.isCancelled { self.result = r }
        }
    }

    deinit { task?.cancel() }
}

struct CameraHealthSummaryView: View {
    @ObservedObject var model: CameraHealthSummaryModel
    @ObservedObject var ai: NovaAI

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Summary").font(.headline)
            if let r = model.result {
                ScrollView {
                    Text(r.value)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 6) {
                    NovaAIStatusIndicator(ai: ai, showsLabel: false, checksOnAppear: false)
                    Text(r.source.label).font(.caption).foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Summarising camera health…").foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(width: 420, height: 130, alignment: .topLeading)
    }
}
