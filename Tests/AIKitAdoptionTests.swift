//
//  AIKitAdoptionTests.swift
//  RTSP Rotator Tests
//
//  The app's contract with NovaAIKit 1.0.0 (AI camera health summary), grouped in the seven
//  categories: security, performance, retry, unit, integration, functional, frame/UI-state.
//  Nothing here touches the real Keychain or the network: settings and keys are in memory
//  and every request goes to a stub URLProtocol.
//

import XCTest
import AppKit
import SwiftUI
import NovaAIKit
@testable import RTSP_Rotator

// MARK: - Support

/// Serves canned replies; records requests. Refuses everything when no reply is queued, and refuses (without
/// recording or consuming a reply) late requests from sessions of earlier tests.
final class AIStubProtocol: URLProtocol {
    struct Reply { var status: Int; var body: String }
    static let tokenHeader = "X-AIKit-Test-Session"
    private static let lock = NSLock()
    private static var replies: [Reply] = []
    private static var seen: [URLRequest] = []
    private static var token = UUID().uuidString

    static func newSessionToken() -> String {
        lock.lock(); defer { lock.unlock() }
        token = UUID().uuidString
        return token
    }
    static func queue(_ r: [Reply]) { lock.lock(); replies = r; seen = []; lock.unlock() }
    static var requests: [URLRequest] { lock.lock(); defer { lock.unlock() }; return seen }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        let current = request.value(forHTTPHeaderField: Self.tokenHeader) == Self.token
        if current { Self.seen.append(request) }
        let reply = (!current || Self.replies.isEmpty) ? nil : Self.replies.removeFirst()
        Self.lock.unlock()
        guard let reply, let url = request.url,
              let http = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: "HTTP/1.1",
                                         headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(reply.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}

    /// An Ollama /api/chat reply carrying `text`.
    static func ollama(_ text: String) -> Reply {
        let obj: [String: Any] = ["model": "test-model", "message": ["role": "assistant", "content": text], "done": true]
        let data = (try? JSONSerialization.data(withJSONObject: obj)) ?? Data()
        return Reply(status: 200, body: String(decoding: data, as: UTF8.self))
    }
}

enum AITestSupport {
    @MainActor
    static func makeAI(_ settings: NovaAISettings = NovaAISettings(backend: .ollama),
                       keys: NovaAIMemoryKeyStore = NovaAIMemoryKeyStore()) -> NovaAI {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [AIStubProtocol.self]
        cfg.httpAdditionalHeaders = [AIStubProtocol.tokenHeader: AIStubProtocol.newSessionToken()]
        return NovaAI(configuration: NovaAIConfiguration(appID: AppAI.appID, appName: AppAI.appName),
                      storage: NovaAIMemoryStorage(settings), keyStore: keys,
                      session: URLSession(configuration: cfg), sleep: { _ in })
    }

    /// Two healthy cameras, one failed (credentials in its error text), one with packet loss.
    static let reports: [[String: Any]] = [
        ["cameraID": "rtsp://admin:hunter2@10.0.0.5/stream", "cameraName": "Driveway", "healthStatus": 3,
         "canConnect": false, "latency": 0, "packetLoss": 0, "droppedFrames": 0,
         "errors": ["Connection refused by rtsp://admin:hunter2@10.0.0.5:554/stream"], "warnings": []],
        ["cameraID": "c2", "cameraName": "Back Yard", "healthStatus": 2, "canConnect": true,
         "latency": 180, "packetLoss": 7.5, "droppedFrames": 42, "errors": [], "warnings": ["High packet loss"]],
        ["cameraID": "c3", "cameraName": "Front Door", "healthStatus": 1, "canConnect": true, "latency": 20,
         "packetLoss": 0, "droppedFrames": 0, "errors": [], "warnings": []],
        ["cameraID": "c4", "cameraName": "Garage", "healthStatus": 1, "canConnect": true, "latency": 25,
         "packetLoss": 0, "droppedFrames": 0, "errors": [], "warnings": []],
    ]
    static var input: CameraHealthBriefing.Input { CameraHealthBriefing.Input(totalCameras: 5, reports: reports) }

    static func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }
}

// MARK: - Security

