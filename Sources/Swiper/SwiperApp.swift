import SwiftUI
import SwiperCore

@main
struct SwiperApp: App {
    @StateObject private var state = AppState()

    init() { Theme.registerFonts() }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(state: state)
        } label: {
            Image(nsImage: MenuBarIcon.image(paused: state.status == .paused))
        }
        .menuBarExtraStyle(.window)

        Window("Swiper Settings", id: "settings") {
            SettingsView(state: state)
        }
        .windowResizability(.contentSize)
    }
}
