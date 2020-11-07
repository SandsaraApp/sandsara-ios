//
//  Codable.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import Foundation

extension Encodable {
    /// Converting object to postable dictionary
    func toDictionary(_ encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoder.encode(self)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Deserialized object is not a dictionary")
            throw DecodingError.typeMismatch(type(of: object), context)
        }
        return json
    }

    func toData(_ encoder: JSONEncoder = JSONEncoder()) -> Data? {
        do {
            let data = try encoder.encode(self)
            return data
        } catch {
            return nil
        }
    }
}

extension Decodable {
    typealias Dictionary = [AnyHashable: Any]
    static func toObject<Target>(type: Target.Type, from json: Dictionary) -> Target? where Target: Decodable {
        if let data = json.toData {
            do {
                let object = try JSONDecoder().decode(type, from: data)
                return object
            } catch let error {
                return nil
            }
        }
        return nil
    }

    static func toObject<Target>(type: Target.Type, from data: Data) -> Target? where Target: Decodable {
        do {
            let object = try JSONDecoder().decode(type, from: data)
            return object
        } catch {
            return nil
        }
    }
}