final class AISecurityTests: XCTestCase {
    func testKeychainServiceNames() {
        let c = NovaAIConfiguration(appID: "rtsprotator", appName: "RTSP Rotator")
        XCTAssertEqual(c.keychainService(for: .openRouter), "com.jkoch.rtsprotator.openrouter")
        XCTAssertEqual(c.keychainService(for: .openAI), "com.jkoch.rtsprotator.openai")
        XCTAssertEqual(AppAI.appID, "rtsprotator")
    }

    /// Camera URLs carry credentials: they must never reach a model.
    func testCredentialsAndCameraIDsNeverReachTheModel() {
        let facts = AITestSupport.input.facts
        XCTAssertFalse(facts.contains("hunter2"))
        XCTAssertFalse(facts.contains("admin:"))
        XCTAssertTrue(facts.contains("rtsp://10.0.0.5:554/stream"))
        XCTAssertFalse(CameraHealthBriefing.fallback(for: AITestSupport.input).contains("hunter2"))
        XCTAssertEqual(CameraHealthBriefing.redact("http://u:p@h/x and rtsps://a@b"), "http://h/x and rtsps://b")
    }

    /// The plaintext OpenAI key the old AIBackendManager kept in UserDefaults moves to the Keychain and is removed;
    /// the removed cloud backends' plaintext secrets are deleted.
    @MainActor
    func testLegacyPlaintextKeysLeaveUserDefaults() throws {
        let suite = "AIKitAdoptionTests.security.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("sk-test-not-a-real-key-000000", forKey: "AIBackend_OpenAI_Key")
        defaults.set("legacy-google", forKey: "AIBackend_GoogleCloud_Key")
        defaults.set("legacy-aws", forKey: "AIBackend_AWS_SecretKey")
        let ai = AITestSupport.makeAI()

        AppAI.migrateLegacy(ai, defaults: defaults, legacyStore: NovaAIMemoryKeyStore())

        XCTAssertNil(defaults.object(forKey: "AIBackend_OpenAI_Key"))
        XCTAssertNil(defaults.object(forKey: "AIBackend_GoogleCloud_Key"))
        XCTAssertNil(defaults.object(forKey: "AIBackend_AWS_SecretKey"))
        XCTAssertTrue(ai.hasAPIKey(for: .openAI))
    }

    /// The old Keychain item moves to com.jkoch.rtsprotator.openai once; the removed backends' items are deleted.
    @MainActor
    func testLegacyKeychainItemsMigrateOnce() throws {
        let suite = "AIKitAdoptionTests.keychain.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = NovaAIMemoryKeyStore()
        _ = legacy.write("sk-legacy-not-real", service: AppAI.legacyKeychainService, account: "AIBackend_OpenAI_Key")
        _ = legacy.write("old-azure", service: AppAI.legacyKeychainService, account: "AIBackend_Azure_Key")
        let ai = AITestSupport.makeAI()

        AppAI.migrateLegacy(ai, defaults: defaults, legacyStore: legacy)

        XCTAssertTrue(ai.hasAPIKey(for: .openAI))
        XCTAssertNil(legacy.read(service: AppAI.legacyKeychainService, account: "AIBackend_OpenAI_Key"))
        XCTAssertNil(legacy.read(service: AppAI.legacyKeychainService, account: "AIBackend_Azure_Key"))
        XCTAssertTrue(defaults.bool(forKey: AppAI.legacyKeychainMarker))
    }

    @MainActor
    func testKeysAreNotInSettings() throws {
        let ai = AITestSupport.makeAI()
        XCTAssertTrue(ai.setAPIKey("sk-or-test-not-real", for: .openRouter))
        let blob = String(decoding: try JSONEncoder().encode(ai.settings), as: UTF8.self)
        XCTAssertFalse(blob.contains("sk-or-test-not-real"))
    }

    /// A key is never sent over plain http to a remote host.
    @MainActor
    func testKeyNotSentOverHTTP() async {
        var s = NovaAISettings(backend: .openAI)
        s.setURL("http://example.com/v1", for: .openAI)
        let ai = AITestSupport.makeAI(s)
        _ = ai.setAPIKey("sk-test-not-real", for: .openAI)
        AIStubProtocol.queue([AIStubProtocol.ollama("should not be used")])
        let r = await CameraHealthBriefing.summarize(AITestSupport.input, ai: ai)
        XCTAssertFalse(r.isAI)
        XCTAssertTrue(AIStubProtocol.requests.isEmpty, "a keyed request went out over http")
    }

