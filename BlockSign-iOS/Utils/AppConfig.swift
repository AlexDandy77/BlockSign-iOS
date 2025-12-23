import Foundation

/// Central place to read app configuration (Info.plist or defaults)
struct AppConfig {
    /// Reads API base URL from Info.plist key `API_BASE_URL`.
    /// Falls back to the default production domain.
    static var apiBaseURL: String {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        return "https://api.blocksign.md"
    }
}
