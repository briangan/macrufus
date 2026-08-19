import Foundation

// MARK: - Model

struct DriveInfo: Identifiable, Equatable {
    var id: String = "" // e.g. "/dev/disk2" or "disk2s1"
    var deviceName: String  // e.g. "WD_BLACK SN850X 4000GB" from system_profiler
    var size: String
    var mountPoint: String // e.g. "/Volumes/MyDrive" or "Not mounted"
    var partitions: [PartitionInfo] = []
    var partitionScheme: String? = nil
    var busProtocol: String
    var isRemovable: Bool
    var isVirtual: Bool = false // Based on value of <key>VirtualOrPhysical</key><string>Physical</string> from diskutil info -plist disk2

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

    /* Running diskutil commands
    */
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
              let allDisksAndPartitions = plist["AllDisksAndPartitions"] as? [[String: Any]]
        else { return [] }

        let devicePartitions : [String : [PartitionInfo]] = parseDevicePartitions(from: allDisksAndPartitions)

        // Step 2: fetch device names from system_profiler in parallel with disk info
        async let deviceNamesTask = deviceNamesByDisk()

        // TODO: Remove debug print
        for (diskId, partitions) in devicePartitions {
            print("Disk \(diskId) has \(partitions.count) partitions: \(partitions.map { $0.id })")
        }