    /// No copy of the old AI client is left in the app's sources.
    func testNoLegacyAIClientInSources() throws {
        let root = AITestSupport.repoRoot()
        let fm = FileManager.default
        var hits: [String] = []
        for dir in ["RTSP Rotator", "RTSP Rotator Widget"] {
            guard let e = fm.enumerator(atPath: root.appendingPathComponent(dir).path) else { continue }
            while let f = e.nextObject() as? String {
                guard f.hasSuffix(".swift") || f.hasSuffix(".m") || f.hasSuffix(".h") else { continue }
                let text = (try? String(contentsOf: root.appendingPathComponent(dir).appendingPathComponent(f), encoding: .utf8)) ?? ""
                for needle in ["AIBackendManager.shared", "class AIBackendManager", "EthicalAIGuardian", "OPENAI_API_KEY",
                               "AIBackendStatusMenu"] where text.contains(needle) {
                    hits.append("\(dir)/\(f): \(needle)")
                }
            }
        }
        XCTAssertEqual(hits, [])
    }
}

// MARK: - Performance

final class AIPerformanceTests: XCTestCase {
    @MainActor
    func testFallbackIsImmediateWhenAIOff() async {
        let ai = AITestSupport.makeAI(NovaAISettings(enabled: false))
        let start = Date()
        for _ in 0..<50 { _ = await CameraHealthBriefing.summarize(AITestSupport.input, ai: ai) }
        XCTAssertLessThan(Date().timeIntervalSince(start), 1.0)
    }

    @MainActor
    func testOfflineFallbackDoesNotHang() async {
        AIStubProtocol.queue([])
        let ai = AITestSupport.makeAI(NovaAISettings(backend: .auto))
        let start = Date()
        let r = await CameraHealthBriefing.summarize(AITestSupport.input, ai: ai)
        XCTAssertFalse(r.isAI)
        XCTAssertLessThan(Date().timeIntervalSince(start), 5.0)
    }

    func testLargeCameraFleetIsCapped() {
        let cams = (0..<5_000).map { CameraHealthBriefing.Camera(name: "Cam \($0)", health: .warning,
                                                                    issues: [String(repeating: "x", count: 2_000)]) }
        let input = CameraHealthBriefing.Input(totalCameras: 5_000, cameras: cams)
        measure { _ = input.facts; _ = CameraHealthBriefing.fallback(for: input) }
        XCTAssertLessThanOrEqual(input.facts.components(separatedBy: "\n- ").count - 1, CameraHealthBriefing.maxCameras)
        XCTAssertTrue(cams.allSatisfy { $0.issues.allSatisfy { $0.count <= CameraHealthBriefing.maxIssueLength } })
    }
}

// MARK: - Retry

final class AIRetryTests: XCTestCase {
    @MainActor
    func testTransientServerErrorIsRetried() async {
        AIStubProtocol.queue([.init(status: 503, body: "{}"),
                              AIStubProtocol.ollama("Driveway is down and Back Yard drops packets; check the Driveway network first.")])
        let r = await CameraHealthBriefing.summarize(AITestSupport.input, ai: AITestSupport.makeAI())
        XCTAssertTrue(r.isAI)
        XCTAssertTrue(r.value.hasPrefix("Driveway is down"))
    }

    /// An invented number is rejected; the kit asks once more and the corrected reply is used.
    @MainActor
    func testRejectedReplyIsAskedAgain() async {
        AIStubProtocol.queue([AIStubProtocol.ollama("9 cameras are offline."),
                              AIStubProtocol.ollama("2 of 5 cameras are healthy; Driveway failed, check it first.")])
        let r = await CameraHealthBriefing.summarize(AITestSupport.input, ai: AITestSupport.makeAI())
        XCTAssertTrue(r.isAI)
        XCTAssertTrue(r.value.hasPrefix("2 of 5"))
        XCTAssertEqual(AIStubProtocol.requests.count, 2)
    }

