//
//  Endpoint.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import Foundation
import Moya
fileprivate let token = "keysvlN7KOHqUBdGn"
enum SandsaraAPI: String {
    case recommendedplaylist
    case recommendedtracks
    case playlists
    case playlistDetail
    case alltrack = "tracks"
    case colorPalette
    case firmware
}

extension String {

    static func ==(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedSame
    }

    static func <(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedAscending
    }

    static func <=(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedAscending || lhs.compare(rhs, options: .numeric) == .orderedSame
    }

    static func >(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedDescending
    }

    static func >=(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedDescending || lhs.compare(rhs, options: .numeric) == .orderedSame
    }

}

extension SandsaraAPI: TargetType {


    var method: Moya.Method {
        return .get
    }

    var baseURL: URL {
        return URL(string: "https://api.airtable.com/v0/apph4ADJ06dIfpZ3C/")!
    }

    var path: String {
        switch self {
        case .recommendedtracks:
            return "tracks"
        case .recommendedplaylist:
            return "playlist"
        default:
            return self.rawValue
        }
    }



    var headers: [String : String]? {
        return ["Authorization": "Bearer \(token)"]
    }

    var task: Task {
        switch self {
        case .recommendedplaylist, .recommendedtracks:
            return .requestParameters(parameters: ["view": "recommended"], encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }

    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
}