        // Step 3: get info for each disk in parallel
        let deviceNames = await deviceNamesTask
        return try await withThrowingTaskGroup(of: DriveInfo?.self) { group in
            var result: [DriveInfo] = []
            for (diskId, partitions) in devicePartitions {

                group.addTask {
                    let deviceName = deviceNames[diskId]
                    return try await fetchDriveInfo(for: diskId)
                }
            }
            for try await info in group {
                if var info = info {
                    if info.isVirtual { continue } // Skip virtual disks
                    info.partitions = devicePartitions[info.id] ?? []
                    result.append(info) 
                }
            }
            return result.sorted { $0.id < $1.id }
        }
    }

    private static func fetchDriveInfo(for disk: String) async throws -> DriveInfo? {
        let data = try await run(["info", "-plist", disk])
        guard let plist = try PropertyListSerialization
                .propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        let deviceId = plist["DeviceIdentifier"] as? String ?? ""
        let deviceName = plist["MediaName"] as? String ?? deviceId
        let totalBytes = plist["Size"] as? Int ?? 0
        let mountPoint = plist["MountPoint"] as? String ?? ""
        let busProto = plist["BusProtocol"] as? String ?? "Unknown"
        let removable = plist["RemovableMedia"] as? Bool ?? false
        let isVirtual = (plist["VirtualOrPhysical"] as? String ?? "Physical") == "Virtual"

        return DriveInfo(
            id: disk,
            deviceName: deviceName,
            size: formatBytes(totalBytes),
            mountPoint: mountPoint.isEmpty ? "Not mounted" : mountPoint,
            busProtocol: busProto,
            isRemovable: removable,
            isVirtual: isVirtual
        )
    }

    // Function to parse the drives and partitions of the value of top-level AllDisksAndPartitions from the mac_diskutil_list_External.xml sample file
    /*
    Special case: the list of disks might have overlapping disks prepared by Mac diskutil, for example, in APFS schema,
        there could be a "sythesized" disk that contains the partitions of a physical disk while the physical disk itself might also be listed.  
        So need to exclude those.

    ❯ diskutil list external                                        
    /dev/disk4 (external, physical):
    #:                       TYPE NAME                    SIZE       IDENTIFIER
    0:      GUID_partition_scheme                        *4.0 TB     disk4
    1:                        EFI EFI                     209.7 MB   disk4s1
    2:                 Apple_APFS Container disk5         4.0 TB     disk4s2

    /dev/disk5 (synthesized):
    #:                       TYPE NAME                    SIZE       IDENTIFIER
    0:      APFS Container Scheme -                      +4.0 TB     disk5
                                    Physical Store disk4s2
    1:                APFS Volume datahd                  2.9 TB     disk5s1

    In XML plist:

    <dict>
        <key>Content</key>
        <string>GUID_partition_scheme</string>
        <key>DeviceIdentifier</key>
        <string>disk6</string>
        <key>OSInternal</key>
        <false/>
        <key>Partitions</key>
        <array>
            ...
        </array>]
    </dict>

    <div>
        <key>APFSPhysicalStores</key>
        <array>
            <dict>
                <key>DeviceIdentifier</key>
                <string>disk6s2</string>
            </dict>
        </array>
        <key>Content</key>
        <string>Apple_APFS_Container</string>
        <key>DeviceIdentifier</key>
        <string>disk7</string>
        <key>OSInternal</key>
        <false/>
        <key>Partitions</key>
        <array/>
        <key>Size</key>
        <integer>4000577273856</integer>
    </dict>
    */
    private static func parseDevicePartitions(from allDisksAndPartitions: [[String: Any]]) -> [String : [PartitionInfo]] {
        var deviceMap: [String : [PartitionInfo]] = [:]
        for diskDict in allDisksAndPartitions {
            guard let deviceId = diskDict["DeviceIdentifier"] as? String,
                  let sizeBytes = diskDict["Size"] as? Int
            else { continue }

            let partitionArray = diskDict["Partitions"] as? [[String: Any]] ?? []
            var partitions: [PartitionInfo] = []
            for (index, partitionDict) in partitionArray.enumerated() {
                var partitionInfo = parsePartitionsDictionary(partitionDict)
                partitionInfo.orderOnDrive = index
                partitions.append(partitionInfo)
            }

            deviceMap[deviceId] = partitions
        }
        return deviceMap
    }

    /*
        Parses a single partition dictionary for a given partition, not the Array of partitions.
        Expect the dictionary to be like:
        <dict>
            <key>Content</key>
            <string>EFI</string>
            <key>DeviceIdentifier</key>
            <string>disk6s1</string>
            <key>DiskUUID</key>
            <string>A3787473-87D5-4D4F-BA08-54A835212BEA</string>
            <key>Size</key>
            <integer>209715200</integer>
            <key>VolumeName</key>
            <string>EFI</string>
            <key>VolumeUUID</key>
            <string>0E239BC6-F960-3107-89CF-1C97F78BB46B</string>
        </dict>
        <dict>
            <key>CapacityInUse</key>
            <integer>2935269965824</integer>
            <key>DeviceIdentifier</key>
            <string>disk7s1</string>
            <key>DiskUUID</key>
            <string>FBF89EA5-B8AB-422D-A480-5DE42582A76A</string>
            <key>MountPoint</key>
            <string>/Volumes/datahd</string>
            <key>MountedSnapshots</key>
            <array/>
            <key>OSInternal</key>
            <false/>
            <key>Size</key>
            <integer>4000577273856</integer>
            <key>VolumeName</key>
            <string>datahd</string>
            <key>VolumeUUID</key>
            <string>FBF89EA5-B8AB-422D-A480-5DE42582A76A</string>
        </dict>
        @return PartitionInfo without the orderOnDrive set (caller should set it based on the index in the array of partitions)
    */
    private static func parsePartitionsDictionary(_ dict: [String: Any] ) -> PartitionInfo {
        let partitionId = dict["DeviceIdentifier"] as? String ?? ""
        let capacity = dict["Size"] as? Int64 ?? 0
        let capacityInUse = dict["CapacityInUse"] as? Int64 ?? 0
        let mountPoint = dict["MountPoint"] as? String ?? ""
        let format = dict["Content"] as? String ?? ""
        let isBootable = format.lowercased() == "efi"

        return PartitionInfo(
            id: partitionId,
            name: dict["VolumeName"] as? String ?? "",
            capacity: capacity,
            capacityInUse: capacityInUse,
            mountPoint: mountPoint,
            format: format,
            isBootable: isBootable
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
