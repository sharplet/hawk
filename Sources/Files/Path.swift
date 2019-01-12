import Clibc

public enum Path {
  public static func basename(_ path: String) -> String {
    return path.withCString { path in
      guard let name = observer_basename(path) else {
        preconditionFailure("path name too long")
      }

      return String(cString: name)
    }
  }

  public static func dirname(_ path: String) -> String {
    return path.withCString { path in
      guard let dir = observer_dirname(path) else {
        preconditionFailure("path name too long")
      }

      return String(cString: dir)
    }
  }
}
