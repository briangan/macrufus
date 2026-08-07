import Foundation

/*
DiskWriterService is a class that handles the writing of an image file to a disk drive. It uses the DiskUtilService library to perform the actual writing operation. The class is designed to be used in a SwiftUI application, and it provides a way to track the progress of the writing operation.
*/
final class DiskWriterService: ObservableObject {
    // ... existing code ...

    // Write a function to check selected drive and image file
    // @return "" if everything is okay, or an error message string if there is an issue
    func checkWriteOperation(drive: DriveInfo, imageFilePath: String) -> String {
        print("Checking write operation for drive \(drive) \nand image file \(imageFilePath)")
        // Check if the drive is not nil and drive.id is not empty
        guard !drive.id.isEmpty else {
            print("Drive is nil or drive.id is empty: \(drive)")
            return "Selected drive is invalid."
        }
        // Check if the drive is removable
        guard drive.isRemovable else {
            print("Drive \(drive.name) is not removable.")
            return "Selected drive is not removable."
        }
        print("Drive \(drive.name) is removable and has id \(drive.id).")

        // Check if imageFilePath is not nil 
        let p : String? = imageFilePath
        guard p != nil else {
            print("imageFilePath is nil")
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

    /* func writeDisk(drive: DriveInfo, imageFilePath: String) {
      // Assuming DriveInfo is a struct and it's imported from DriveInfo.swift
      
      print("Starting write operation from \(imageFilePath) to drive \(drive.name)")
    } */
    
    // ... rest of code ...
}