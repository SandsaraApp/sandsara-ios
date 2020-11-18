// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Add anyway
  internal static let addAnyway = L10n.tr("Localizeable", "add_anyway")
  /// Add to Playlist
  internal static let addToPlaylist = L10n.tr("Localizeable", "add_to_playlist")
  /// By %@
  internal static func authorBy(_ p1: Any) -> String {
    return L10n.tr("Localizeable", "author_by", String(describing: p1))
  }
  /// Cancel
  internal static let cancel = L10n.tr("Localizeable", "cancel")
  /// Create new playlist
  internal static let createPlaylist = L10n.tr("Localizeable", "create_playlist")
  /// Duplicate track found
  internal static let duplicateFound = L10n.tr("Localizeable", "duplicate_found")
  /// Favorite
  internal static let favorite = L10n.tr("Localizeable", "favorite")
  /// Favorited
  internal static let favorited = L10n.tr("Localizeable", "favorited")
  /// No Sandsara detected.
  internal static let noSandsaraDetected = L10n.tr("Localizeable", "no_sandsara_detected")
  /// Ok
  internal static let ok = L10n.tr("Localizeable", "ok")
  /// Play
  internal static let play = L10n.tr("Localizeable", "play")
  /// Playlists
  internal static let playlists = L10n.tr("Localizeable", "playlists")
  /// Recomended Playlists
  internal static let recommendedPlaylists = L10n.tr("Localizeable", "recommended_playlists")
  /// Recomended Tracks
  internal static let recommendedTracks = L10n.tr("Localizeable", "recommended_tracks")
  /// Sandsara detected.
  internal static let sandsaraDetected = L10n.tr("Localizeable", "sandsara_detected")
  /// Tracks
  internal static let tracks = L10n.tr("Localizeable", "tracks")
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
