//
//  CameraHealthBriefing.swift
//  RTSP Rotator
//
//  AI camera health summary (NovaAIKit): turns the diagnostics reports into a short note on
//  which cameras need attention and what to check first. When AI is off, unreachable, or its
//  reply is rejected, a deterministic built-in summary is shown instead.
//

import Foundation
import NovaAIKit

enum CameraHealthBriefing {
    /// Longest summary shown.
    static let maxLength = 600
    /// Cameras described to the model (worst first).
    static let maxCameras = 24
    static let maxIssueLength = 160

    static let systemPrompt = """
    You are a video-surveillance technician. Summarise the camera health report for the operator \
    in at most three short plain sentences (under 500 characters): how many cameras are fine, \
    which ones need attention and what to check first (network, credentials, codec, bandwidth). \
    Use only the facts given; never invent numbers or camera names. No markdown, no lists, no greetings.
    """

    /// Health of one camera, as in RTSPCameraHealthStatus.
    enum Health: Int, Sendable, Comparable {
        case unknown = 0, healthy = 1, warning = 2, critical = 3, testing = 4

        var label: String {
            switch self {
            case .unknown: return "untested"
            case .healthy: return "healthy"
            case .warning: return "warning"
            case .critical: return "failed"
            case .testing: return "testing"
            }
        }

        /// Sort key: worst first.
        var severity: Int {
            switch self {
            case .critical: return 4
            case .warning: return 3
            case .unknown: return 2
            case .testing: return 1
            case .healthy: return 0
            }
        }

        static func < (a: Health, b: Health) -> Bool { a.severity < b.severity }
    }

    /// The parts of one diagnostics report the summary uses. Never the camera ID or URL
    /// (they can carry credentials).
    struct Camera: Sendable, Equatable {
        var name: String
        var health: Health
        var canConnect: Bool
        var latencyMs: Double
        var packetLoss: Double
        var droppedFrames: Int
        var issues: [String]

        init(name: String, health: Health, canConnect: Bool = true, latencyMs: Double = 0,
             packetLoss: Double = 0, droppedFrames: Int = 0, issues: [String] = []) {
            self.name = CameraHealthBriefing.redact(String(name.prefix(80)))
            self.health = health
            self.canConnect = canConnect
            self.latencyMs = latencyMs
            self.packetLoss = packetLoss
            self.droppedFrames = droppedFrames
            self.issues = issues.prefix(4).map { CameraHealthBriefing.redact(String($0.prefix(CameraHealthBriefing.maxIssueLength))) }
        }

