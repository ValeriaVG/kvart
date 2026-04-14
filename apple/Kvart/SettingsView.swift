import App
import AVFoundation
import StoreKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var core: Core
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @StateObject private var preview = AlarmPreviewPlayer()
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n.Settings.alarmSound).foregroundStyle(.white)) {
                    Toggle(L10n.Settings.enableSound, isOn: Binding(
                        get: { core.view.settings.soundEnabled },
                        set: { core.send(.setSoundEnabled($0)) }
                    ))
                    ForEach(core.view.settings.sounds, id: \.id) { sound in
                        soundRow(sound)
                    }
                }

                Section(header: Text(L10n.Settings.vibration).foregroundStyle(.white)) {
                    Toggle(L10n.Settings.enableVibration, isOn: Binding(
                        get: { core.view.settings.vibrationEnabled },
                        set: { core.send(.setVibrationEnabled($0)) }
                    ))
                }

                Section(header: Text(L10n.Settings.language).foregroundStyle(.white)) {
                    Picker(L10n.Settings.language, selection: Binding(
                        get: { core.view.settings.language },
                        set: { core.send(.setLanguage($0)) }
                    )) {
                        ForEach(core.view.settings.languages, id: \.id) { lang in
                            Text(lang.id.displayName).tag(lang.id)
                        }
                    }
                }

                Section(header: Text(L10n.Settings.support).foregroundStyle(.white)) {
                    restorePurchasesRow
                    Button {
                        requestReview()
                    } label: {
                        rowLabel(title: L10n.Settings.rateApp,
                                 subtitle: L10n.Settings.rateAppSubtitle,
                                 systemImage: "star")
                    }
                    .buttonStyle(.plain)
                    Link(destination: URL(string: "https://github.com/ValeriaVG/kvart/issues/new")!) {
                        rowLabel(title: L10n.Settings.reportBug,
                                 subtitle: L10n.Settings.reportBugSubtitle,
                                 systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(L10n.Settings.restorePurchases,
                   isPresented: Binding(get: { restoreMessage != nil },
                                        set: { if !$0 { restoreMessage = nil } })) {
                Button(L10n.Common.ok) { restoreMessage = nil }
            } message: {
                Text(restoreMessage ?? "")
            }
        }
        .onDisappear { preview.stop() }
        .preferredColorScheme(.dark)
    }

    private func soundRow(_ sound: AlarmSoundView) -> some View {
        HStack {
            Button {
                core.send(.selectSound(sound.id))
            } label: {
                HStack {
                    Image(systemName: sound.selected ? "checkmark" : "")
                        .foregroundStyle(.white)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sound.id.localizedName).foregroundStyle(.primary)
                        Text(sound.id.localizedDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                preview.play(asset: sound.asset)
            } label: {
                Image(systemName: "play.circle")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(L10n.Settings.playSoundPreview(sound.id.localizedName))
        }
        .disabled(!core.view.settings.soundEnabled)
    }

    private var restorePurchasesRow: some View {
        Button {
            Task { await restorePurchases() }
        } label: {
            HStack {
                rowLabel(title: L10n.Settings.restorePurchases,
                         subtitle: L10n.Settings.restorePurchasesSubtitle,
                         systemImage: "arrow.clockwise")
                if isRestoring {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isRestoring)
    }

    private func rowLabel(title: String, subtitle: String, systemImage: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: systemImage).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
        } catch {
            restoreMessage = L10n.Settings.restoreFailed
            return
        }
        var restoredAny = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if let theme = themeId(forProductId: tx.productID) {
                core.send(ThemesEvent.setPurchased(id: theme, purchased: true))
                restoredAny = true
            }
        }
        restoreMessage = restoredAny
            ? L10n.Settings.restoreSuccess
            : L10n.Settings.restoreNone
    }

    private func themeId(forProductId productId: String) -> ThemeId? {
        for theme in core.view.themes.themes {
            if theme.productId == productId { return theme.id }
        }
        return nil
    }
}

@MainActor
final class AlarmPreviewPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func play(asset: String) {
        guard let url = Bundle.main.url(forResource: asset, withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            // Ignore — preview is best-effort.
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}

#Preview {
    SettingsView(core: Core())
}
