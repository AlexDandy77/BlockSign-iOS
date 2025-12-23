import SwiftUI

// MARK: - App Theme Colors

struct AppTheme {
    // Primary brand colors
    static let primaryBlue = Color(red: 0.25, green: 0.48, blue: 0.85) // #4079D9
    static let accentBlue = Color(red: 0.35, green: 0.58, blue: 0.95) // #5A94F2
    
    // Status colors
    static let success = Color(red: 0.2, green: 0.7, blue: 0.4) // Green
    static let warning = Color(red: 0.9, green: 0.6, blue: 0.2) // Orange
    static let error = Color(red: 0.85, green: 0.25, blue: 0.25) // Red
    
    // Dark mode background gradients
    static let darkBackground = Color(red: 0.05, green: 0.08, blue: 0.15) // Deep navy
    static let darkCardBackground = Color(red: 0.08, green: 0.12, blue: 0.22) // Navy card
    static let darkInputBackground = Color(red: 0.10, green: 0.15, blue: 0.28) // Lighter navy
    
    // Light mode backgrounds
    static let lightBackground = Color(red: 0.95, green: 0.97, blue: 1.0) // Light blue tint
    static let lightCardBackground = Color.white
    static let lightInputBackground = Color(red: 0.92, green: 0.95, blue: 1.0) // Light blue input
    
    // Text colors
    static let darkText = Color.white
    static let darkSecondaryText = Color(red: 0.6, green: 0.65, blue: 0.75)
    static let lightText = Color(red: 0.1, green: 0.15, blue: 0.25)
    static let lightSecondaryText = Color(red: 0.4, green: 0.45, blue: 0.55)
    
    // Helper functions for theme-aware colors
    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }
    
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkCardBackground : lightCardBackground
    }
    
    static func inputBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkInputBackground : lightInputBackground
    }
    
    static func textColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkText : lightText
    }
    
    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkSecondaryText : lightSecondaryText
    }
    
    // Gradient for backgrounds
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                backgroundColor(for: colorScheme),
                colorScheme == .dark
                    ? Color(red: 0.08, green: 0.12, blue: 0.25)
                    : Color(red: 0.90, green: 0.94, blue: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Button gradient
    static func buttonGradient(isEnabled: Bool = true) -> LinearGradient {
        LinearGradient(
            colors: isEnabled
                ? [primaryBlue, accentBlue]
                : [Color.gray, Color.gray],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Themed Button Style

struct ThemedButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.buttonGradient(isEnabled: isEnabled))
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: isEnabled ? AppTheme.primaryBlue.opacity(0.4) : .clear, radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Themed Card Modifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, y: 4)
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }
}
