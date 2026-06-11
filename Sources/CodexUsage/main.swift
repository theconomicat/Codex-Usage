import AppKit
import CodexUsageCore
import Foundation

if CommandLine.arguments.contains("--print") {
    do {
        let snapshot = try CodexUsageReader().latestSnapshot()
        print(SnapshotFormatter.textSummary(snapshot))
        exit(0)
    } catch {
        fputs("CodexUsage: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let reader = CodexUsageReader()
    private let formatter = SnapshotFormatter()
    private let iconRenderer = StatusIconRenderer()
    private var refreshTimer: Timer?
    private var latestSnapshot: CodexUsageSnapshot?
    private var latestError: Error?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        refresh()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = ""
        button.image = iconRenderer.placeholderImage()
        button.imagePosition = .imageOnly
        button.toolTip = "Codex Usage"
        statusItem.menu = makeMenu()
    }

    @objc private func refresh() {
        let reader = reader
        DispatchQueue.global(qos: .utility).async {
            let result: Result<CodexUsageSnapshot, Error>
            do {
                result = .success(try reader.latestSnapshot())
            } catch {
                result = .failure(error)
            }

            Task { @MainActor [weak self] in
                self?.apply(result)
            }
        }
    }

    private func apply(_ result: Result<CodexUsageSnapshot, Error>) {
        switch result {
        case .success(let snapshot):
            latestSnapshot = snapshot
            latestError = nil
        case .failure(let error):
            latestError = error
        }
        render()
    }

    private func render() {
        if let snapshot = latestSnapshot {
            statusItem.button?.title = ""
            statusItem.button?.image = iconRenderer.image(for: snapshot)
            statusItem.button?.toolTip = formatter.tooltip(snapshot)
        } else {
            statusItem.button?.title = ""
            statusItem.button?.image = iconRenderer.placeholderImage()
            statusItem.button?.toolTip = latestError?.localizedDescription ?? "No Codex usage data found"
        }

        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        if let snapshot = latestSnapshot {
            menu.addItem(withTitle: formatter.menuLine(.fiveHour, snapshot.primary), action: nil, keyEquivalent: "")
            menu.addItem(withTitle: formatter.menuLine(.week, snapshot.secondary), action: nil, keyEquivalent: "")
        } else {
            menu.addItem(withTitle: latestError?.localizedDescription ?? "No usage data found", action: nil, keyEquivalent: "")
        }

        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: AppText.current.refresh, action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let quitItem = NSMenuItem(title: AppText.current.quit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

enum UsageKind {
    case fiveHour
    case week
}

struct AppText {
    let fiveHourMenu: String
    let weekMenu: String
    let remainingPrefix: String
    let refresh: String
    let quit: String
    let resetPrefix: String
    let resetSuffix: String
    let updated: String

    static var current: AppText {
        AppText(
            fiveHourMenu: "5h",
            weekMenu: "1w",
            remainingPrefix: "Codex remaining",
            refresh: "Refresh",
            quit: "Quit Codex-Usage",
            resetPrefix: "reset",
            resetSuffix: "",
            updated: "Updated"
        )
    }
}

final class SnapshotFormatter {
    private let dateFormatter: DateFormatter
    private let text = AppText.current

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
    }

    func menuBarTitle(_ snapshot: CodexUsageSnapshot) -> String {
        "\(text.fiveHourMenu) \(rounded(snapshot.primary.remainingPercent))% · \(text.weekMenu) \(rounded(snapshot.secondary.remainingPercent))%"
    }

    func tooltip(_ snapshot: CodexUsageSnapshot) -> String {
        "\(text.remainingPrefix): \(text.fiveHourMenu) \(rounded(snapshot.primary.remainingPercent))%, \(text.weekMenu) \(rounded(snapshot.secondary.remainingPercent))%"
    }

    func menuLine(_ kind: UsageKind, _ window: UsageWindow) -> String {
        let label = kind == .fiveHour ? text.fiveHourMenu : text.weekMenu
        let reset = window.resetsAt.map { "\(text.resetPrefix) \(compactDuration(until: $0))\(text.resetSuffix.isEmpty ? "" : " \(text.resetSuffix)")" } ?? "\(text.resetPrefix) --"
        return "\(label)     \(rounded(window.remainingPercent))% · \(reset)"
    }

    func shortDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func textSummary(_ snapshot: CodexUsageSnapshot) -> String {
        let formatter = SnapshotFormatter()
        return [
            formatter.menuBarTitle(snapshot),
            formatter.menuLine(.fiveHour, snapshot.primary),
            formatter.menuLine(.week, snapshot.secondary),
            "\(formatter.text.updated) \(formatter.shortDate(snapshot.timestamp))"
        ].joined(separator: "\n")
    }

    private func compactDuration(until date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSinceNow.rounded()))
        let minutes = seconds / 60

        if minutes < 60 {
            return "\(max(1, minutes))m"
        }

        let hours = minutes / 60
        if hours < 48 {
            return "\(hours)h"
        }

        let days = hours / 24
        return "\(days)d"
    }

    private func rounded(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

final class StatusIconRenderer {
    private let sidePadding: CGFloat = 2
    private let ringDiameter: CGFloat = 23
    private let ringLineWidth: CGFloat = 2.3
    private let ringGap: CGFloat = 14

    private var imageSize: NSSize {
        NSSize(
            width: sidePadding * 2 + ringDiameter * 2 + ringGap,
            height: 24
        )
    }

    func image(for snapshot: CodexUsageSnapshot) -> NSImage {
        render(percents: [snapshot.primary.remainingPercent, snapshot.secondary.remainingPercent])
    }

    func placeholderImage() -> NSImage {
        render(percents: [nil, nil])
    }

    private func render(percents: [Double?]) -> NSImage {
        NSImage(size: imageSize, flipped: false) { [self] rect in
            let firstCenterX = sidePadding + ringDiameter / 2
            let secondCenterX = firstCenterX + ringDiameter + ringGap

            let firstText = percents[0].map { String(Int($0.rounded())) } ?? "--"
            self.drawRing(in: rect, centerX: firstCenterX, percent: percents[0] ?? 0, text: firstText)

            let secondText = percents[1].map { String(Int($0.rounded())) } ?? "--"
            self.drawRing(in: rect, centerX: secondCenterX, percent: percents[1] ?? 0, text: secondText)

            return true
        }
    }

    private func drawRing(in rect: NSRect, centerX: CGFloat, percent: Double, text: String) {
        let center = NSPoint(x: centerX, y: rect.midY)
        let radius = ringDiameter / 2 - ringLineWidth / 2

        let background = NSBezierPath()
        background.lineWidth = ringLineWidth
        background.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        NSColor.separatorColor.withAlphaComponent(0.45).setStroke()
        background.stroke()

        let progress = NSBezierPath()
        progress.lineCapStyle = .round
        progress.lineWidth = ringLineWidth
        let clamped = max(0, min(100, percent))
        progress.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: 90,
            endAngle: 90 - CGFloat(clamped / 100 * 360),
            clockwise: true
        )
        color(for: clamped).setStroke()
        progress.stroke()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: text.count > 2 ? 7.2 : 8.2, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        attributed.draw(at: NSPoint(x: center.x - textSize.width / 2, y: center.y - textSize.height / 2 - 0.5))
    }

    private func color(for percent: Double) -> NSColor {
        if percent >= 65 {
            return NSColor(calibratedRed: 0.16, green: 0.80, blue: 0.31, alpha: 0.9)
        }
        if percent >= 35 {
            return NSColor(calibratedRed: 1.00, green: 0.73, blue: 0.18, alpha: 0.9)
        }
        if percent >= 15 {
            return NSColor(calibratedRed: 1.00, green: 0.62, blue: 0.18, alpha: 0.9)
        }
        return NSColor(calibratedRed: 1.00, green: 0.37, blue: 0.34, alpha: 0.9)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
