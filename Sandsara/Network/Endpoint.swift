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
            return ""
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