    @MainActor
    func testTwiceRejectedFallsBack() async {
        AIStubProtocol.queue([AIStubProtocol.ollama("9 cameras are offline."), AIStubProtocol.ollama("Still 9.")])
        let r = await CameraHealthBriefing.summarize(AITestSupport.input, ai: AITestSupport.makeAI())
        XCTAssertFalse(r.isAI)
        guard case .fallback(.validationFailed) = r.source else { return XCTFail("expected validationFailed, got \(r.source)") }
        XCTAssertEqual(r.value, CameraHealthBriefing.fallback(for: AITestSupport.input))
    }
}

// MARK: - Unit

final class AIUnitTests: XCTestCase {
    func testFallbackSummarisesTheFleet() {
        let text = CameraHealthBriefing.fallback(for: AITestSupport.input)
        XCTAssertTrue(text.hasPrefix("2 of 5 camera(s) healthy, 1 failed, 1 with warnings."), text)
        XCTAssertTrue(text.contains("Check first: Driveway, Back Yard."))
        XCTAssertLessThanOrEqual(text.count, CameraHealthBriefing.maxLength)
    }

    func testFallbackWithoutReports() {
        XCTAssertEqual(CameraHealthBriefing.fallback(for: .init(totalCameras: 0, cameras: [])), "No cameras configured.")
        XCTAssertTrue(CameraHealthBriefing.fallback(for: .init(totalCameras: 3, cameras: [])).contains("Run a camera test"))
    }

    func testReportParsing() {
        let cams = AITestSupport.input.cameras
        XCTAssertEqual(cams.count, 4)
        XCTAssertEqual(cams[0].health, .critical)
        XCTAssertFalse(cams[0].canConnect)
        XCTAssertEqual(cams[1].droppedFrames, 42)
        XCTAssertEqual(cams[1].issues, ["High packet loss"])
        let odd = CameraHealthBriefing.Camera(report: ["healthStatus": 99])
        XCTAssertEqual(odd.name, "Unnamed camera")
        XCTAssertEqual(odd.health, .unknown)
    }

    func testValidatorAcceptsGroundedPlainText() throws {
        let v = try CameraHealthBriefing.validate("  **Driveway** failed;\ncheck its network. Back Yard loses 7.5% of packets. ",
                                                  input: AITestSupport.input)
        XCTAssertEqual(v, "Driveway failed; check its network. Back Yard loses 7.5% of packets.")
    }

    func testValidatorRejectsNonsense() {
        let input = AITestSupport.input
        XCTAssertThrowsError(try CameraHealthBriefing.validate("", input: input))
        XCTAssertThrowsError(try CameraHealthBriefing.validate("ok", input: input))
        XCTAssertThrowsError(try CameraHealthBriefing.validate(String(repeating: "word ", count: 200), input: input))
        XCTAssertThrowsError(try CameraHealthBriefing.validate("Latency is 900 ms on 7 cameras.", input: input))
        XCTAssertThrowsError(try CameraHealthBriefing.validate("<think>12345</think>", input: input))
    }

    func testFactsAndRequest() {
        let facts = AITestSupport.input.facts
        XCTAssertTrue(facts.contains("Cameras configured: 5"))
        XCTAssertTrue(facts.contains("healthy 2, warning 1, failed 1"))
        XCTAssertTrue(facts.contains("- Back Yard: warning, latency 180 ms, packet loss 7.5%, 42 dropped frames"))
        XCTAssertTrue(facts.hasPrefix("Cameras configured"))
        let req = CameraHealthBriefing.request(for: AITestSupport.input)
        XCTAssertEqual(req.messages.first?.role, .system)
        XCTAssertLessThanOrEqual(req.maxTokens, 300)
    }

    func testBackendCatalogue() {
        XCTAssertEqual(NovaAIBackend.allCases.count, 9)
    }
}

// MARK: - Integration

final class AIIntegrationTests: XCTestCase {
    @MainActor
    func testSummaryFromOllama() async throws {
        AIStubProtocol.queue([AIStubProtocol.ollama("Driveway failed and Back Yard is degraded; check the Driveway network first.")])
        let r = await CameraHealthBriefing.summarize(AITestSupport.input, ai: AITestSupport.makeAI())
        XCTAssertTrue(r.isAI)
        XCTAssertTrue(r.source.label.hasPrefix("AI · Ollama"))
        let req = try XCTUnwrap(AIStubProtocol.requests.first)
        XCTAssertEqual(req.url?.path, "/api/chat")
    }