        /// From `-[RTSPCameraDiagnosticReport toDictionary]`.
        init(report d: [String: Any]) {
            let name = (d["cameraName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Unnamed camera"
            let health = Health(rawValue: (d["healthStatus"] as? NSNumber)?.intValue ?? 0) ?? .unknown
            let issues = ((d["errors"] as? [String]) ?? []) + ((d["warnings"] as? [String]) ?? [])
            self.init(name: name, health: health,
                      canConnect: (d["canConnect"] as? NSNumber)?.boolValue ?? false,
                      latencyMs: (d["latency"] as? NSNumber)?.doubleValue ?? 0,
                      packetLoss: (d["packetLoss"] as? NSNumber)?.doubleValue ?? 0,
                      droppedFrames: (d["droppedFrames"] as? NSNumber)?.intValue ?? 0,
                      issues: issues)
        }

        var line: String {
            var s = "\(name): \(health.label)"
            if !canConnect { s += ", cannot connect" }
            if latencyMs > 0 { s += ", latency \(Int(latencyMs.rounded())) ms" }
            if packetLoss > 0 { s += ", packet loss \(String(format: "%.1f", min(packetLoss, 100)))%" }
            if droppedFrames > 0 { s += ", \(droppedFrames) dropped frames" }
            if !issues.isEmpty { s += ". Issues: \(issues.joined(separator: "; "))" }
            return s
        }
    }

    struct Input: Sendable, Equatable {
        var totalCameras: Int
        var cameras: [Camera]

        init(totalCameras: Int, cameras: [Camera]) {
            self.totalCameras = max(totalCameras, cameras.count)
            self.cameras = cameras
        }

        init(totalCameras: Int, reports: [[String: Any]]) {
            self.init(totalCameras: totalCameras, cameras: reports.map(Camera.init(report:)))
        }

        func count(_ h: Health) -> Int { cameras.filter { $0.health == h }.count }
        var attention: [Camera] { cameras.filter { $0.health == .critical || $0.health == .warning }.sorted { $0.health > $1.health } }
        var untested: Int { totalCameras - cameras.count + count(.unknown) + count(.testing) }

        /// The facts sent to the model; also the grounding source for the validator.
        var facts: String {
            var lines = [
                "Cameras configured: \(totalCameras)",
                "Tested: \(cameras.count) (healthy \(count(.healthy)), warning \(count(.warning)), failed \(count(.critical)))",
            ]
            let worstFirst = cameras.sorted { $0.health > $1.health }.prefix(CameraHealthBriefing.maxCameras)
            if !worstFirst.isEmpty {
                lines.append("Per camera:")
                lines += worstFirst.map { "- \($0.line)" }
            }
            return lines.joined(separator: "\n")
        }
    }

    static func request(for input: Input) -> NovaAIRequest {
        NovaAIRequest(prompt: input.facts, system: systemPrompt, temperature: 0.2, maxTokens: 220)
    }

    /// Built-in summary: deterministic, from the reports alone.
    static func fallback(for input: Input) -> String {
        if input.cameras.isEmpty {
            return input.totalCameras == 0
                ? "No cameras configured."
                : "No diagnostics yet for \(input.totalCameras) camera(s). Run a camera test first."
        }
        var s = "\(input.count(.healthy)) of \(input.totalCameras) camera(s) healthy"
        let failed = input.count(.critical), warn = input.count(.warning)
        if failed > 0 { s += ", \(failed) failed" }
        if warn > 0 { s += ", \(warn) with warnings" }
        s += "."
        let attention = input.attention
        if !attention.isEmpty {
            let names = attention.prefix(4).map(\.name).joined(separator: ", ")
            s += " Check first: \(names)"
            s += attention.count > 4 ? " and \(attention.count - 4) more." : "."
            if let first = attention.first, let issue = first.issues.first {
                s += " \(first.name): \(issue)"
            }
        }
        return String(s.prefix(maxLength))
    }

    /// Accepts a short plain reply whose numbers all appear in the facts; rejects the rest.
    static func validate(_ reply: String, input: Input) throws -> String {
        guard let cleaned = NovaAIText.clean(reply) else { throw NovaAIValidationError("empty reply") }
        let text = NovaAIText.plain(cleaned, max: 4_000)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard text.count >= 12 else { throw NovaAIValidationError("reply too short") }
        guard text.count <= maxLength else { throw NovaAIValidationError("reply longer than \(maxLength) characters") }
        guard NovaAIText.grounded(text, in: input.facts) else {
            throw NovaAIValidationError("reply contains numbers that are not in the camera report")
        }
        return text
    }

    /// AI summary or the built-in one. Never throws; honours the AI on/off switch.
    @MainActor
    static func summarize(_ input: Input, ai: NovaAI) async -> NovaAIResult<String> {
        await ai.text(request(for: input),
                      validate: { try validate($0, input: input) },
                      fallback: { fallback(for: input) })
    }

    /// Removes credentials from URLs ("rtsp://user:pass@host" -> "rtsp://host") so they never reach a model.
    static func redact(_ s: String) -> String {
        s.replacingOccurrences(of: #"([A-Za-z][A-Za-z0-9+.-]*://)[^/@\s]+@"#, with: "$1", options: .regularExpression)
    }
}
