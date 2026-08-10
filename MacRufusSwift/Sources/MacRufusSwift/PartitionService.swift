import Foundation

final class PartitionService: ObservableObject {
  @Published var partitionMapping: PartitionMapping? = nil
  @Published var partitions: [PartitionInfo] = []
  @Published var isLoading = false
  @Published var errorMessage: String? = nil

  // Expect the drive is blank with no partitions, and create a new partition scheme with partitions.
  func createPartitions() {
    isLoading = true
    errorMessage = nil
  }

  func formatPartition(driveId: String, partitionScheme: String, partition: PartitionInfo) {
    isLoading = true
    errorMessage = nil
  }

  
}