    @MainActor
    func testLegacySettingsMigrate() throws {
        let suite = "AIKitAdoptionTests.settings.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("Ollama", forKey: "AIBackend_Active")
        defaults.set("http://studio.local:11434", forKey: "AIBackend_OllamaURL")
        defaults.set("qwen3:8b", forKey: "AIBackend_OllamaModel")
        let ai = AITestSupport.makeAI(NovaAISettings())

        AppAI.migrateLegacy(ai, defaults: defaults, legacyStore: NovaAIMemoryKeyStore())

        XCTAssertEqual(ai.settings.backend, .ollama)
        XCTAssertEqual(ai.settings.url(for: .ollama), "http://studio.local:11434")
        XCTAssertEqual(ai.settings.model(for: .ollama), "qwen3:8b")
    }

    /// The Objective-C entry point builds the diagnostics view from report dictionaries.
    @MainActor
    func testObjectiveCBridgeBuildsSummaryView() {
        let view = RTSPAIBridge.diagnosticsSummaryView(reports: AITestSupport.reports, totalCameras: 5)
        XCTAssertEqual(view.frame.size, NSSize(width: 420, height: 130))
    }
}

// MARK: - Functional

final class AIFunctionalTests: XCTestCase {
    @MainActor
    func testEveryFeatureWorksWithAIOff() async {
        AIStubProtocol.queue([AIStubProtocol.ollama("unused")])
        let ai = AITestSupport.makeAI(NovaAISettings(enabled: false))
        for input in [AITestSupport.input, .init(totalCameras: 0, cameras: []), .init(totalCameras: 2, cameras: [])] {
            let r = await CameraHealthBriefing.summarize(input, ai: ai)
            XCTAssertFalse(r.value.isEmpty)
            XCTAssertEqual(r.source, .fallback(.disabled))
        }
        XCTAssertTrue(AIStubProtocol.requests.isEmpty)
    }

    @MainActor
    func testEveryFeatureFallsBackWhenOffline() async {
        AIStubProtocol.queue([])
        let r = await CameraHealthBriefing.summarize(AITestSupport.input, ai: AITestSupport.makeAI(NovaAISettings(backend: .auto)))
        XCTAssertFalse(r.isAI)
        XCTAssertEqual(r.value, CameraHealthBriefing.fallback(for: AITestSupport.input))
    }
}

// MARK: - Frame / UI state

final class AIFrameTests: XCTestCase {
    @MainActor
    func testStatusReflectsToggleAndSource() async {
        let ai = AITestSupport.makeAI()
        ai.isEnabled = false
        XCTAssertEqual(ai.status.state, .off)
        _ = await CameraHealthBriefing.summarize(AITestSupport.input, ai: ai)
        XCTAssertEqual(ai.status.lastSource, .fallback(.disabled))

        ai.isEnabled = true
        AIStubProtocol.queue([AIStubProtocol.ollama("Driveway failed; check its network first.")])
        _ = await CameraHealthBriefing.summarize(AITestSupport.input, ai: ai)
        XCTAssertEqual(ai.status.state, .online)
        XCTAssertEqual(ai.status.activeBackend, .ollama)
    }

    /// The diagnostics view model goes from "summarising" to a result with a source.
    @MainActor
    func testSummaryModelPublishesResult() async throws {
        let ai = AITestSupport.makeAI(NovaAISettings(enabled: false))
        let model = CameraHealthSummaryModel(input: AITestSupport.input)
        XCTAssertNil(model.result)
        model.start(ai: ai)
        for _ in 0..<100 where model.result == nil { try await Task.sleep(nanoseconds: 10_000_000) }
        XCTAssertEqual(model.result?.source, .fallback(.disabled))
        let host = NSHostingView(rootView: CameraHealthSummaryView(model: model, ai: ai))
        host.frame = NSRect(x: 0, y: 0, width: 420, height: 130)
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.fittingSize.height, 0)
    }

    @MainActor
    func testSettingsViewRenders() {
        let host = NSHostingView(rootView: NovaAISettingsView(ai: AITestSupport.makeAI(), footer: RTSPAIBridge.settingsFooter))
        host.frame = NSRect(x: 0, y: 0, width: 520, height: 600)
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.fittingSize.height, 0)
    }
}
