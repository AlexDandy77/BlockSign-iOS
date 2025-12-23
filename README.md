# BlockSign iOS

A secure document signing application for iOS that uses blockchain-inspired cryptographic signatures to ensure document authenticity and integrity.

## Features

- **Secure Authentication**: Challenge-response authentication with BIP-39 mnemonic seed phrases
- **Biometric Protection**: FaceID/TouchID integration for sensitive operations
- **Document Management**: Create, view, sign, and reject documents
- **Cryptographic Signing**: Ed25519 digital signatures using SLIP-0010 HD key derivation
- **Document Verification**: Public verification of document signatures without authentication
- **Offline Caching**: Local PDF caching for viewing documents even when server files expire
- **Dark Mode Support**: Full dark/light theme support

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

- **CryptoKit**: Native Apple cryptography framework for Ed25519 signatures
- **CryptoSwift**: Extended cryptographic operations (SHA3-512, HMAC)
- **PDFKit**: Native PDF viewing

## Architecture

### Project Structure

```
BlockSign-iOS/
├── Models/
│   ├── Document.swift          # Document data models
│   ├── User.swift              # User profile models
│   └── AuthModels.swift        # Authentication request/response models
├── Views/
│   ├── LoginView.swift         # Authentication flow
│   ├── DashboardView.swift     # Main document list
│   ├── DocumentDetailView.swift # Document details & signing
│   ├── CreateDocumentView.swift # Document creation
│   ├── SettingsView.swift      # User settings & backup
│   └── VerifyDocumentView.swift # Public document verification
├── ViewModels/
│   ├── AuthenticationManager.swift  # Auth state management
│   ├── DocumentManager.swift        # Document state management
│   ├── DocumentSigningViewModel.swift
│   └── DocumentCreationViewModel.swift
├── Services/
│   ├── APIClient.swift         # Network layer with token refresh
│   ├── CryptoManager.swift     # Cryptographic operations
│   ├── KeychainManager.swift   # Secure credential storage
│   ├── BiometricManager.swift  # FaceID/TouchID
│   └── DocumentCache.swift     # Local PDF caching
└── Utils/
    ├── AppTheme.swift          # UI theming
    ├── AppConfig.swift         # Configuration
    └── BIP39Wordlist.swift     # Mnemonic word list
```

### Authentication Flow

1. User enters email address
2. Server returns a challenge string
3. User enters their 12-word mnemonic phrase
4. App derives Ed25519 private key using SLIP-0010 (path: `m/44'/53550'/0'/0'/0'`)
5. App signs the challenge and sends signature to server
6. Server verifies signature and returns JWT tokens

### Document Signing Flow

1. Document owner creates document with PDF and participant list
2. Owner's signature is included at creation time
3. Participants receive the document and can view/sign/reject
4. Each signature is verified against the canonical payload:
   ```json
   {"sha256Hex":"...","docTitle":"...","participantsUsernames":[...]}
   ```

## Setup

1. Clone the repository
2. Open `BlockSign-iOS.xcodeproj` in Xcode
3. Update `AppConfig.swift` with your backend API URL:
   ```swift
   static let apiBaseURL = "https://your-api-server.com"
   ```
4. Build and run on simulator or device

## Security Features

- **Private keys never leave the device**: Keys are derived from mnemonic and stored in iOS Keychain
- **Biometric gating**: FaceID required for signing operations
- **Secure token storage**: JWT tokens stored in Keychain
- **Automatic token refresh**: Seamless session management
- **Mnemonic backup**: Users can backup their seed phrase for account recovery

## API Integration

The app communicates with a Node.js/Express backend. Key endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/challenge` | POST | Request login challenge |
| `/api/v1/auth/verify` | POST | Verify signature and login |
| `/api/v1/auth/refresh` | POST | Refresh access token |
| `/api/v1/user/me` | GET | Get user profile and documents |
| `/api/v1/user/documents` | POST | Create new document |
| `/api/v1/user/documents/:id/sign` | POST | Sign a document |
| `/api/v1/user/documents/:id/reject` | POST | Reject a document |
| `/api/v1/user/documents/:id/view` | GET | Download document PDF |
| `/api/v1/documents/verify` | POST | Public document verification |

## License

MIT License - See [LICENSE](LICENSE) file for details.
