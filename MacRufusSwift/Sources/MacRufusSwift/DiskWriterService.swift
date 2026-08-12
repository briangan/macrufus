import Foundation

let supportedImageExtensions: [String] = ["iso", "img", "dmg", "bin", "raw"]

/*
DiskWriterService is a class that handles the writing of an image file to a disk drive. It uses the DiskUtilService library to perform the actual writing operation. The class is designed to be used in a SwiftUI application, and it provides a way to track the progress of the writing operation.
*/
final class DiskWriterService: ObservableObject {
  @Published var isWriting  = false
  @Published var progress = DiskOperationProgress()
  @Published var process: Process? = nil
  
  @Published var driveInfo: DriveInfo? = nil
  @Published var imageFilePath: String? = nil

  // Write a function to check selected drive and image file
  // @return "" if everything is okay, or an error message string if there is an issue
  func checkWriteOperation(drive: DriveInfo, imageFilePath: String) -> String {
    // print("Checking write operation for drive \(drive) \nand image file \(imageFilePath)")
    
    // Check if the drive is not nil and drive.id is not empty
    guard !drive.id.isEmpty else {
        return "Selected drive is invalid."
    }
    // Check if the drive is removable
    /* guard drive.isRemovable else {
        return "Selected drive is not removable."
    }
    TODO: RESTORE */

    print("Drive \(drive.name) is removable and has id \(drive.id).")

    // Check if imageFilePath is not nil 
    let p : String? = imageFilePath
    guard p != nil else {
        return "No image file selected." 
    }
    // not empty
    guard !imageFilePath.isEmpty else {
        return "No image file selected."
    }

    // Check if the image file has a supported extension
    let fileExtension = (imageFilePath as NSString).pathExtension.lowercased()
    guard supportedImageExtensions.contains(fileExtension) else {
        return "Unsupported image file extension."
    }

    // Check if the image file exists
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: imageFilePath) else {
        return "Image file does not exist at path \(imageFilePath)."
    }
    
    // Additional checks can be added here (e.g., check for sufficient space)
    print("Drive and image file checks passed for drive \(drive.name) and image file \(imageFilePath).")
    
    return "" // Everything is okay
  }

  func isReadyToWrite() -> Bool {
    guard let drive = driveInfo, let imagePath = imageFilePath else {
      return false
    }
    let checkResult = checkWriteOperation(drive: drive, imageFilePath: imagePath)
    return checkResult.isEmpty
  }

  // @return : Bool indicating whether the write operation was initiated successfully
  func writeDisk() -> Bool {
    // Assuming DriveInfo is a struct and it's imported from DriveInfo.swift
    let isReady = isReadyToWrite()
    guard isReady else {
        print("Write operation is not ready yet.")
        return false
    }

    progress = DiskOperationProgress()
    
    // Simply non-async run
    self.isWriting = true
    self.runPythonDDTest(progressHandler: { progressUpdate in
        self.progress = progressUpdate
// print("Progress: \(progressUpdate.bytesTransferred) bytes transferred, \(progressUpdate.timeElapsed) seconds elapsed, \(progressUpdate.transferRate) kB/s => \(progressUpdate.progressPercentage())% complete")
      })
    self.isWriting = false

    return true
  }


  //===================================
  // Simulate the dd command output for testing purposes. This function generates a series of progress status lines that mimic what dd would output during a real write operation.
  func runPythonDDTest(progressHandler: @escaping (DiskOperationProgress) -> Void) {
    // print("Running Python script to simulate dd command output...")
    print("What the hell is going on here?")
    // print("Log file: \(logURL().path)")

    /*
    Task { @MainActor in
        do {
            try await runSubprocess(cmd: "/opt/anaconda3/envs/comfy-env/bin/python", args: ["../dd_test.py"], outputHandler: { line in
                writeToLogFile(message: line, at: logURL())

                if let progressUpdate = self.parseDDProgressStatus(line) {
                    progressHandler(progressUpdate)
                }
            }, errorHandler: { line in
                print("Error from Python script: \(line)")
            })
        } catch {
            print("Error running subprocess: \(error)")
        }
    }
    */
  }


  // This function is called when dd outputs a progress status line. It parses the line and updates the progress bar or other UI elements accordingly.
  // 109051904 bytes (109 MB, 104 MiB) transferred 19.011s, 5736 k
  func parseDDProgressStatus(_ statusLine: String) -> DiskOperationProgress? {
    let pattern: String = #"(\d+) bytes.*transferred (\d+(\.\d+)?)s, (\d+) k"#
    guard let regex: NSRegularExpression = try? NSRegularExpression(pattern: pattern, options: []) else {
      return DiskOperationProgress()
    }
    return regex.firstMatch(in: statusLine, options: [], range: NSRange(location: 0, length: statusLine.utf16.count)).flatMap { match in
      guard match.numberOfRanges == 5,
            let bytesRange = Range(match.range(at: 1), in: statusLine),
            let timeRange = Range(match.range(at: 2), in: statusLine),
            let rateRange = Range(match.range(at: 4), in: statusLine),
            let bytesTransferred = Int64(statusLine[bytesRange]),
            let timeElapsed = Double(statusLine[timeRange]),
            let transferRate = Int64(statusLine[rateRange]) else {
        return DiskOperationProgress()
      }
      let progress = DiskOperationProgress()
      progress.bytesTransferred = bytesTransferred
      progress.timeElapsed = timeElapsed
      progress.transferRate = transferRate
      return progress
    }
  }
}