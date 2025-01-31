import Foundation

/// Defines the current UticaKit version.
public struct CarthageKitVersion {
  public let value: SemanticVersion

  public static let current = CarthageKitVersion(value: SemanticVersion(0, 40, 1))
}
