import App
import StoreKit
import SwiftUI

struct ThemesView: View {
    @ObservedObject var core: Core
    @Environment(\.dismiss) private var dismiss

    @State private var pendingProductId: String?
    @State private var alertTitle: String = ""
    @State private var alertMessage: String?
    @State private var prices: [String: String] = [:]

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(core.view.themes.themes, id: \.id) { card in
                        ThemeCard(
                            card: card,
                            price: card.productId.flatMap { prices[$0] },
                            busy: pendingProductId != nil && pendingProductId == card.productId
                        ) {
                            if card.locked, let productId = card.productId {
                                Task { await purchase(themeId: card.id, productId: productId) }
                            } else {
                                core.send(.select(card.id))
                            }
                        }
                    }
                }
                .padding(16)
            }
            .alert(alertTitle,
                   isPresented: Binding(get: { alertMessage != nil },
                                        set: { if !$0 { alertMessage = nil } })) {
                Button(L10n.Common.ok) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
            .background(Color(red: 0x02 / 255.0, green: 0x0C / 255.0, blue: 0x1D / 255.0).ignoresSafeArea())
            .navigationTitle(L10n.Themes.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .task { await loadPrices() }
        }
    }
}

extension ThemesView {
    private func loadPrices() async {
        let ids = core.view.themes.themes.compactMap(\.productId)
        guard !ids.isEmpty else { return }
        guard let products = try? await Product.products(for: ids) else { return }
        var map: [String: String] = [:]
        for p in products { map[p.id] = p.displayPrice }
        prices = map
    }

    private func purchase(themeId: ThemeId, productId: String) async {
        guard pendingProductId == nil else { return }
        pendingProductId = productId
        defer { pendingProductId = nil }
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                alertTitle = L10n.Themes.purchaseFailed
                alertMessage = L10n.Themes.productUnavailable
                return
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let tx) = verification else {
                    alertTitle = L10n.Themes.purchaseFailed
                    alertMessage = L10n.Themes.verifyFailed
                    return
                }
                core.send(ThemesEvent.setPurchased(id: themeId, purchased: true))
                core.send(ThemesEvent.select(themeId))
                await tx.finish()
            case .userCancelled:
                return
            case .pending:
                alertTitle = L10n.Themes.purchasePending
                alertMessage = L10n.Themes.purchasePendingMessage
                return
            @unknown default:
                return
            }
        } catch {
            alertTitle = L10n.Themes.purchaseFailed
            alertMessage = error.localizedDescription
        }
    }
}

struct ThemeCard: View {
    let card: ThemeCardView
    let price: String?
    let busy: Bool
    let onTap: () -> Void

    private var accent: Color { ThemePalette.accent(card.id) }
    private var background: Color { ThemePalette.background(card.id) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Spacer(minLength: 8)
                ThemePreview(themeId: card.id)
                    .frame(width: 120, height: 120)
                Spacer(minLength: 4)
                Text(card.id.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                statusRow
                    .frame(height: 24)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(card.selected && !card.locked ? accent : Color.white.opacity(0.10),
                            lineWidth: card.selected && !card.locked ? 2 : 1)
            )
            .shadow(color: card.selected && !card.locked ? accent.opacity(0.25) : .clear,
                    radius: 16)
            .overlay(alignment: .topTrailing) {
                if card.selected && !card.locked {
                    ZStack {
                        Circle().fill(accent).frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(red: 0x02 / 255.0, green: 0x0C / 255.0, blue: 0x1D / 255.0))
                    }
                    .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    @ViewBuilder
    private var statusRow: some View {
        if card.locked {
            if busy {
                ProgressView().tint(accent)
            } else {
                Text(price ?? card.id.localizedDescription)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.15))
                    .clipShape(Capsule())
            }
        } else if card.selected {
            Text(L10n.Themes.active)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accent)
        } else {
            Text(L10n.Themes.tapToApply)
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0x7A / 255.0, green: 0x90 / 255.0, blue: 0xB0 / 255.0))
        }
    }
}

private struct ThemePreview: View {
    let themeId: ThemeId

    private let previewSize: CGFloat = 120
    private let fullSize: CGFloat = 390

    var body: some View {
        let scale = previewSize / fullSize
        let view = TimerView(secondsTotal: 900, secondsElapsed: 0, status: .idle)
        return ZStack {
            ThemePalette.background(themeId)
            TimerFace(view: view, theme: themeId, onTapTime: {}, onPrimary: {})
                .frame(width: fullSize, height: fullSize)
                .scaleEffect(scale)
                .allowsHitTesting(false)
        }
        .frame(width: previewSize, height: previewSize)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

