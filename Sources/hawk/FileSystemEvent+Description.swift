import Dispatch

extension DispatchSource.FileSystemEvent: CustomStringConvertible {
  public var description: String {
    switch self {
    case .attrib:
      return "attrib"
    case .delete:
      return "delete"
    case .extend:
      return "extend"
    case .funlock:
      return "funlock"
    case .link:
      return "link"
    case .rename:
      return "rename"
    case .revoke:
      return "revoke"
    case .write:
      return "write"
    default:
      return "FileSystemEvent(rawValue: \(rawValue))"
    }
  }
}
