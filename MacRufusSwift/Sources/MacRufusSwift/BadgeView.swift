// MARK: - Badge
import SwiftUI

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