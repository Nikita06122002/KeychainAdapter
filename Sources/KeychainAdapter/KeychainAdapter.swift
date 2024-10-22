// The Swift Programming Language
// https://docs.swift.org/swift-book
import Security
import Foundation

/// A class for interacting with Keychain, providing thread safety using NSLock and basic data operations.
public class KeychainAdapter {
    
    private var serviceKey: String
    private let lock = NSLock()
    
    /// Keychain attribute keys
    private struct KeychainAttributes {
        static let secClass = kSecClass as String
        static let secAttrService = kSecAttrService as String
        static let secAttrAccount = kSecAttrAccount as String
        static let secValueData = kSecValueData as String
        static let secReturnData = kSecReturnData as String
        static let secMatchLimit = kSecMatchLimit as String
    }
    
    /// Initializes the KeychainAdapterWrapper with a given service key.
    /// - Parameter serviceKey: A unique key representing the service.
    public init(serviceKey: String) {
        self.serviceKey = serviceKey
    }
    
    /// Saves a string value in Keychain for a given key.
    /// This method is thread-safe.
    /// - Parameters:
    ///   - string: The string value to save.
    ///   - key: The key to associate with the value.
    /// - Returns: `true` if the save operation was successful, `false` otherwise.
    /// - Throws: Throws a `KeychainAdapterError` if key or value are invalid.
    @discardableResult
    public func save(_ string: String, forKey key: String) throws -> Bool {
        return try lockSync {
            try validateFields(key: key, value: string)
            let stringData = string.data(using: .utf8)!
            
            let query = keychainQuery(key: key, data: stringData)
            
            SecItemDelete(query as CFDictionary)  // Delete existing item if present
            
            let status = SecItemAdd(query as CFDictionary, nil)
            return try handleKeychainStatus(status)
        }
    }
    
    /// Retrieves a string value from Keychain for a given key.
    /// This method is thread-safe.
    /// - Parameter key: The key to look up in Keychain.
    /// - Returns: The string value associated with the key, or `nil` if not found.
    /// - Throws: Throws a `KeychainAdapterError` if the key is invalid.
    public func get(forKey key: String) throws -> String? {
        return try lockSync {
            try validateKey(key: key)
            
            var query = keychainQuery(key: key)
            query[KeychainAttributes.secReturnData] = kCFBooleanTrue
            query[KeychainAttributes.secMatchLimit] = kSecMatchLimitOne
            
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            
            guard let data = item as? Data else {
                return nil
            }
            
            return String(data: data, encoding: .utf8)
        }
    }
    
    /// Updates an existing string value in Keychain for a given key.
    /// This method is thread-safe.
    /// - Parameters:
    ///   - string: The new string value to update.
    ///   - key: The key whose associated value needs to be updated.
    /// - Returns: `true` if the update was successful, `false` otherwise.
    /// - Throws: Throws a `KeychainAdapterError` if key or value are invalid.
    @discardableResult
    public func update(_ string: String, forKey key: String) throws -> Bool {
        return try lockSync {
            try validateFields(key: key, value: string)
            
            let query = keychainQuery(key: key)
            let attributesToUpdate = [KeychainAttributes.secValueData: string.data(using: .utf8)!]
            
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            return try handleKeychainStatus(status)
        }
    }
    
    /// Checks if a value exists in Keychain for a given key.
    /// This method is thread-safe.
    /// - Parameter key: The key to check in Keychain.
    /// - Returns: `true` if the value exists, `false` otherwise.
    /// - Throws: Throws a `KeychainAdapterError` if the key is invalid.
    public func getBool(forKey key: String) throws -> Bool {
        return try get(forKey: key) != nil
    }
    
    /// Deletes a value from Keychain for a given key.
    /// This method is thread-safe.
    /// - Parameter key: The key whose associated value needs to be deleted.
    /// - Throws: Throws a `KeychainAdapterError` if the key is invalid.
    public func delete(forKey key: String) throws {
        try lockSync {
            try validateKey(key: key)
            
            let query = keychainQuery(key: key)
            let status = SecItemDelete(query as CFDictionary)
            try handleKeychainStatus(status)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Creates a basic Keychain query for a key with optional data.
    private func keychainQuery(key: String, data: Data? = nil) -> [String: Any] {
        var query: [String: Any] = [
            KeychainAttributes.secClass: kSecClassGenericPassword,
            KeychainAttributes.secAttrService: serviceKey,
            KeychainAttributes.secAttrAccount: key
        ]
        if let data = data {
            query[KeychainAttributes.secValueData] = data
        }
        return query
    }
    
    /// Validates fields before Keychain operations.
    private func validateFields(key: String, value: String) throws {
        guard !key.isEmpty else { throw KeychainAdapterError.keyIsEmpty }
        guard !value.isEmpty else { throw KeychainAdapterError.valueIsEmpty }
    }
    
    /// Validates that the key is not empty.
    private func validateKey(key: String) throws {
        guard !key.isEmpty else { throw KeychainAdapterError.keyIsEmpty }
    }
    
    /// Handles the Keychain operation status.
    @discardableResult
    private func handleKeychainStatus(_ status: OSStatus) throws -> Bool {
        if status != errSecSuccess {
            throw KeychainAdapterError.unexpectedError(status: status)
        }
        return true
    }
    
    /// Executes a closure inside a lock for thread safety.
    private func lockSync<T>(_ closure: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try closure()
    }
    
    // MARK: - Error
    
    /// Custom error type for KeychainAdapter.
    enum KeychainAdapterError: Error, Equatable {
        case valueIsEmpty
        case keyIsEmpty
        case unexpectedError(status: OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .valueIsEmpty:
                return "The value is empty!"
            case .keyIsEmpty:
                return "The key is empty!"
            case .unexpectedError(let status):
                return "Keychain operation failed with status: \(status)"
            }
        }
    }
}
