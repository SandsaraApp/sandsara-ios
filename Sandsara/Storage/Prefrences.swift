//
//  Prefrences.swift
//  MiniYoutubePlayer
//
//  Created by tin on 5/4/20.
//  Copyright © 2020 tin. All rights reserved.
//
import Foundation

@propertyWrapper
final class UserDefault<T> where T: Codable {
    private(set) var key: String
    let defaultValue: T?

    private var userDefault: UserDefaults

    init(_ key: String,
         defaultValue: T?,
         userDefault: UserDefaults = UserDefaults.standard,
         domain: String = "com.ios.sandsara") {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefault = userDefault
    }
    var wrappedValue: T? {
        get {
            let value = userDefault.object(forKey: key)
            if value is Data { //-- Array, enum, class, struct type
                let obj = T.toObject(type: T.self, from: value as! Data)
                return obj ?? defaultValue
            } else { //-- primitive type: Int, String, Double, Bool
                return (value as? T) ?? defaultValue
            }
        }
        set {
            if (newValue is String) || (newValue is Int) || (newValue is Double) || (newValue is Bool) || (newValue is Data) {
                userDefault.set(newValue, forKey: key)
            } else {
                let newData = newValue?.toData()
                userDefault.set(newData, forKey: key)
            }
            userDefault.synchronize()
        }
    }

    var projectedValue: UserDefault<T> { return self }

    func setKey(_ key: String) {
        self.key = key
    }
}

struct Preferences {

    static var prefixDomain: String {
        return "user_defaults.mobytelab_"
    }

    struct AppDomain {
        @UserDefault(Keys.currentAppLanguage.key, defaultValue: nil)
        static var currentAppLanguage: String?

        enum Keys: String {
            case currentAppLanguage

            var key: String {
                return Preferences.prefixDomain + self.rawValue
            }
        }
    }

    struct PlaylistsDomain {
        @UserDefault(Keys.topListId.key, defaultValue: nil)
        static var topListId: String?
        @UserDefault(Keys.featuredList.key, defaultValue: nil)
        static var featuredList: [GenreItem]?

        @UserDefault(Keys.categories.key, defaultValue: nil)
        static var categories: [GenreItem]?

        enum Keys: String {
            case topListId
            case featuredList
            case categories

            var key: String {
                return Preferences.prefixDomain + self.rawValue
            }
        }
    }
}

struct Config: Decodable {
    var trial_time_minutes: Double = 0.0
    var testing_version = 0

    var data: DataItem?

    enum CodingKeys: String, CodingKey {
        case trial_time_minutes
        case testing_version

        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        container.decodeIfPresent(Double.self, forKey: .trial_time_minutes, assignTo: &trial_time_minutes)
        container.decodeIfPresent(Int.self, forKey: .testing_version, assignTo: &testing_version)

        data = try container.decodeIfPresent(DataItem.self, forKey: .data)
    }
}

struct DataItem: Decodable {
    var features = [GenreItem]()
    var categories = [GenreItem]()

    var top: GenreItem?

    enum CodingKeys: String, CodingKey {
        case features = "featured"
        case categories
        case top
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        container.decodeIfPresent([GenreItem].self, forKey: .features, assignTo: &features)
        container.decodeIfPresent([GenreItem].self, forKey: .categories, assignTo: &categories)
        top = try container.decodeIfPresent(GenreItem.self, forKey: .top)
    }
}

class GenreItem: Codable {
    var id = ""
    var title = ""
    var thumbnail = ""

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnail
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        container.decodeIfPresent(String.self, forKey: .id, assignTo: &id)
        container.decodeIfPresent(String.self, forKey: .title, assignTo: &title)
        container.decodeIfPresent(String.self, forKey: .thumbnail, assignTo: &thumbnail)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
    }
}


