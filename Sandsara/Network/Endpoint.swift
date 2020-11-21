//
//  Endpoint.swift
//  Sandsara
//
//  Created by Tín Phan on 14/11/2020.
//

import Foundation
import Moya

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
        return URL(string: "http://uninterested-cows.surge.sh/")!
    }

    var path: String {
        return "\(self.rawValue).json"
    }

    var headers: [String : String]? {
        return nil
    }

    var task: Task {
        return .requestPlain
    }

    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
}
