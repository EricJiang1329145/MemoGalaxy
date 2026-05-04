import SwiftUI

struct AppLocaleKey: EnvironmentKey {
    static let defaultValue: Locale = .current
}

extension EnvironmentValues {
    var appLocale: Locale {
        get { self[AppLocaleKey.self] }
        set { self[AppLocaleKey.self] = newValue }
    }
}

extension View {
    func appLocale(_ locale: Locale) -> some View {
        environment(\.appLocale, locale)
    }
}

extension String {
    func localized(locale: Locale = .current) -> String {
        let lang: String
        if locale.language.languageCode?.identifier == "en" {
            lang = "en"
        } else if locale.language.languageCode?.identifier == "zh" {
            lang = "zh-Hans"
        } else {
            lang = "zh-Hans"
        }

        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return self
        }
        return bundle.localizedString(forKey: self, value: self, table: "Localizable")
    }
}