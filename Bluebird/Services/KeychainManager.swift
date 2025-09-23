import Foundation
import Security

class KeychainManager {
    static func storeData(data: Data, service: String, account: String) -> Bool {
        _ = deleteData(service: service, account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func retrieveData(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            print("Successfully retrieved data for service: \(service), account: \(account)")
            return result as? Data
        } else if status == errSecItemNotFound {
            print("Data not found for service: \(service), account: \(account)")
            return nil
        } else {
            print(
                "Error retrieving data for service: \(service), account: \(account). Status: \(status)"
            )
            return nil
        }
    }

    static func deleteData(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            if status == errSecSuccess {
                print("Successfully deleted data for service: \(service), account: \(account)")
            }
            return true
        } else {
            print(
                "Error deleting data for service: \(service), account: \(account). Status: \(status)"
            )
            return false
        }
    }
}
