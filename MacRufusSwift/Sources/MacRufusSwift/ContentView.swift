import SwiftUI
import AppKit
import Security

// MARK: - Content view

struct ContentView: View {
    @StateObject private var service = DiskUtilService()
    @StateObject private var diskWriterService: DiskWriterService = DiskWriterService()
    @State private var selectedDriveID: String? = nil
    @State private var selectedImageURL: URL? = nil
    @State private var hasEnoughToClickWrite: Bool = false
    @State private var progressRatio: Double = 0.0 // 0.0 to 1.0, not percentage
    @State private var progressStatusText: String = ""
    // @State private var progressStatusResult: String = ""
    let IS_TESTING = false // Set to true for testing with a mock sudo script, false for production
    let FAILURE_PASSWORD_PATTERN = try! NSRegularExpression(pattern: "try\\s+again|(?:(password\\s+is\\s+)?(wrong|incorrect|required)(\\s+password)?)", options: .caseInsensitive)

    /// Keep selectedDriveID in sync whenever the drive list changes.
    private func syncSelection() {
        if let id = selectedDriveID, service.drives.contains(where: { $0.id == id }) { return }
        selectedDriveID = service.drives.first?.id
        updateWriteButtonState()
    }

    private var selectedDrive: DriveInfo? {
        service.drives.first { $0.id == selectedDriveID }
    }

    private func updateWriteButtonState() {
        diskWriterService.driveInfo = selectedDrive
        diskWriterService.imageFilePath = selectedImageURL?.path
        let enoughInfo = selectedDrive != nil && selectedImageURL != nil

        print("Is enough info to enable write button? \(enoughInfo)")
        hasEnoughToClickWrite = enoughInfo
        progressStatusText = enoughInfo ? "Ready" : ""
    }
    
    private func clickToWrite() {
        let imagePath = selectedImageURL?.path ?? ""
        let errorMessage: String = diskWriterService.checkWriteOperation(drive: selectedDrive!, imageFilePath: imagePath)
        print("Error message from checkWriteOperation: \(errorMessage)")
        if !errorMessage.isEmpty {
            // Show an alert with the error message
            popupAlert(title: "Error", message: errorMessage)
            
        } else {
            // Proceed with the write operation
            progressStatusText = "Starting..."
            diskWriterService.driveInfo = selectedDrive
            diskWriterService.imageFilePath = imagePath
            let successRun = diskWriterService.writeDisk(progressHandler: { progressPercentage in
                if progressPercentage < 100.0 {
                    progressStatusText = String(format: "%.1f%% complete", progressPercentage)
                } else {
                    progressStatusText = "Complete"
                }
                DispatchQueue.main.async {
                    self.progressRatio = progressPercentage / 100.0
                }
            })
        }
    }

    ///////////////////////////////////////////

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("MacRufus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text("Drive image writer to external drives and USB sticks. Supports ISO, IMG, DMG, and more.")
                    .font(.system(size: 13))
                    .foregroundColor(.overlay0)
            }
            .padding(.vertical, 16)

            // Device header

            headerWithDivider(title: "Device")

