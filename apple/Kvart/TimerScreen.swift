import App
import SwiftUI

struct TimerScreen: View {
    @ObservedObject var core: Core
    @State private var showThemes = false
    @State private var showSettings = false
    @State private var showSetTimer = false

    var body: some View {
        ZStack {
            backgroundColor(for: core.view.themes.selected)
                .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            TimerFace(
                view: core.view.timer,
                theme: core.view.themes.selected,
                onTapTime: {
                    if core.view.timer.status != .running { showSetTimer = true }
                },
                onPrimary: primaryAction
            )
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showThemes) { ThemesView(core: core) }
        .sheet(isPresented: $showSettings) { SettingsView(core: core) }
        .sheet(isPresented: $showSetTimer) {
            SetTimerView(initial: core.view.timer.secondsTotal) { seconds in
                core.send(.setDuration(seconds))
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { showThemes = true } label: {
                Image(systemName: "paintpalette")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }

    private func primaryAction() {
        switch core.view.timer.status {
        case .running: core.send(.pause(nowMs()))
        case .completed: core.send(.reset)
        default: core.send(.start(nowMs()))
        }
    }
}

struct SetTimerView: View {
    let initial: UInt32
    let onSave: (UInt32) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int
    @State private var seconds: Int

    init(initial: UInt32, onSave: @escaping (UInt32) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _minutes = State(initialValue: Int(initial / 60))
        _seconds = State(initialValue: Int(initial % 60))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0x02 / 255.0, green: 0x0C / 255.0, blue: 0x1D / 255.0).ignoresSafeArea()
                HStack(spacing: 0) {
                    pickerColumn(value: $minutes, range: 0...180, label: L10n.Timer.minutesShort)
                    pickerColumn(value: $seconds, range: 0...59, label: L10n.Timer.secondsShort)
                }
                .padding()
            }
            .navigationTitle(L10n.Timer.setTimer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) {
                        let total = max(1, UInt32(minutes * 60 + seconds))
                        onSave(total)
                        dismiss()
                    }
                    .foregroundStyle(Color(red: 0xC5 / 255.0, green: 0xF9 / 255.0, blue: 0x74 / 255.0))
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func pickerColumn(value: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        HStack(spacing: 4) {
            Picker("", selection: value) {
                ForEach(range, id: \.self) {
                    Text("\($0)")
                        .foregroundStyle(.white)
                        .tag($0)
                }
            }
            .pickerStyle(.wheel)
            .environment(\.colorScheme, .dark)
            .frame(maxWidth: .infinity)
            Text(label)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

func backgroundColor(for id: ThemeId) -> Color {
    switch id {
    case .blaze: return Color(red: 0x0C / 255.0, green: 0x0B / 255.0, blue: 0x0B / 255.0)
    case .vintageAmber: return Color(red: 0x2D / 255.0, green: 0x1F / 255.0, blue: 0x0F / 255.0)
    case .modern: return Color(red: 0x02 / 255.0, green: 0x0C / 255.0, blue: 0x1D / 255.0)
    }
}

func accent(for id: ThemeId) -> Color {
    switch id {
    case .blaze: return Color(red: 0xFF / 255.0, green: 0x78 / 255.0, blue: 0x4C / 255.0)
    case .vintageAmber: return Color(red: 0xFF / 255.0, green: 0xB3 / 255.0, blue: 0x47 / 255.0)
    case .modern: return Color(red: 0xC5 / 255.0, green: 0xF9 / 255.0, blue: 0x74 / 255.0)
    }
}

#Preview {
    TimerScreen(core: Core())
}
