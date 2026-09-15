import Foundation

/* The structure that holds info for each partition of a drive.
*/
struct PartitionInfo: Identifiable, Equatable {
  let id: String          // e.g. "disk2"
  var name: String // e.g. "WD_BLACK SN850X 4000GB" from system_profiler
  var capacity: Int64 // in bytes
  var capacityInUse: Int64 // in bytes
  var mountPoint: String
  var format: String
  var orderOnDrive: Int = 0 // 0-based index of the partition on the drive
  var isBootable: Bool
}

// Dummy PartitionInfo for testing purposes
let dummyPartitionInfo: PartitionInfo = PartitionInfo(id: "null", name: "Test Partition", capacity: 1000000, capacityInUse: 0, mountPoint: "/Volumes/TestPartition", format: "APFS", orderOnDrive: 0, isBootable: false)

struct PartitionMapping: Equatable {
  let driveId: String
  let partitionScheme: String
  let partitions: [PartitionInfo]
}
