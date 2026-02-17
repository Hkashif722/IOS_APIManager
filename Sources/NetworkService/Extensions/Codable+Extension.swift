//
//  Codable+Extension.swift
//  Ujjivan
//
//  Created by Kashif Hussain on 06/01/25.
//  Copyright © 2025 EnthrallTech. All rights reserved.
//

import Foundation

public extension Encodable {
    func toDictionary() -> [String: AnyObject]? {
        do {
            let jsonData = try JSONEncoder().encode(self)
            if let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject] {
                return dictionary
            }
        } catch {
            print("Error encoding \(type(of: self)) to dictionary: \(error)")
        }
        return nil
    }

    func toStringDictionary() -> [String: String]? {
        do {
            let jsonData = try JSONEncoder().encode(self)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return nil
            }
            var stringDictionary = [String: String]()
            for (key, value) in dictionary {
                stringDictionary[key] = "\(value)"
            }
            return stringDictionary
        } catch {
            print("Error converting to string dictionary: \(error)")
            return nil
        }
    }
}

public extension Data {
    func decodeJSON() -> Any? {
        if let stringValue = String(data: self, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            switch stringValue.lowercased() {
            case "true",  "1": return true
            case "false", "0": return false
            default: break
            }
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [.fragmentsAllowed])
            return parseJSONValue(jsonObject)
        } catch {
            print("JSON Decoding Error: \(error)")
            return nil
        }
    }

    func getIntValue() -> Int? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [.fragmentsAllowed])
            return parseJSONValue(jsonObject) as? Int
        } catch {
            print("JSON Decoding Error: \(error)")
            return nil
        }
    }

    func getStringValue() -> String? {
        guard let string = String(data: self, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        return string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }

    func prettyPrintedJSONString() -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let prettyPrintedString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return prettyPrintedString
    }

    func decryptAndDecodeNew<T: Decodable>(as type: T.Type) -> T? {
        do {
            let keyBytes = LoginUtility.shared.getKeyBytes(key: keysValueConst.keyStr)
            let decryptedData = try LoginUtility.shared.newDecrypt(encryptedData: self, key: keyBytes, initialVector: keyBytes)
            return try JSONDecoder().decode(T.self, from: decryptedData)
        } catch {
            print("Error decrypting or decoding: \(error.localizedDescription)")
            return nil
        }
    }

    func decryptResponse() -> Data? {
        let keyBytes = LoginUtility.shared.getKeyBytes(key: keysValueConst.keyStr)
        do {
            return try LoginUtility.shared.newDecrypt(encryptedData: self, key: keyBytes, initialVector: keyBytes)
        } catch {
            print("Error while decrypting response: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private

    private func parseJSONValue(_ value: Any) -> Any? {
        switch value {
        case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID():
            return number.boolValue

        case let number as NSNumber:
            let doubleValue = number.doubleValue
            let intValue = number.intValue
            return Double(intValue) == doubleValue ? intValue : doubleValue

        case let string as String:
            return string

        case let array as [Any]:
            return array.compactMap(parseJSONValue)

        case let dict as [String: Any]:
            return dict.compactMapValues(parseJSONValue)

        case is NSNull:
            return nil

        default:
            print("Unsupported JSON type: \(type(of: value))")
            return nil
        }
    }
}

public extension Decodable {
    static func from(jsonString: String) -> Self? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            Logger.shared.log(.error, message: "❌ Error: Could not convert string to Data")
            return nil
        }
        do {
            return try JSONDecoder().decode(Self.self, from: jsonData)
        } catch {
            Logger.shared.log(.error, message: "❌ JSON Decoding Error: \(error)")
            return nil
        }
    }
}
