import Foundation

/// Per-user vocabulary mapping that rewrites transcripts before they're pasted.
///
/// Each entry maps a phrase the model is likely to mishear ("you attend") to
/// the correct rendering ("uAttend"). Replacement is case-insensitive and
/// applies longest-pattern-first so "you attend cloud" wins over "you attend".
///
/// Persists to `~/Library/Application Support/Starling/corrections.json`.
/// On first launch the file is seeded with Workwell defaults.
@MainActor
final class Corrections: ObservableObject {
    struct Entry: Identifiable, Equatable {
        let id: UUID
        var heard: String
        var pastesAs: String

        init(id: UUID = UUID(), heard: String, pastesAs: String) {
            self.id = id
            self.heard = heard
            self.pastesAs = pastesAs
        }
    }

    @Published var entries: [Entry] = [] {
        didSet { scheduleSave() }
    }

    private let url: URL
    private var saveTask: DispatchWorkItem?

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Starling", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("corrections.json")
        load()
    }

    /// Apply replacements to `text`. Safe to call repeatedly.
    func apply(_ text: String) -> String {
        // Sort longest pattern first so multi-word phrases match before their
        // shorter prefixes (e.g. "you attend cloud" before "you attend").
        let sorted = entries.sorted { $0.heard.count > $1.heard.count }
        var result = text
        for entry in sorted {
            let pattern = entry.heard.trimmingCharacters(in: .whitespacesAndNewlines)
            let replacement = entry.pastesAs.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !pattern.isEmpty, !replacement.isEmpty else { continue }
            guard let regex = try? NSRegularExpression(
                pattern: NSRegularExpression.escapedPattern(for: pattern),
                options: .caseInsensitive
            ) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: NSRegularExpression.escapedTemplate(for: replacement)
            )
        }
        return result
    }

    func addBlank() {
        entries.append(Entry(heard: "", pastesAs: ""))
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: url.path) else {
            entries = Self.defaultEntries
            persist()
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: String] ?? [:]
            entries = dict
                .map { Entry(heard: $0.key, pastesAs: $0.value) }
                .sorted { $0.heard < $1.heard }
        } catch {
            fputs("corrections load error: \(error)\n", stderr)
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.persist() }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: task)
    }

    private func persist() {
        var dict: [String: String] = [:]
        for entry in entries {
            let key = entry.heard.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = entry.pastesAs.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty && !value.isEmpty { dict[key] = value }
        }
        do {
            let data = try JSONSerialization.data(
                withJSONObject: dict,
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: url, options: .atomic)
        } catch {
            fputs("corrections persist error: \(error)\n", stderr)
        }
    }

    private static let defaultEntries: [Entry] = [
        ("work well", "Workwell"),
        ("work well technologies", "Workwell Technologies"),
        ("workwell tech", "Workwell Technologies"),
        ("you attend", "uAttend"),
        ("u attend", "uAttend"),
        ("you attend cloud", "uAttend Cloud"),
        ("you attend payroll", "uAttend Payroll"),
        ("you attend scheduling", "uAttend Scheduling"),
        ("you attend staffing", "uAttend Staffing"),
        ("you attend mobile", "uAttend Mobile"),
        ("you punch", "uPunch"),
        ("u punch", "uPunch"),
        ("you accept", "uAccept"),
        ("u accept", "uAccept"),
        ("cloud punch", "CloudPunch"),
        ("pro punch", "ProPunch"),
        ("bio look", "BioLook"),
        ("bio touch", "BioTouch"),
        ("acro print", "Acroprint"),
        ("polar is payroll", "Polaris Payroll"),
        ("punch to pay", "Punch-to-Pay"),
        ("pendulum product suite", "Pendulum Product Suite"),
        ("master console", "Master Console"),
        ("client portal", "Client Portal"),
        ("employee portal", "Employee Portal"),
        ("citadel time cloud", "Citadel Time Cloud"),
        ("citadel time clock", "Citadel Time Clock"),
    ].map { Entry(heard: $0.0, pastesAs: $0.1) }
}
