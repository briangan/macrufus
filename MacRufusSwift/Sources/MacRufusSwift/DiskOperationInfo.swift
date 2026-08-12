import Foundation

class DiskOperationProgress: ObservableObject {
  @Published var bytesTransferred: Int64 = 0
  @Published var bytesEstimatedToTransfer: Int64 = 0
  @Published var timeElapsed: Double = 0.0
  @Published var transferRate: Int64 = 0

  func humanizedTransferRate() -> String {
    let rateInKB = Double(transferRate) / 1024.0
    if rateInKB < 1024 {
      return String(format: "%.2f KB/s", rateInKB)
    } else {
      let rateInMB = rateInKB / 1024.0
      return String(format: "%.2f MB/s", rateInMB)
    }
  }

  func estimatedRemainingTime() -> String {
    guard transferRate > 0 else { return "Calculating..." }
    let remainingBytes = bytesEstimatedToTransfer - bytesTransferred
    let remainingSeconds = Double(remainingBytes) / Double(transferRate)
    let minutes = Int(remainingSeconds) / 60
    let seconds = Int(remainingSeconds) % 60
    return String(format: "%02d:%02d remaining", minutes, seconds)
  }

  func progressPercentage() -> Double {
    guard bytesEstimatedToTransfer > 0 else { return 0.0 }
    return (Double(bytesTransferred) / Double(bytesEstimatedToTransfer)) * 100.0
  }
}
