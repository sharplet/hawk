import Clibc

public struct Path: Hashable {
  private(set) var _path: String

  public init(_ path: String) {
    self._path = path
  }

  public var basename: String {
    return _path.withCString { path in
      guard let name = hawk_basename(path) else {
        preconditionFailure("path name too long")
      }

      return String(cString: name)
    }
  }

  public var dirname: String {
    return _path.withCString { path in
      guard let dir = hawk_dirname(path) else {
        preconditionFailure("path name too long")
      }

      return String(cString: dir)
    }
  }
}

extension Path {
  public static func + (lhs: Path, rhs: String) -> Path {
    guard lhs._path != "." else { return Path(rhs) }

    var path = lhs._path
    if !path.hasSuffix("/") {
      path += "/"
    }
    path += rhs

    return Path(path)
  }
}

extension Path: CustomStringConvertible {
  public var description: String {
    return _path
  }
}
