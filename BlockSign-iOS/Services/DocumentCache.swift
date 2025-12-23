import Foundation

/// Handles local caching of document PDFs
class DocumentCache {
    static let shared = DocumentCache()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Use the app's caches directory for document storage
        let cachesPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesPath.appendingPathComponent("DocumentPDFs", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// Returns the file URL for a cached document
    private func fileURL(for documentId: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(documentId).pdf")
    }
    
    /// Saves PDF data to cache
    func save(data: Data, for documentId: String) {
        let url = fileURL(for: documentId)
        try? data.write(to: url)
    }
    
    /// Retrieves cached PDF data if available
    func retrieve(for documentId: String) -> Data? {
        let url = fileURL(for: documentId)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    /// Checks if a document is cached
    func isCached(documentId: String) -> Bool {
        let url = fileURL(for: documentId)
        return fileManager.fileExists(atPath: url.path)
    }
    
    /// Removes a cached document
    func remove(documentId: String) {
        let url = fileURL(for: documentId)
        try? fileManager.removeItem(at: url)
    }
    
    /// Returns all cached document IDs
    func getAllCachedDocumentIds() -> [String] {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return files.compactMap { url -> String? in
                guard url.pathExtension == "pdf" else { return nil }
                return url.deletingPathExtension().lastPathComponent
            }
        } catch {
            return []
        }
    }
    
    /// Removes cached documents that are not in the active list
    func cleanupOrphanedCache(activeDocumentIds: Set<String>) {
        let cachedIds = getAllCachedDocumentIds()
        for cachedId in cachedIds {
            if !activeDocumentIds.contains(cachedId) {
                remove(documentId: cachedId)
            }
        }
    }
    
    /// Clears all cached documents
    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
