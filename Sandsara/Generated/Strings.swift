// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// About this Sandsara
  internal static let about = L10n.tr("Localizeable", "about")
  /// Add anyway
  internal static let addAnyway = L10n.tr("Localizeable", "add_anyway")
  /// Add to Playlist
  internal static let addToPlaylist = L10n.tr("Localizeable", "add_to_playlist")
  /// Advanced Settings
  internal static let advanceSetting = L10n.tr("Localizeable", "advance_setting")
  /// By %@
  internal static func authorBy(_ p1: Any) -> String {
    return L10n.tr("Localizeable", "author_by", String(describing: p1))
  }
  /// Basic Settings
  internal static let basicSetting = L10n.tr("Localizeable", "basic_setting")
  /// Brightness
  internal static let brightness = L10n.tr("Localizeable", "brightness")
  /// Cancel
  internal static let cancel = L10n.tr("Localizeable", "cancel")
  /// Change Name
  internal static let changeName = L10n.tr("Localizeable", "change_name")
  /// Create new playlist
  internal static let createPlaylist = L10n.tr("Localizeable", "create_playlist")
  /// Cycle
  internal static let cycle = L10n.tr("Localizeable", "cycle")
  /// Name: %@
  internal static func deviceName(_ p1: Any) -> String {
    return L10n.tr("Localizeable", "device_name", String(describing: p1))
  }
  /// Duplicate track found
  internal static let duplicateFound = L10n.tr("Localizeable", "duplicate_found")
  /// Factory Reset
  internal static let factoryReset = L10n.tr("Localizeable", "factory_reset")
  /// Favorite
  internal static let favorite = L10n.tr("Localizeable", "favorite")
  /// Favorited
  internal static let favorited = L10n.tr("Localizeable", "favorited")
  /// Firmware version: %@
  internal static func firmwareVersion(_ p1: Any) -> String {
    return L10n.tr("Localizeable", "firmware_version", String(describing: p1))
  }
  /// Help
  internal static let help = L10n.tr("Localizeable", "help")
  /// Light Cycle Speed
  internal static let lightCycleSpeed = L10n.tr("Localizeable", "light_cycle_speed")
  /// Light mode
  internal static let lightmode = L10n.tr("Localizeable", "lightmode")
  /// No Sandsara detected.
  internal static let noSandsaraDetected = L10n.tr("Localizeable", "no_sandsara_detected")
  /// Ok
  internal static let ok = L10n.tr("Localizeable", "ok")
  /// Play
  internal static let play = L10n.tr("Localizeable", "play")
  /// Playlists
  internal static let playlists = L10n.tr("Localizeable", "playlists")
  /// Presets
  internal static let presets = L10n.tr("Localizeable", "presets")
  /// Recomended Playlists
  internal static let recommendedPlaylists = L10n.tr("Localizeable", "recommended_playlists")
  /// Recomended Tracks
  internal static let recommendedTracks = L10n.tr("Localizeable", "recommended_tracks")
  /// Rotate
  internal static let rotate = L10n.tr("Localizeable", "rotate")
  /// Sandsara detected.
  internal static let sandsaraDetected = L10n.tr("Localizeable", "sandsara_detected")
  /// Settings
  internal static let settings = L10n.tr("Localizeable", "settings")
  /// Speed
  internal static let speed = L10n.tr("Localizeable", "speed")
  /// Static
  internal static let `static` = L10n.tr("Localizeable", "static")
  /// Tracks
  internal static let tracks = L10n.tr("Localizeable", "tracks")
  /// Update Firmware
  internal static let updateFirmware = L10n.tr("Localizeable", "update_firmware")
  /// Sandsara’s Website
  internal static let website = L10n.tr("Localizeable", "website")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
