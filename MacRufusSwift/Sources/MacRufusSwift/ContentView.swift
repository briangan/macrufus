import SwiftUI
import AppKit


// MARK: - Content view

struct ContentView: View {
    @StateObject private var service = DiskUtilService()
    @StateObject private var diskWriterService: DiskWriterService = DiskWriterService()
    @State private var selectedDriveID: String? = nil
    @State private var selectedImageURL: URL? = nil
    @State private var hasEnoughToClickWrite: Bool = false

    // @State private var progressStatusText: String = ""
    // @State private var progressStatusResult: String = ""

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
            diskWriterService.driveInfo = selectedDrive
            diskWriterService.imageFilePath = imagePath
            diskWriterService.writeDisk()
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
                            Text("\(drive.name)  ·  \(drive.id)  ·  \(drive.size)").font(.system(size: 15))
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
                ProgressView(value: 0.0, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                Spacer()
                Text("Ready")
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
                        clickToWrite()
                    }
                }) {
                    Label(diskWriterService.isWriting ? "Writing…" : "Write", systemImage: "externaldrive.fill.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
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
} // ContentView


