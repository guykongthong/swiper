import CoreText
import SwiftUI
import SwiperCore

enum Theme {
    static let navy = Color(red: 0x1e/255, green: 0x33/255, blue: 0x54/255)
    static let navyHover = Color(red: 0x2a/255, green: 0x45/255, blue: 0x70/255)
    static let paper = Color(red: 0xf8/255, green: 0xf6/255, blue: 0xf0/255)
    static let card = Color(red: 0xff/255, green: 0xfd/255, blue: 0xf8/255)
    static let line = Color(red: 0xe6/255, green: 0xe1/255, blue: 0xd6/255)
    static let muted = Color(red: 0x5d/255, green: 0x64/255, blue: 0x70/255)
    static let onNavy = Color(red: 0xdf/255, green: 0xe5/255, blue: 0xee/255)
    static let green = Color(red: 0x5c/255, green: 0xc9/255, blue: 0x8a/255)
    static let grey = Color(red: 0xa7/255, green: 0xb0/255, blue: 0xbd/255)
    static let amber = Color(red: 0xf0/255, green: 0xb8/255, blue: 0x4a/255)
    static let red = Color(red: 0xef/255, green: 0x85/255, blue: 0x77/255)
    static let warnBg = Color(red: 0xfb/255, green: 0xf0/255, blue: 0xd9/255)
    static let warnLine = Color(red: 0xec/255, green: 0xd2/255, blue: 0x9b/255)
    static let warnText = Color(red: 0x6e/255, green: 0x4a/255, blue: 0x0c/255)
    static let errBg = Color(red: 0xf9/255, green: 0xe4/255, blue: 0xdf/255)
    static let errLine = Color(red: 0xe9/255, green: 0xb7/255, blue: 0xad/255)
    static let errText = Color(red: 0x7f/255, green: 0x2a/255, blue: 0x1f/255)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }

    /// Registers the bundled Inter font so it works even if the Info.plist font path is missed.
    static func registerFonts() {
        guard let url = Bundle.main.url(forResource: "Inter", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func dotColor(for status: AppStatus) -> Color {
        switch status {
        case .active: return green
        case .paused: return grey
        case .needsPermission: return amber
        case .gestureNotWorking: return red
        }
    }

    static func label(for status: AppStatus) -> String {
        switch status {
        case .active: return "Active"
        case .paused: return "Paused"
        case .needsPermission: return "Needs permission"
        case .gestureNotWorking: return "Gesture not working"
        }
    }
}

struct NavyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(12.5, .medium))
            .foregroundStyle(Theme.paper)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(configuration.isPressed ? Theme.navyHover : Theme.navy, in: RoundedRectangle(cornerRadius: 7))
    }
}

struct SoftButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(12.5))
            .foregroundStyle(Theme.navy)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(red: 0.84, green: 0.82, blue: 0.76)))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct Banner: View {
    enum Kind { case warning, error }
    let kind: Kind
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        let text = kind == .warning ? Theme.warnText : Theme.errText
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(13.5, .semibold))
            Text(message).font(Theme.font(12)).fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(NavyButton())
            }
        }
        .foregroundStyle(text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(kind == .warning ? Theme.warnBg : Theme.errBg, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(kind == .warning ? Theme.warnLine : Theme.errLine))
    }
}
