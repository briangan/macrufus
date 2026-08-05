import SwiftUI
import AppKit

// MARK: - Catppuccin Mocha palette

extension Color {
    static let crust      = Color(hex: 0x11111B)
    static let base       = Color(hex: 0x1E1E2E)
    static let mantle     = Color(hex: 0x181825)
    static let surface0   = Color(hex: 0x313244)
    static let surface1   = Color(hex: 0x45475A)
    static let overlay0   = Color(hex: 0x6C7086)
    static let subtext1   = Color(hex: 0xA6ADC8)
    static let text       = Color(hex: 0xCDD6F4)
    static let lavender   = Color(hex: 0xB4BEFE)
    static let mauve      = Color(hex: 0xCBA6F7)
    static let blue       = Color(hex: 0x89B4FA)
    static let green      = Color(hex: 0xA6E3A1)
    static let red        = Color(hex: 0xF38BA8)

    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}

// MARK: - Drive card

struct DriveCardView: View {
    let drive: DriveInfo

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: drive.protocolIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundColor(.mauve)

            VStack(alignment: .leading, spacing: 6) {
                Text(drive.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.text)

                HStack(spacing: 4) {
                    Text("Name:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.subtext1)
                    Text(drive.name)
                        .font(.system(size: 12))
                        .foregroundColor(.overlay0)
                }

                HStack(spacing: 8) {
                    Badge(drive.id)
                    Badge(drive.busProtocol, color: .blue)
                    Badge(drive.mountPoint)
                    if drive.isRemovable { Badge("Removable") }
                }
            }

            Spacer()

            Text(drive.size)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.surface0)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.surface1, lineWidth: 1)
        )
    }
}

// MARK: - Badge

struct Badge: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = .subtext1) {
        self.text  = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color == .subtext1 ? Color.surface1 : Color.surface0)
            .overlay(
                Capsule()
                    .stroke(color == .subtext1 ? Color.clear : color, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

// MARK: - Content view

struct ContentView: View {
    @StateObject private var service = DiskUtilService()
    @State private var selectedDriveID: String? = nil
    @State private var selectedImageURL: URL? = nil

    /// Keep selectedDriveID in sync whenever the drive list changes.
    private func syncSelection() {
        if let id = selectedDriveID, service.drives.contains(where: { $0.id == id }) { return }
        selectedDriveID = service.drives.first?.id
    }

    private var selectedDrive: DriveInfo? {
        service.drives.first { $0.id == selectedDriveID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("MacRufus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.mauve)
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
                            Text("\(drive.name)  ·  \(drive.id)  ·  \(drive.size)")
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .mauve))
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
            .padding(.top, 16)

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
                boldLabel("File System: ")
                // default selection is "NTFS"
                Picker("", selection: .constant("ntfs")) {
                    Text("NTFS").tag("ntfs")
                    Text("FAT32").tag("fat32")
                    Text("exFAT").tag("exfat")
                }

                Spacer(minLength: 20)

                boldLabel("Cluster Size: ")
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

            // Label

        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
        .frame(minWidth: 600, minHeight: 300)
        .background(Color.base.ignoresSafeArea())
        .onAppear { service.refresh() }
        .onChange(of: service.drives) { _ in syncSelection() }
    }
    // end of body

    func browseForImage() {
        let panel = NSOpenPanel()
        panel.title = "Select a disk image"
        panel.allowedContentTypes = [
            .init(filenameExtension: "iso")!,
            .init(filenameExtension: "img")!,
            .init(filenameExtension: "dmg")!,
            .init(filenameExtension: "vhd")!,
            .init(filenameExtension: "vhdx")!,
            .init(filenameExtension: "bin")!,
            .init(filenameExtension: "raw")!,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            selectedImageURL = panel.url
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
}

// MARK: - Button style

struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.base)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color.lavender : Color.mauve)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
