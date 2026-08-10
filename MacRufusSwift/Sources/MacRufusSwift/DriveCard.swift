import SwiftUI

// Array of supported image file extensions in String for the file picker

// MARK: - Drive card

struct DriveCardView: View {
    let drive: DriveInfo

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: drive.protocolIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundColor(.primary)

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