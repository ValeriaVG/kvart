import App

extension ThemeId {
    var localizedName: String {
        switch self {
        case .modern: return L10n.Themes.Modern.name
        case .vintageAmber: return L10n.Themes.VintageAmber.name
        case .blaze: return L10n.Themes.Blaze.name
        }
    }

    var localizedDescription: String {
        switch self {
        case .modern: return L10n.Themes.Modern.description
        case .vintageAmber: return L10n.Themes.VintageAmber.description
        case .blaze: return L10n.Themes.Blaze.description
        }
    }
}

extension AlarmSoundId {
    var localizedName: String {
        switch self {
        case .gameUnlock: return L10n.Sounds.GameUnlock.name
        case .kalimbaDing: return L10n.Sounds.KalimbaDing.name
        case .doubleBell: return L10n.Sounds.DoubleBell.name
        }
    }

    var localizedDescription: String {
        switch self {
        case .gameUnlock: return L10n.Sounds.GameUnlock.description
        case .kalimbaDing: return L10n.Sounds.KalimbaDing.description
        case .doubleBell: return L10n.Sounds.DoubleBell.description
        }
    }
}
