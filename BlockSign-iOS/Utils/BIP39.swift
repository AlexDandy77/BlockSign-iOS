import Foundation
import CommonCrypto

class BIP39 {
    
    // MARK: - Mnemonic to Seed (PBKDF2)
    
    /// Converts a mnemonic phrase to a 64-byte binary seed using PBKDF2.
    /// - Parameters:
    ///   - mnemonic: The 12-24 word mnemonic string.
    ///   - passphrase: An optional passphrase (default is empty).
    /// - Returns: 64 bytes of data.
    static func mnemonicToSeed(mnemonic: String, passphrase: String = "") -> Data? {
        let password = mnemonic.precomposedStringWithCanonicalMapping.data(using: .utf8)!
        let salt = ("mnemonic" + passphrase).precomposedStringWithCanonicalMapping.data(using: .utf8)!
        
        var derivedBytes = [UInt8](repeating: 0, count: 64)
        let derivedLength = derivedBytes.count
        
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            (password as NSData).bytes.bindMemory(to: Int8.self, capacity: password.count),
            password.count,
            (salt as NSData).bytes.bindMemory(to: UInt8.self, capacity: salt.count),
            salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512),
            2048, // Iterations
            &derivedBytes,
            derivedLength
        )
        
        guard status == kCCSuccess else { return nil }
        return Data(derivedBytes)
    }
    
    // MARK: - Entropy to Mnemonic
    
    // A small subset of the wordlist for demonstration if full list is too large for this context window.
    // In a real app, this should be the full 2048 words.
    // I will include the full list in a separate file to be correct.
    
    static func generateMnemonic(strength: Int = 128) -> String? {
        guard [128, 256].contains(strength) else { return nil }
        let byteCount = strength / 8
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        
        guard status == errSecSuccess else { return nil }
        let data = Data(bytes)
        return dataToMnemonic(data: data)
    }
    
    static func dataToMnemonic(data: Data) -> String? {
        guard !BIP39Wordlist.english.isEmpty else { return nil }
        
        // 1. Checksum
        // SHA256(entropy) -> take first (entropy_len / 32) bits
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        let checksumBitLength = data.count * 8 / 32
        let checksumByte = hash[0] // Simplified: we only need a few bits, usually fits in first byte for 128/256 bits
        
        // 2. Convert to bits
        var bits = ""
        for byte in data {
            bits += String(byte, radix: 2).pad(toSize: 8)
        }
        
        let checksumBits = String(checksumByte, radix: 2).pad(toSize: 8).prefix(checksumBitLength)
        bits += checksumBits
        
        // 3. Split into 11-bit chunks
        var words: [String] = []
        let wordCount = bits.count / 11
        
        for i in 0..<wordCount {
            let start = bits.index(bits.startIndex, offsetBy: i * 11)
            let end = bits.index(start, offsetBy: 11)
            let chunk = String(bits[start..<end])
            if let index = Int(chunk, radix: 2), index < BIP39Wordlist.english.count {
                words.append(BIP39Wordlist.english[index])
            }
        }
        
        return words.joined(separator: " ")
    }
}

extension String {
    func pad(toSize: Int) -> String {
        var padded = self
        for _ in 0..<(toSize - self.count) {
            padded = "0" + padded
        }
        return padded
    }
}
