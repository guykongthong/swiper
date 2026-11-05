import SwiftUI
import SwiperCore

struct SettingsView: View {
    @ObservedObject var state: AppState

    private var settings: Binding<SettingsModel> { Binding(get: { state.store.settings }, set: { state.store.settings = $0 }) }
    private var granted: Bool { state.permission.isGranted }

    var body: some View {
        let status = state.status
        VStack(spacing: 0) {
            header(status)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    permissionSection
                    gestureSection.opacity(granted ? 1 : 0.5).disabled(!granted)
                    card { toggleRow }
                    compatibilitySection(status)
                    footer
                }
                .padding(.horizontal, 22).padding(.vertical, 20)
            }
        }
        .frame(width: 480, height: 640)
        .background(Theme.paper)
        .foregroundStyle(Theme.navy)
    }

    private func header(_ status: AppStatus) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Swiper Settings").font(Theme.font(20, .semibold))
                Text("Swipe between desktops with a two-button mouse.").font(Theme.font(12.5)).foregroundStyle(Color(red: 0.81, green: 0.84, blue: 0.89))
            }
            Spacer()
            HStack(spacing: 7) {
                Circle().fill(Theme.dotColor(for: status)).frame(width: 8, height: 8)
                Text(Theme.label(for: status)).font(Theme.font(12.5)).foregroundStyle(Theme.onNavy)
            }
        }
        .foregroundStyle(Theme.paper)
        .padding(.horizontal, 22).padding(.vertical, 20)
        .background(Theme.navy)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted).padding(.leading, 4)
            content()
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))
    }

    private var permissionSection: some View {
        section("Permission") {
            if granted {
                card {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Accessibility").font(Theme.font(13.5, .medium))
                            HStack(spacing: 6) {
                                Circle().fill(Color(red: 0.25, green: 0.68, blue: 0.42)).frame(width: 7, height: 7)
                                Text("Granted").font(Theme.font(12)).foregroundStyle(Color(red: 0.18, green: 0.44, blue: 0.27))
                            }
                        }
                        Spacer()
                        Button("Open System Settings") { state.openSystemSettingsAccessibility() }.buttonStyle(SoftButton())
                    }.padding(16)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Accessibility").font(Theme.font(13.5, .medium)).foregroundStyle(Theme.navy)
                            Text("Not granted").font(Theme.font(12, .semibold))
                        }
                        Spacer()
                        Button("Open System Settings") { state.openSystemSettingsAccessibility() }.buttonStyle(NavyButton())
                    }
                    Text("In Privacy & Security → Accessibility, switch on Swiper. This window updates on its own once it's allowed.")
                        .font(Theme.font(12)).fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Theme.warnText)
                .padding(16)
                .background(Theme.warnBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.warnLine))
            }
        }
    }

    private var gestureSection: some View {
        section(granted ? "Gesture" : "Gesture · available after permission is granted") {
            card {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Swipe sensitivity").font(Theme.font(13.5, .medium))
                            Spacer()
                            Text(SettingsModel.sensitivityLabel(settings.wrappedValue.sensitivity)).font(Theme.font(12.5, .semibold))
                        }
                        Slider(value: Binding(get: { Double(settings.wrappedValue.sensitivity) },
                                              set: { settings.wrappedValue.sensitivity = Int($0) }),
                               in: 1...5, step: 1).tint(Theme.navy)
                        HStack { Text("Slower"); Spacer(); Text("Faster") }.font(Theme.font(11.5)).foregroundStyle(Theme.muted)
                    }.padding(16)
                    Divider().overlay(Theme.line).padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Click delay").font(Theme.font(13.5, .medium))
                            Spacer()
                            Text("\(settings.wrappedValue.clickDelayMs) ms").font(Theme.font(12.5, .semibold))
                                .foregroundStyle(settings.wrappedValue.isClickDelayLow ? Theme.warnText : Theme.navy)
                        }
                        Slider(value: Binding(get: { Double(settings.wrappedValue.clickDelayMs) },
                                              set: { settings.wrappedValue.clickDelayMs = Int($0) }),
                               in: 30...50, step: 1).tint(settings.wrappedValue.isClickDelayLow ? Color(red: 0.85, green: 0.6, blue: 0.17) : Theme.navy)
                        HStack { Text("30 ms"); Spacer(); Text("50 ms") }.font(Theme.font(11.5)).foregroundStyle(Theme.muted)
                        Text("How long a click waits to see if you are starting a swipe.")
                            .font(Theme.font(12)).foregroundStyle(Theme.muted)
                        if settings.wrappedValue.isClickDelayLow {
                            HStack(alignment: .top, spacing: 10) {
                                Circle().fill(Color(red: 0.85, green: 0.6, blue: 0.17)).frame(width: 7, height: 7).padding(.top, 5)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("A short delay can cause mistakes").font(Theme.font(12.5, .semibold))
                                    Text("Swipes may feel jittery, and a swipe may register as an accidental click. 40 ms works well for most mice.")
                                        .font(Theme.font(12)).fixedSize(horizontal: false, vertical: true)
                                    Button("Reset to 40 ms") { settings.wrappedValue.clickDelayMs = 40 }.buttonStyle(SoftButton())
                                }
                            }
                            .foregroundStyle(Theme.warnText)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(Theme.warnBg, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.warnLine))
                        }
                    }.padding(16)
                    Divider().overlay(Theme.line).padding(.horizontal, 16)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Swipe direction").font(Theme.font(13.5, .medium))
                            Text("Follows your system's natural scrolling setting").font(Theme.font(12)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Button("System Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.Mouse-Settings.extension") { NSWorkspace.shared.open(url) }
                        }.buttonStyle(.link).font(Theme.font(12.5))
                    }.padding(16)
                }
            }
        }
    }

    private var toggleRow: some View {
        HStack {
            Text("Launch at login").font(Theme.font(13.5, .medium))
            Spacer()
            Toggle("", isOn: Binding(get: { settings.wrappedValue.launchAtLogin }, set: { settings.wrappedValue.launchAtLogin = $0 }))
                .labelsHidden().toggleStyle(.switch).tint(Theme.navy)
        }.padding(16)
    }

    private func compatibilitySection(_ status: AppStatus) -> some View {
        let result = state.compatibilityResult
        let version = SystemInfo.currentVersion()
        let testedText = testedVersions.isEmpty ? "Not verified yet" : testedVersions.map { "macOS \($0.major).\($0.minor)" }.joined(separator: ", ")
        return section("Compatibility") {
            card {
                VStack(alignment: .leading, spacing: 12) {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                        GridRow { Text("Tested on").foregroundStyle(Theme.muted); Text(testedText) }
                        GridRow { Text("Your Mac").foregroundStyle(Theme.muted); Text("macOS \(version.major).\(version.minor)").fontWeight(.semibold) }
                    }.font(Theme.font(12.5))
                    HStack(spacing: 8) {
                        Circle().fill(result == .tested ? Color(red: 0.25, green: 0.68, blue: 0.42) : Color(red: 0.85, green: 0.6, blue: 0.17)).frame(width: 7, height: 7)
                        Text(noteText(result, status)).font(Theme.font(12.5))
                    }
                    .foregroundStyle(result == .tested ? Color(red: 0.18, green: 0.44, blue: 0.27) : Theme.warnText)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(result == .tested ? Color(red: 0.88, green: 0.95, blue: 0.9) : Theme.warnBg, in: RoundedRectangle(cornerRadius: 8))
                }.padding(16)
            }
        }
    }

    private func noteText(_ result: CompatibilityResult, _ status: AppStatus) -> String {
        if status == .gestureNotWorking { return "Swipes are not changing desktops on this macOS version." }
        return result == .tested ? "This macOS version has been tested." : "This macOS version hasn't been tested yet. Clicks still work normally."
    }

    private var footer: some View {
        HStack {
            Text("Swiper 0.1.0")
            Spacer()
            Link("View on GitHub", destination: URL(string: "https://github.com/guykongthong/swiper")!)
        }.font(Theme.font(12)).foregroundStyle(Theme.muted).padding(.horizontal, 4)
    }
}
