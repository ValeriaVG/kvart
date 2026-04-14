import App
import Foundation

/// Resolves the bundle used for string lookups. Set `override` to a language
/// code (e.g. "sv") to force that localization; nil falls back to the main
/// bundle, which honors the device's preferred language ordering.
enum LocaleBundle {
    static var override: String? {
        didSet {
            guard oldValue != override else { return }
            UserDefaults.standard.set(override, forKey: "kvart.language.override")
            if let code = override {
                UserDefaults.standard.set([code] + Bundle.main.preferredLocalizations,
                                          forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
        }
    }

    static var current: Bundle {
        guard let code = override,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

extension Language {
    var code: String? {
        switch self {
        case .system: return nil
        case .en: return "en"
        case .sv: return "sv"
        case .fr: return "fr"
        case .de: return "de"
        }
    }

    var displayName: String {
        switch self {
        case .system: return L10n.Settings.languageSystem
        case .en: return "English"
        case .sv: return "Svenska"
        case .fr: return "Français"
        case .de: return "Deutsch"
        }
    }
}
