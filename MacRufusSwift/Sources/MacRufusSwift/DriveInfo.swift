import Foundation

// MARK: - Model

struct DriveInfo: Identifiable, Equatable {
    var id: String = "" // e.g. "disk2"
    var name: String
    var deviceName: String  // e.g. "WD_BLACK SN850X 4000GB" from system_profiler
    var size: String
    var mountPoint: String
    var busProtocol: String
    var isRemovable: Bool

    var protocolIcon: String {
        let p = busProtocol.lowercased()
        if p.contains("usb")                      { return "cable.connector" }
        if p.contains("thunderbolt")              { return "bolt.fill" }
        if p.contains("pci") || p.contains("nvm") { return "bolt.fill" }
        if p.contains("apple fabric")             { return "internaldrive.fill" }
        if p.contains("sd")                       { return "camera.fill" }
        return "externaldrive.fill"
    }
}

// MARK: - Service

final class DiskUtilService: ObservableObject {
    @Published var drives: [DriveInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func refresh() {
        isLoading = true
        errorMessage = nil

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            do {
                let result = try await Self.loadDrives()

                print("Loaded count of drives: \(result.count)") // TODO: Remove debug print
                
                await MainActor.run {
                    self.drives = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Private helpers

    private static func run(_ args: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
            proc.arguments = args
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                cont.resume(returning: data)
            }
            do {
                try proc.run()
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    /// Run `system_profiler SPStorageDataType -json` and return the raw Data.
    private static func runSystemProfiler() async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            proc.arguments = ["SPStorageDataType", "-json"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                cont.resume(returning: data)
            }
            do {
                try proc.run()
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    /// Parse `system_profiler SPStorageDataType -json` and return a mapping
    /// from top-level disk identifier (e.g. "disk7") → device name
    /// (e.g. "PSSD T7 Shield") taken from the nested `physical_drive.device_name`.
    static func deviceNamesByDisk() async -> [String: String] {
        guard let data = try? await runSystemProfiler(),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let volumes = json["SPStorageDataType"] as? [[String: Any]]
        else { return [:] }

        var result: [String: String] = [:]
        for volume in volumes {
            guard let bsdName = volume["bsd_name"] as? String,
                  let physDrive = volume["physical_drive"] as? [String: Any],
                  let devName = physDrive["device_name"] as? String
            else { continue }

            // Extract top-level disk id: "disk7s1" → "disk7"
            let diskId = bsdName.replacingOccurrences(
                of: #"s\d+.*$"#, with: "", options: .regularExpression)
            if result[diskId] == nil {
                result[diskId] = devName
            }
        }
        return result
    }

    private static func loadDrives() async throws -> [DriveInfo] {
        // Step 1: list external disks
        let listData = try await run(["list", "-plist", "external"])
        guard let plist = try PropertyListSerialization
                .propertyList(from: listData, format: nil) as? [String: Any],
              let allDisks = plist["AllDisks"] as? [String]
        else { return [] }

        // Only top-level physical disk identifiers: "disk4", "disk5", etc.
        // Exclude partitions like "disk4s1", "disk4s2"
        let topLevel = allDisks.filter { $0.range(of: #"^disk\d+$"#, options: .regularExpression) != nil }

        // Step 2: fetch device names from system_profiler in parallel with disk info
        async let deviceNamesTask = deviceNamesByDisk()

        // Step 3: get info for each disk in parallel
        let deviceNames = await deviceNamesTask
        return try await withThrowingTaskGroup(of: DriveInfo?.self) { group in
            for disk in topLevel {
                group.addTask { try await Self.driveInfo(for: disk, deviceName: deviceNames[disk]) }
            }
            var result: [DriveInfo] = []
            for try await info in group {
                if let info { result.append(info) }
            }
            return result.sorted { $0.id < $1.id }
        }
    }

    private static func driveInfo(for disk: String, deviceName: String? = nil) async throws -> DriveInfo? {
        let data = try await run(["info", "-plist", disk])
        guard let plist = try PropertyListSerialization
                .propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        let name       = (plist["VolumeName"] as? String)
                      ?? (plist["MediaName"]  as? String)
                      ?? disk
        let totalBytes = plist["TotalSize"] as? Int ?? 0
        let mountPoint = (plist["MountPoint"] as? String) ?? ""
        let busProto   = (plist["BusProtocol"] as? String) ?? "Unknown"
        let removable  = plist["RemovableMedia"] as? Bool ?? false

        // Skip synthesized/virtual disks (APFS containers) and disk images
        let virtualOrPhysical = plist["VirtualOrPhysical"] as? String ?? ""
        let deviceProtocol    = plist["DeviceProtocol"]    as? String ?? ""
        guard virtualOrPhysical != "Virtual",
              deviceProtocol != "Disk Image"
        else { return nil }

        return DriveInfo(
            id: disk,
            name: name,
            deviceName: deviceName ?? name,
            size: formatBytes(totalBytes),
            mountPoint: mountPoint.isEmpty ? "Not mounted" : mountPoint,
            busProtocol: busProto,
            isRemovable: removable
        )
    }

    private static func formatBytes(_ bytes: Int) -> String {
        guard bytes > 0 else { return "Unknown" }
        let units = ["B", "KB", "MB", "GB", "TB"]
        let k = 1000.0
        var value = Double(bytes)
        var index = 0
        while value >= k && index < units.count - 1 {
            value /= k
            index += 1
        }
        return String(format: "%.1f %@", value, units[index])
    }
}
