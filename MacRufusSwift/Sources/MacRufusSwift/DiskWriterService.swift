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
  func writeDisk(progressHandler: @escaping (Double) -> Void) -> Bool {
    // Assuming DriveInfo is a struct and it's imported from DriveInfo.swift
    let isReady = isReadyToWrite()
    guard isReady else {
        print("Write operation is not ready yet.")
        return false
    }

    self.progress = DiskOperationProgress()
    // Open image file and get its size
    let fileManager = FileManager.default
    guard let imagePath = imageFilePath else {
        print("Image file path is nil.")
        return false
    }
    guard let fileAttributes = try? fileManager.attributesOfItem(atPath: imagePath),
          let fileSize = fileAttributes[.size] as? Int64 else {
        print("Failed to get file size for image file at path \(imagePath).")
        return false
    }
    print("Image file size: \(fileSize) bytes.")
    self.progress.bytesEstimatedToTransfer = 48000000 // TODO: Restore to fileSize

    // Simply non-async run
    self.isWriting = true
    self.runPythonDDTest(progressHandler: { progressUpdate in
        self.progress.bytesTransferred = progressUpdate.bytesTransferred
        self.progress.timeElapsed = progressUpdate.timeElapsed
        self.progress.transferRate = progressUpdate.transferRate
        progressHandler(self.progress.progressPercentage())
        print("Progress: \(self.progress.bytesTransferred) bytes transferred, \(self.progress.timeElapsed) seconds elapsed, \(self.progress.transferRate) kB/s => \(self.progress.progressPercentage())% complete")
      })
    self.isWriting = false

    return true
  }


  //===================================
  // Simulate the dd command output for testing purposes. This function generates a series of progress status lines that mimic what dd would output during a real write operation.
  func runPythonDDTest(progressHandler: @escaping (DiskOperationProgress) -> Void) {
    print("Running Python script to simulate dd command output...")
    print("Log file: \(logURL().path)")

    Task { @MainActor in
        do {
            try await runSubprocess(cmd: "python", args: ["../dd_test.py"], outputHandler: { line in
                if let progressUpdate: DiskOperationProgress = self.parseDDProgressStatus(line) {
                    writeToLogFile(message: "  Progress update: \(progressUpdate.stats())", at: logURL())
                    
                    progressHandler(progressUpdate)
                }
            }, errorHandler: { line in
                print("Error from Python script: \(line)")
            })
            print("Python script completed successfully.")
        } catch {
            print("Error running subprocess: \(error)")
        }
    }
  }


  // This function is called when dd outputs a progress status line. It parses the line and updates the progress bar or other UI elements accordingly.
  // 109051904 bytes (109 MB, 104 MiB) transferred 19.011s, 5736 k
  func parseDDProgressStatus(_ statusLine: String) -> DiskOperationProgress? {
    let pattern: String = #"(\d+) bytes.*transferred\s+(\d+(\.\d+)?)s,\s*([\d\.]+)\s*k"#
    guard let regex: NSRegularExpression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
      return DiskOperationProgress()
    }
    
    let matches = regexMatch(pattern: pattern, in: statusLine)
    // writeToLogFile(message: "| Regex matches for status line '\(statusLine)': \(matches)", at: logURL())
        
    let progress = DiskOperationProgress()
    progress.bytesTransferred = if matches.count > 1, let bytesTransferred = Int64(matches[1]) { bytesTransferred } else { 0 }
    progress.timeElapsed = if matches.count > 2, let timeElapsed = Double(matches[2]) { timeElapsed } else { 0 }
    progress.transferRate = if matches.count > 4, let transferRate = Int64(matches[4]) { transferRate } else { 0 }
    return progress
  }
  /*
  func testRegexMatch(regex) {
    let s = "109051904 bytes (109 MB, 104 MiB) transferred 19.011s, 5736 k"
    let regex = try? NSRegularExpression(
      pattern: #"(\d+) bytes.*transferred\s+(\d+(\.\d+)?)s,\s*([\d\.]+)\s*k"#,
      options: .caseInsensitive
    )

    // https://medium.com/@ck3g/how-to-capture-regex-group-values-in-swift-8bf14b8db6a7
    let title = "Season 1 Episode 3 - When Joey meets Zoey"
    let pattern = "^Season\\s+(\\d+)\\s+Episode\\s+(\\d+)"
    let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    let match = regex?.firstMatch(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count)) 
    if let match = match {
      if let wholeRange = Range(match.range(at: 2), in: title) {
        let wholeMatch = title[wholeRange]
        print("Whole match: \(wholeMatch)")
      }
    }
  }
  */

  func regexMatch(pattern: String, in text: String, options: NSRegularExpression.Options = []) -> [String] { 
    let regex = try!NSRegularExpression(pattern: pattern, options: options)
    let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
    var results : [String] = []
    if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) 
    {
      for i in 0..<match.numberOfRanges {
        if let range = Range(match.range(at: i), in: text) {
          let matchedString = String(text[range])
          results.append(matchedString)
        }
      }
    }
    return results
  }
}