            // Device selector row
            HStack(spacing: 12) {
                boldLabel("Select Drive: ")
                
                Picker("", selection: $selectedDriveID) {
                    if service.drives.isEmpty {
                        Text("No external drives found").tag(Optional<String>.none)
                    }
                    ForEach(service.drives) { drive in
                        HStack {
                            Image(systemName: drive.protocolIcon)
                            Text("\(drive.deviceName)  ·  \(drive.id)  ·  \(drive.size)").font(.system(size: 15))
                        }
                        .tag(Optional(drive.id))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .disabled(service.drives.isEmpty || service.isLoading)
                .padding(.trailing, 8)

                Button(action: {
                    service.refresh()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(PillButtonStyle())
                .disabled(service.isLoading)

                if service.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                }

                Spacer()

                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundColor(.overlay0)
            }
            .padding(.bottom, 20)

            // Body – details for selected drive
            if let err = service.errorMessage {
                errorView(err)
            } else if service.drives.isEmpty && !service.isLoading {
                emptyView
            } else if let drive = selectedDrive {
                DriveCardView(drive: drive)
                    .transition(.opacity)
            }

            headerWithDivider(title: "Image")

            // Image selector row
            HStack(spacing: 12) {
                boldLabel("Select Image: ")

                // File label with folder-path tooltip
                Text(selectedImageURL?.lastPathComponent ?? "No image selected")
                    .font(.system(size: 13))
                    .foregroundColor(selectedImageURL == nil ? .overlay0 : .text)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .help(selectedImageURL?.deletingLastPathComponent().path ?? "")

                Button(action: browseForImage) {
                    Label("Browse…", systemImage: "folder")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(PillButtonStyle())
            }
            .padding(.bottom, 16)

            // Format Options header
            headerWithDivider(title: "Format Options")

            // Volume label row
            HStack(spacing: 12) {
                boldLabel("Volume Label: ")
                TextField("Enter volume label", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            // File system, Cluster size
            HStack(spacing: 12) {
                boldLabel("Partition Scheme: ")
                // default selection is "GPT"
                Picker("", selection: .constant("gpt")) {
                    Text("GPT").tag("gpt")
                    Text("MBR").tag("mbr")
                }

                Spacer(minLength: 20)

                boldLabel("File System: ")
                // default selection is "NTFS"
                Picker("", selection: .constant("ntfs")) {
                    Text("NTFS").tag("ntfs")
                    Text("FAT32").tag("fat32")
                    Text("exFAT").tag("exfat")
                }

                Spacer(minLength: 20)

                boldLabel("Block Size: ")
                Picker("", selection: .constant("4096")) {
                    Text("4096 bytes (Default)").tag("4096")
                    Text("8192 bytes").tag("8192")
                    Text("16 kilobytes").tag("16384")
                    Text("32 kilobytes").tag("32768")
                    Text("64 kilobytes").tag("65536")
                }
            }
            .padding(.vertical, 8)

            // Status
            headerWithDivider(title: "Status")

            // Process bar with status text
            HStack(spacing: 10) {
                ProgressView(value: progressRatio, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                Spacer()
                Text(progressStatusText)
                    .font(.system(size: 12))
                    .foregroundColor(.overlay0)
            }

            Divider()
            .padding(.vertical, 12)
            
            // Write button
            HStack(spacing: 12) {
                Spacer()

                Button(action: {
                    self.disabled(!hasEnoughToClickWrite)
                    if hasEnoughToClickWrite {
                        print("| hasFullDiskAccess: \(hasFullDiskAccess())")
                        print("| hasAccessToRunDD: \(hasAccessToRunDD())")
                        print("| hasSudoAccess: \(hasSudoAccess())")
                        if !hasFullDiskAccess() {
                            requestFullDiskAccess()
                        } 
                        else if !hasAccessToRunDD() {
                            // popupAlert(title: "Access Denied", message: "This application does not have permission to run the 'dd' command. Please check your system settings.")
                            requestSudoAccess()
                        }
                        else if !hasSudoAccess() {
                            self.progressStatusText = "Request access"
                            requestSudoAccess()
                        }
                        else {
                            clickToWrite()
                        }
                    }
                }) {
                    Label(diskWriterService.isWriting ? "Writing…" : "Write", systemImage: "externaldrive.fill.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                        .opacity(hasEnoughToClickWrite ? 1.0 : 0.5)
                }
                .buttonStyle(PillButtonStyle(isSecondary: true))
                .disabled(!hasEnoughToClickWrite || diskWriterService.isWriting)
                
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
        .frame(minWidth: 600, minHeight: 340)
        .background(Color.base.ignoresSafeArea())
        .onAppear { 
            service.refresh()
            print("hasFullDiskAccess: \(hasFullDiskAccess())")
            print("hasAccessToRunDD: \(hasAccessToRunDD())")
        }
        .onChange(of: service.drives) { _ in syncSelection() }
    }
    // end of body

    func browseForImage() {
        let panel = NSOpenPanel()
        panel.title = "Select a disk image"
        panel.allowedContentTypes = supportedImageExtensions.compactMap { .init(filenameExtension: $0) }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            selectedImageURL = panel.url
            diskWriterService.imageFilePath = selectedImageURL?.path

            updateWriteButtonState()
        }
    }

    var statusText: String {        if service.isLoading { return "Scanning…" }
        let n = service.drives.count
        if n == 0 { return "No external drives found." }
        return "\(n) drive\(n != 1 ? "s" : "") found."
    }

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.overlay0)
            Text("No external drives detected.")
                .font(.system(size: 15))
                .foregroundColor(.overlay0)
            Text("Plug in a USB drive and click Refresh.")
                .font(.system(size: 12))
                .foregroundColor(.overlay0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Failed to read drive information.")
                .font(.system(size: 15))
                .foregroundColor(.text)
            Text(msg)
                .font(.system(size: 12))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /* Look: 
    Device --------------------------------------
    */
    func headerWithDivider(title: String) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.subtext1)
                .padding(.trailing, 4)

            VStack(alignment: .center, spacing: 0) {
                Divider()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    func boldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.subtext1)
            .padding(.trailing, 4)
    }

    func popupAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // If password is empty, would be non-interactive check for sudo access.  If password is provided, would be interactive prompt for sudo access.
    // Only for checking and setting the sudo performission for following sudo commands, but not executing anything else.
    func makeSudoAccessProcess(shouldPrompt: Bool) -> Process {
        let task = Process()
        // ["-S", "true"] Interactive check with password | ["-n", "true"] // Non-interactive check
        if IS_TESTING {
            task.launchPath = "/bin/bash"
            task.arguments = ["/Users/brian/Downloads/dev/macrufus/MacRufusSwift/tudo.sh", shouldPrompt ? "-S" : "-n", "true"] 
        } else {
            task.launchPath = "/usr/bin/sudo"
            task.arguments = [shouldPrompt ? "-S" : "-n", "true"]
        }
        task.standardOutput = Pipe()
        task.standardInput = Pipe()
        return task
    }

    func hasSudoAccess() -> Bool {
        let task = makeSudoAccessProcess(shouldPrompt: false)
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Error checking system authorization: \(error)")
            return false
        }
    }

    func hasAccessToRunDD() -> Bool {
        let task = Process()
        task.launchPath = "/bin/dd"
        task.arguments = ["if=/dev/null", "of=/dev/null", "bs=1m"]
        task.standardOutput = Pipe()
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            // print out pipe output for debugging
            if task.terminationStatus > 0 {
                print("| hasAccessToRunDD terminationStatus: \(task.terminationStatus)")
                /* 
                if let errorData = (task.standardError as? Pipe)?.fileHandleForReading.readDataToEndOfFile(),
                   let errorString = String(data: errorData, encoding: .utf8) {
                    print("| dd error output: \(errorString)")
                }
                */
            }
            return task.terminationStatus == 0
        } catch {
            print("Error checking access to run dd: \(error)")
            return false
        }
    }

    // Check if this application has Full Disk Access permission
    func hasFullDiskAccess() -> Bool {
        return FullDiskAccess.isGranted
    }

    func requestFullDiskAccess() {
        /*
        let alert = NSAlert()
        alert.messageText = "Full Disk Access Required"
        alert.informativeText = "This application requires Full Disk Access to write to external drives. Please grant permission in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open the Security & Privacy preferences pane
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
        } */
        FullDiskAccess.promptIfNotGranted(
            title: "Enable Full Disk Access for MacRufus",
            message: "MacRufus requires Full Disk Access to write to external drives.",
            settingsButtonTitle: "Open Settings",
            skipButtonTitle: "Later",
            canBeSuppressed: false, // `true` will display a "Do not ask again." checkbox and honor it
            icon: nil
        )
    }

    func requestSudoAccess() -> Bool {
        
        var hasAccess : Bool = false
        var stillPrompting : Bool = true
        var trialCount : Int = 0
        
        // Attempt to run a command with sudo to verify access
        print("...Checking sudo access with provided password...")
        
        var isFailure = false

        // Run once, and script might continuously prompt if password is incorrect, until user cancels or max attempts reached
        let task = makeSudoAccessProcess(shouldPrompt: true)
        let outPipe = task.standardOutput as! Pipe
        let outHandle = outPipe.fileHandleForReading
        
        
        while stillPrompting {
            let alert = NSAlert()
            alert.messageText = "Administrator Access Required"
            alert.informativeText = "Requires admin access to write to external drives. Please enter your password."
            alert.alertStyle = .warning
            
            // add a text field for password input
            let passwordField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            // Check return key press to trigger the OK button
            alert.accessoryView = passwordField

            // add a label to display status of sudo access check
            let statusLabel = NSTextField(labelWithString: "")
            statusLabel.textColor = .red
            statusLabel.font = NSFont.systemFont(ofSize: 12)
            alert.accessoryView?.addSubview(statusLabel)
            
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "OK")
            
            if isFailure {
                statusLabel.stringValue = "Incorrect password. Please try again."
            } else {
                statusLabel.stringValue = ""
            }
            alert.runModal()

            // Check if OK is clicked and password is entered
            // alert passwordField is the first subview of the accessoryView

            if alert.buttons[1].state == .on && !passwordField.stringValue.isEmpty {
                do {
                    print(". given password: \(passwordField.stringValue) and is outHandle.readabilityHandler nil ? \(outHandle.readabilityHandler == nil)")

                    if let inputPipe = task.standardInput as? Pipe {
                        let passwordData = (passwordField.stringValue + "\n").data(using: .utf8)!
                        inputPipe.fileHandleForWriting.write(passwordData)
                    }
 
                    // Called whenever there's data available
                    outHandle.readabilityHandler = { handle in
                        let data = handle.availableData
                        guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else {
                            return
                        }
                        
                        let range = NSRange(location: 0, length: chunk.utf16.count)
                        isFailure = FAILURE_PASSWORD_PATTERN.firstMatch(in: chunk, options: [], range: range) != nil
                        statusLabel.stringValue = chunk.trimmingCharacters(in: .whitespacesAndNewlines)

                        print("| output chunk (failed? \(isFailure)): \(chunk)")
                        if isFailure {
                            // If failure detected, while it keeps prompting try again, ask user to re-enter password
                            stillPrompting = true
                            progressStatusText = "Incorrect password.  Try again."
                        }
                    }
                    if trialCount == 0 {
                        print("Starting sudo access check with prompt ----------------------------")
                        try task.run()
                        // task.waitUntilExit()
                        trialCount = 1
                        print("Finished call to prompt sudo access ----------------------------")
                    }
                    
                    hasAccess = task.terminationStatus == 0 && !isFailure
                    print("Sudo access checked after prompt.  terminationStatus: \(task.terminationStatus), hasAccess: \(hasAccess)")
                } catch {
                    print("Error checking system authorization: \(error)")
                    hasAccess = false
                }
                stillPrompting = false // exit the loop after checking
            } // if button
            trialCount += 1
            print("* Trial \(trialCount) completed.  hasAccess: \(hasAccess)")
            if trialCount > 3 {
                print("Maximum attempts reached. Exiting sudo access prompt.")
                stillPrompting = false
            }
        }

        // statusLabel.stringValue = hasAccess ? "Sudo access granted." : "Sudo access denied."
        print("Sudo access checked after prompt. Status: \(hasAccess)")
        return hasAccess
    }
} // ContentView


