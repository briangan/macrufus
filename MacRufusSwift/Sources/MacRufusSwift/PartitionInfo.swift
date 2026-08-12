import Foundation

/* The structure that holds info for each partition of a drive.
*/
struct PartitionInfo: Identifiable, Equatable {
  let id: String          // e.g. "disk2"
  var name: String // e.g. "WD_BLACK SN850X 4000GB" from system_profiler
  var size: String
  var mountPoint: String
  var format: String
  var orderOnDrive: Int // 0-based index of the partition on the drive
  var isBootable: Bool
}

struct PartitionMapping: Equatable {
  let driveId: String
  let partitionScheme: String
  let partitions: [PartitionInfo]
}
