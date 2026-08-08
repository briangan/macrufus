import SwiftUI

// MARK: - Catppuccin Mocha palette

extension Color {
  static let crust: Color      = Color(hex: 0x11111B)
  static let base       = Color(hex: 0x1E1E2E)
  static let mantle     = Color(hex: 0x181825)
  static let surface0   = Color(hex: 0x313244)
  static let surface1   = Color(hex: 0x45475A)
  static let overlay0   = Color(hex: 0x6C7086)
  static let subtext1   = Color(hex: 0xA6ADC8)
  static let text       = Color(hex: 0xCDD6F4)
  static let primary    = Color(hex: 0x00AAFF) // aqua
  static let primaryFocused = Color(hex: 0x007ACC) // darker variant of primary
  static let secondary = Color(hex: 0xD3D3D3) // light gray
  static let secondaryFocused = Color(hex: 0xA9A9A9) // darker variant of secondary
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

// MARK: - Button style

struct PillButtonStyle: ButtonStyle {
  @State var isSecondary: Bool = false

  init(isSecondary: Bool = false,) {
    self.isSecondary = isSecondary
  }

  func makeBody(configuration: Configuration) -> some View {
    var backgroundColor: Color {
      if isSecondary {
        return configuration.isPressed ? Color.secondaryFocused : Color.secondary
      } else {
        return configuration.isPressed ? Color.primaryFocused : Color.primary
      }
    }

    configuration.label
      .foregroundColor(.base)
      .padding(.horizontal, 18)
      .padding(.vertical, 8)
      .background(backgroundColor)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}


struct RoundedAndShadowButton<V>:View where V:View {
  let label:V
  let action: () -> Void
  init(label: V, action: @escaping () -> Void) {
      self.label = label
      self.action = action
  }
  var body: some View {
      Button {
          action()
      } label: {
          label
              .foregroundColor(.white)
              .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
              .background(
                  RoundedRectangle(cornerRadius: 10)
                      .foregroundColor(.blue)
                  )
              .compositingGroup()
              .shadow(radius: 5,x:0,y:3)
              .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
  }
}